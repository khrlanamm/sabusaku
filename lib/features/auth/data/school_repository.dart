import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/school.dart';
import 'auth_repository.dart';

part 'school_repository.g.dart';

/// The signed-in user's school document.
@Riverpod(keepAlive: true)
Stream<School> school(Ref ref) {
  final schoolId = ref.watch(currentSessionProvider.select((s) => s.schoolId));
  return ref
      .watch(firestoreProvider)
      .doc('schools/$schoolId')
      .snapshots()
      .where((snapshot) => snapshot.exists)
      .map((snapshot) => School.fromMap(snapshot.id, snapshot.data()!));
}
