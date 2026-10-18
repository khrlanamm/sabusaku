import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/school.dart';
import '../../auth/data/auth_repository.dart';

part 'superadmin_repository.g.dart';

/// What only the superadmin does: list every school, open another one, and
/// add a school with its first penanggung jawab. Inside the school they have
/// open, they work as one of its teachers through [TeacherRepository].
class SuperadminRepository {
  SuperadminRepository(this._ref);

  final Ref _ref;

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  FirebaseFunctions get _functions => _ref.read(functionsProvider);

  /// Every school, sorted by name.
  Stream<List<School>> watchSchools() => _firestore
      .collection('schools')
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) School.fromMap(doc.id, doc.data()),
        ],
      );

  /// Opens [schoolId]. The server moves the claims there; this returns once
  /// the session runs in that school.
  Future<void> switchSchool(String schoolId) async {
    final switched = Completer<void>();
    final subscription = _ref.listen(sessionProvider, (_, session) {
      if (session?.schoolId == schoolId && !switched.isCompleted) {
        switched.complete();
      }
    });
    try {
      await _functions.httpsCallable('switchSchool').call<Object?>({
        'schoolId': schoolId,
      });
      await _ref.read(authRepositoryProvider).refreshClaims();
      await switched.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AppException(
        AppErrorCode.network,
        message: 'Sekolah belum terbuka. Periksa koneksi, lalu coba lagi.',
      );
    } catch (error) {
      throw mapError(error);
    } finally {
      subscription.close();
    }
  }

  /// Registers a school with its first teacher. Returns whether the teacher
  /// joined right away (they already had a verified account with that email).
  Future<bool> addSchool({
    required String code,
    required String name,
    required String teacherName,
    required String teacherEmail,
  }) async {
    try {
      final result = await _functions.httpsCallable('addSchool').call<Object?>({
        'code': code,
        'name': name,
        'teacherName': teacherName,
        'teacherEmail': teacherEmail,
      });
      final data = result.data as Map? ?? const {};
      return data['joined'] == true;
    } catch (error) {
      throw mapError(error);
    }
  }
}

@Riverpod(keepAlive: true)
SuperadminRepository superadminRepository(Ref ref) => SuperadminRepository(ref);

/// Every school, for the superadmin's school picker.
@riverpod
Stream<List<School>> allSchools(Ref ref) =>
    ref.watch(superadminRepositoryProvider).watchSchools();
