import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router/app_router.dart';
import '../../app/router/routes.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/storage/prefs.dart';
import '../auth/data/auth_repository.dart';
import '../auth/domain/app_user.dart';
import '../auth/domain/session.dart';

part 'notification_service.g.dart';

/// Shows in-app banners from anywhere, without a BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// FCM for the app (docs/05 §6): keeps this device's token under the signed-in
/// user, shows teacher-comment messages, opens the journal a notification
/// points at, and refreshes the ID token when the server says claims changed.
class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;

  static const _lastUidKey = 'notifications.lastUid';
  static String _askedKey(String uid) => 'notifications.asked.$uid';

  FirebaseMessaging get _messaging => _ref.read(messagingProvider);

  bool _started = false;
  StreamSubscription<String>? _tokenSub;
  String? _pendingLink;

  /// Wires the message listeners. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);
    // The app was launched by tapping a notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onNotificationTapped(initial);
  }

  /// Called whenever the signed-in session changes.
  Future<void> onSession(Session? session) async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    if (session == null) return;

    await _registerDevice(session);
    _tokenSub = _messaging.onTokenRefresh.listen(
      (token) => _saveToken(session, token),
    );
    _openPendingLink(session);
  }

  // ---------- Device token ----------

  DocumentReference<Map<String, dynamic>> _deviceDoc(
    Session session,
    String token,
  ) => _ref
      .read(firestoreProvider)
      .doc(
        'schools/${session.schoolId}/users/${session.uid}'
        '/devices/${sha256.convert(utf8.encode(token))}',
      );

  Future<void> _registerDevice(Session session) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    try {
      // A token still registered under the previous account of this phone
      // would deliver that person's notifications here. A new token makes the
      // old one dead, and the server prunes dead tokens.
      final lastUid = prefs.getString(_lastUidKey);
      if (lastUid != null && lastUid != session.uid) {
        await _messaging.deleteToken();
      }
      final token = await _messaging.getToken();
      if (token == null) return;
      await _saveToken(session, token);
      await prefs.setString(_lastUidKey, session.uid);
    } on Object {
      // No Play services or no network: try again at the next sign-in.
    }
  }

  Future<void> _saveToken(Session session, String token) async {
    try {
      await _deviceDoc(session, token).set({
        'token': token,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Object {
      // Not critical: the next token refresh or sign-in retries.
    }
  }

  /// Removes this device's token before signing out, so the next person to
  /// use the phone does not receive this account's notifications.
  Future<void> unregisterDevice() async {
    final session = _ref.read(sessionProvider);
    if (session == null) return;
    try {
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 5),
      );
      if (token != null) {
        await _deviceDoc(
          session,
          token,
        ).delete().timeout(const Duration(seconds: 5));
      }
    } on Object {
      // Offline: `_registerDevice` rotates the token at the next sign-in.
    }
  }

  // ---------- Permission (Android 13+) ----------

  /// Whether the student should be shown the explanation before the system
  /// permission dialog. Asked once per account on this device.
  Future<bool> shouldExplainPermission(Session session) async {
    if (session.role != UserRole.siswa) return false;
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_askedKey(session.uid)) ?? false) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.denied;
  }

  Future<void> markPermissionExplained(Session session) => _ref
      .read(sharedPreferencesProvider)
      .setBool(_askedKey(session.uid), true);

  /// Shows the system permission dialog. Returns whether it was granted.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<bool> isPermissionGranted() async =>
      (await _messaging.getNotificationSettings()).authorizationStatus ==
      AuthorizationStatus.authorized;

  // ---------- Messages ----------

  static String? _linkOf(RemoteMessage message) {
    final data = message.data;
    final programId = data['programId'];
    final date = data['date'];
    if (data['type'] != 'comment' || programId == null || date == null) {
      return null;
    }
    return Routes.studentJournal(programId as String, date as String);
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'claims_changed') {
      _ref.read(authRepositoryProvider).refreshClaims();
      return;
    }
    final link = _linkOf(message);
    final notification = message.notification;
    if (link == null || notification == null) return;
    // The system tray stays quiet while the app is open, so show it in-app.
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          duration: const Duration(seconds: 6),
          content: Text(
            '${notification.title ?? 'Komentar baru'}\n'
            '${notification.body ?? ''}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => _ref.read(appRouterProvider).push(link),
          ),
        ),
      );
  }

  void _onNotificationTapped(RemoteMessage message) {
    final link = _linkOf(message);
    if (link == null) return;
    _pendingLink = link;
    final session = _ref.read(sessionProvider);
    if (session != null) _openPendingLink(session);
  }

  /// Deep links wait until a student session exists: at a cold start the
  /// router is still on the splash when the tap is reported.
  void _openPendingLink(Session session) {
    final link = _pendingLink;
    if (link == null) return;
    if (session.role != UserRole.siswa || session.mustChangePassword) {
      // Not this account's notification, or not allowed in yet: drop it.
      if (session.role != UserRole.siswa) _pendingLink = null;
      return;
    }
    _pendingLink = null;
    // After the redirect to the student shell has settled.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ref.read(appRouterProvider).push(link),
    );
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService(ref);
