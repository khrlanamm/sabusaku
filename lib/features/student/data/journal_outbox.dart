import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/reading_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/prefs.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/journal_draft.dart';
import 'student_repository.dart';

part 'journal_outbox.freezed.dart';
part 'journal_outbox.g.dart';

enum OutboxKind { save, delete }

enum OutboxStatus {
  /// Written on this device, not yet acknowledged by the server.
  pending,

  /// The server refused it. The text is kept so nothing the student typed is
  /// lost.
  failed,
}

/// One journal write the device is still responsible for.
@freezed
abstract class OutboxEntry with _$OutboxEntry {
  const OutboxEntry._();

  const factory OutboxEntry({
    required String programId,
    required String bookTitle,
    required String date,
    required OutboxKind kind,
    @Default(OutboxStatus.pending) OutboxStatus status,
    String? reason,

    /// What was being saved; null for a delete.
    JournalDraft? draft,
  }) = _OutboxEntry;

  factory OutboxEntry.fromMap(Map<String, dynamic> json) => OutboxEntry(
    programId: json['programId'] as String,
    bookTitle: json['bookTitle'] as String? ?? '',
    date: json['date'] as String,
    kind: OutboxKind.values.byName(json['kind'] as String),
    status: OutboxStatus.values.byName(json['status'] as String),
    reason: json['reason'] as String?,
    draft: json['draft'] == null
        ? null
        : JournalDraft.fromMap(json['draft'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toMap() => {
    'programId': programId,
    'bookTitle': bookTitle,
    'date': date,
    'kind': kind.name,
    'status': status.name,
    'reason': reason,
    'draft': draft?.toMap(),
  };

  String get key => '$programId/$date';
}

const _rejectedReason =
    'Server menolak jurnal ini. Biasanya karena tanggalnya sudah melewati '
    'batas pengisian (paling lama 2 hari ke belakang) atau batas ubah '
    '(sampai sehari setelah tanggal jurnal).';

/// Tracks journal writes until the server answers, so a journal written
/// offline is never rejected silently (docs/03 §3, "Catatan perilaku offline").
///
/// Firestore queues offline writes and replays them after an app restart, but
/// the future of the original call is gone by then. Entries are therefore
/// persisted, and on the next start each leftover entry is settled by
/// watching its document: once it has no pending writes, either the server
/// took the write or it rolled it back.
@Riverpod(keepAlive: true)
class JournalOutbox extends _$JournalOutbox {
  /// Entries whose write future is alive in this process.
  final _live = <String>{};
  final _watchers =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};

  String get _prefsKey =>
      'journal.outbox.${ref.read(currentSessionProvider).uid}';

  @override
  List<OutboxEntry> build() {
    // A different account has its own outbox.
    ref.watch(currentSessionProvider.select((session) => session.uid));
    ref.onDispose(_cancelWatchers);
    _cancelWatchers();
    _live.clear();

    final entries = _load();
    Future.microtask(_settleLeftovers);
    return entries;
  }

  List<OutboxEntry> _load() {
    final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List)
          OutboxEntry.fromMap(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  void _save(List<OutboxEntry> entries) {
    state = entries;
    ref
        .read(sharedPreferencesProvider)
        .setString(
          _prefsKey,
          jsonEncode([for (final entry in entries) entry.toMap()]),
        );
  }

  void _remove(String key) => _save([
    for (final entry in state)
      if (entry.key != key) entry,
  ]);

  void _fail(String key, String reason) => _save([
    for (final entry in state)
      entry.key == key
          ? entry.copyWith(status: OutboxStatus.failed, reason: reason)
          : entry,
  ]);

  /// Registers [write] and follows it to its outcome.
  void track(OutboxEntry entry, Future<void> write) {
    final key = entry.key;
    _watchers.remove(key)?.cancel();
    _live.add(key);
    _save([
      for (final existing in state)
        if (existing.key != key) existing,
      entry.copyWith(status: OutboxStatus.pending, reason: null),
    ]);

    write.then(
      (_) {
        _live.remove(key);
        _remove(key);
      },
      onError: (Object error) {
        _live.remove(key);
        final denied =
            error is FirebaseException && error.code == 'permission-denied';
        _fail(key, denied ? _rejectedReason : mapError(error).userMessage);
      },
    );
  }

  /// Forgets an entry, e.g. after the student has read why it failed.
  void dismiss(OutboxEntry entry) {
    _watchers.remove(entry.key)?.cancel();
    _remove(entry.key);
  }

  /// Settles entries left pending by a previous run of the app.
  void _settleLeftovers() {
    final reading = ref.read(readingRepositoryProvider);
    for (final entry in state) {
      if (entry.status != OutboxStatus.pending ||
          _live.contains(entry.key) ||
          _watchers.containsKey(entry.key)) {
        continue;
      }
      _watchers[entry.key] = reading
          .journals(entry.programId)
          .doc(entry.date)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            // Still queued: the device has not reached the server yet.
            if (snapshot.metadata.hasPendingWrites) return;
            _watchers.remove(entry.key)?.cancel();
            if (_delivered(entry, snapshot)) {
              _remove(entry.key);
            } else {
              _fail(entry.key, _rejectedReason);
            }
          }, onError: (Object _) {});
    }
  }

  /// Whether the document now reflects what the entry tried to do.
  static bool _delivered(
    OutboxEntry entry,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (entry.kind == OutboxKind.delete) return !snapshot.exists;
    final data = snapshot.data();
    final draft = entry.draft;
    return data != null &&
        draft != null &&
        data['pageStart'] == draft.pageStart &&
        data['pageEnd'] == draft.pageEnd &&
        data['keyInformation'] == draft.keyInformation.trim();
  }

  void _cancelWatchers() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
  }
}

/// Saves or deletes a journal without waiting for the server, handing the
/// write to the outbox.
@riverpod
JournalWriter journalWriter(Ref ref) => JournalWriter(ref);

class JournalWriter {
  JournalWriter(this._ref);

  final Ref _ref;

  void save({
    required String programId,
    required String bookTitle,
    required JournalDraft draft,
    required bool isNew,
  }) {
    final write = _ref
        .read(studentRepositoryProvider)
        .writeJournal(programId, draft, isNew: isNew);
    _ref
        .read(journalOutboxProvider.notifier)
        .track(
          OutboxEntry(
            programId: programId,
            bookTitle: bookTitle,
            date: draft.date,
            kind: OutboxKind.save,
            draft: draft,
          ),
          write,
        );
  }

  void delete({
    required String programId,
    required String bookTitle,
    required String date,
  }) {
    final write = _ref
        .read(studentRepositoryProvider)
        .deleteJournal(programId, date);
    _ref
        .read(journalOutboxProvider.notifier)
        .track(
          OutboxEntry(
            programId: programId,
            bookTitle: bookTitle,
            date: date,
            kind: OutboxKind.delete,
          ),
          write,
        );
  }
}
