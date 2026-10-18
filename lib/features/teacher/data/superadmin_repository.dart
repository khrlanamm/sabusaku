import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';

/// A school as a superadmin sees it in "Ganti sekolah".
typedef SchoolEntry = ({String id, String name, bool suspended});

/// What only a superadmin does: list every school, register a school with
/// its first teacher, and switch to another school (through
/// [AuthRepository.switchSchool], which also reloads the session). The server
/// checks the account on every call.
class SuperadminRepository {
  SuperadminRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<List<SchoolEntry>> listSchools() => _guard(() async {
    final result = await _functions.httpsCallable('listSchools').call<Object?>();
    final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
    return [
      for (final raw in data['schools'] as List? ?? const [])
        if (raw is Map)
          (
            id: raw['id'] as String,
            name: raw['name'] as String? ?? raw['id'] as String,
            suspended: raw['status'] == 'suspended',
          ),
    ];
  });

  /// Returns whether the teacher already had an account and has joined.
  Future<bool> createSchool({
    required String code,
    required String name,
    required String teacherEmail,
    required String teacherName,
  }) => _guard(() async {
    final result = await _functions.httpsCallable('createSchool').call<Object?>({
      'code': code,
      'name': name,
      'teacherEmail': teacherEmail,
      'teacherName': teacherName,
    });
    final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
    return data['joined'] == true;
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}

final superadminRepositoryProvider = Provider<SuperadminRepository>(
  (ref) => SuperadminRepository(ref.watch(functionsProvider)),
);

/// Whether the signed-in account is a superadmin. Read again whenever the
/// account or its school changes.
final isSuperadminProvider = FutureProvider<bool>((ref) {
  ref.watch(
    sessionProvider.select((session) => (session?.uid, session?.schoolId)),
  );
  return ref.watch(authRepositoryProvider).isSuperadmin();
});

/// Every school, by name. Refreshed after a school is added.
final allSchoolsProvider = FutureProvider.autoDispose<List<SchoolEntry>>(
  (ref) => ref.watch(superadminRepositoryProvider).listSchools(),
);
