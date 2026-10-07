import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/school.dart';
import '../../../core/models/school_class.dart';
import '../../../core/models/student_status.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../domain/admin_models.dart';

part 'admin_repository.g.dart';

/// Everything the admin shell reads and writes. Changes to roles, classes of
/// users, account status and passwords always go through callables.
class AdminRepository {
  AdminRepository(this._firestore, this._functions, this._schoolId);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String _schoolId;

  DocumentReference<Map<String, dynamic>> get _school =>
      _firestore.doc('schools/$_schoolId');
  CollectionReference<Map<String, dynamic>> get _classes =>
      _school.collection('classes');
  CollectionReference<Map<String, dynamic>> get _users =>
      _school.collection('users');
  CollectionReference<Map<String, dynamic>> get _stats =>
      _school.collection('studentStats');

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(result.data as Map);
    } catch (error) {
      throw mapError(error);
    }
  }

  // ---------- Classes ----------

  Future<void> createClass({
    required String name,
    required int grade,
    required String academicYear,
  }) => _guard(
    () => _classes.add({
      'name': name,
      'grade': grade,
      'academicYear': academicYear,
      'teacherIds': <String>[],
      'isArchived': false,
    }),
  );

  Future<void> updateClass(SchoolClass item) => _guard(
    () => _classes.doc(item.id).update({
      'name': item.name,
      'grade': item.grade,
      'academicYear': item.academicYear,
      'isArchived': item.isArchived,
    }),
  );

  // ---------- Users ----------

  Stream<List<AppUser>> watchUsers(UserRole role) => _users
      .where('role', isEqualTo: role.wire)
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) AppUser.fromMap(doc.id, doc.data()),
        ],
      );

  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);

  Future<void> renameUser(String uid, String name) => _guard(
    () => _users.doc(uid).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  /// At most 100 users per call; larger imports are split by the caller.
  Future<List<CreateUserResult>> createUsers(List<NewUser> users) async {
    final data = await _call('createUsers', {
      'users': [for (final user in users) user.toMap()],
    });
    return [
      for (final row in data['results'] as List)
        CreateUserResult.fromMap(Map<String, dynamic>.from(row as Map)),
    ];
  }

  /// Returns the temporary password, shown to the caller once.
  Future<String> resetPassword(String uid) async =>
      (await _call('resetPassword', {'uid': uid}))['password'] as String;

  Future<void> setUserActive(String uid, {required bool active}) =>
      _call('setUserActive', {'uid': uid, 'active': active});

  Future<void> setTeacherClasses(String uid, List<String> classIds) =>
      _call('setTeacherClasses', {'uid': uid, 'classIds': classIds});

  Future<void> moveStudentClass(String uid, String classId) =>
      _call('moveStudentClass', {'uid': uid, 'classId': classId});

  /// Permanently removes a student and all of their reading data.
  Future<void> eraseStudent(String uid) => _call('eraseStudent', {'uid': uid});

  // ---------- Settings ----------

  Future<void> updateSettings(SchoolSettings settings) =>
      _guard(() => _school.update({'settings': settings.toMap()}));

  // ---------- Home ----------

  Future<AdminCounts> loadCounts() => _guard(() async {
    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;

    final activeUsers = _users.where('status', isEqualTo: 'active');
    final results = await Future.wait([
      count(activeUsers.where('role', isEqualTo: UserRole.siswa.wire)),
      count(activeUsers.where('role', isEqualTo: UserRole.guru.wire)),
      count(_classes.where('isArchived', isEqualTo: false)),
      for (final status in StudentStatus.values)
        count(_stats.where('status', isEqualTo: status.wire)),
    ]);
    return AdminCounts(
      students: results[0],
      teachers: results[1],
      classes: results[2],
      byStatus: {
        for (final (index, status) in StudentStatus.values.indexed)
          status: results[3 + index],
      },
    );
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}

@riverpod
AdminRepository adminRepository(Ref ref) => AdminRepository(
  ref.watch(firestoreProvider),
  ref.watch(functionsProvider),
  ref.watch(currentSessionProvider.select((session) => session.schoolId)),
);

@riverpod
Stream<List<AppUser>> usersByRole(Ref ref, UserRole role) =>
    ref.watch(adminRepositoryProvider).watchUsers(role);

@riverpod
Stream<AppUser?> userById(Ref ref, String uid) =>
    ref.watch(adminRepositoryProvider).watchUser(uid);

@riverpod
Future<AdminCounts> adminCounts(Ref ref) =>
    ref.watch(adminRepositoryProvider).loadCounts();
