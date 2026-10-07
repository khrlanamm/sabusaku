import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../firebase/firebase_providers.dart';
import '../models/school_class.dart';

part 'class_repository.g.dart';

/// Every class of the school, archived ones included, sorted by name.
/// Readable by all members of the school.
@riverpod
Stream<List<SchoolClass>> classes(Ref ref) {
  final schoolId = ref.watch(currentSessionProvider.select((s) => s.schoolId));
  return ref
      .watch(firestoreProvider)
      .collection('schools/$schoolId/classes')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => SchoolClass.fromMap(doc.id, doc.data()))
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
      );
}

/// Class names by ID, for labels.
@riverpod
Map<String, String> classNames(Ref ref) => {
  for (final item in ref.watch(classesProvider).value ?? const <SchoolClass>[])
    item.id: item.name,
};
