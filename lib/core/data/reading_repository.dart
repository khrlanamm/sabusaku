import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../firebase/firebase_providers.dart';
import '../models/journal.dart';
import '../models/program.dart';
import '../models/student_stats.dart';

part 'reading_repository.g.dart';

/// Read side of the reading data, shared by the student and teacher shells.
///
/// Queries follow the shapes the security rules can prove (docs/03 §3):
/// journals and comments are always read under one program, never through a
/// collection-group query.
class ReadingRepository {
  ReadingRepository(this._firestore, this._schoolId);

  final FirebaseFirestore _firestore;
  final String _schoolId;

  DocumentReference<Map<String, dynamic>> get _school =>
      _firestore.doc('schools/$_schoolId');
  CollectionReference<Map<String, dynamic>> get programs =>
      _school.collection('programs');
  CollectionReference<Map<String, dynamic>> journals(String programId) =>
      programs.doc(programId).collection('journals');
  CollectionReference<Map<String, dynamic>> comments(
    String programId,
    String date,
  ) => journals(programId).doc(date).collection('comments');
  DocumentReference<Map<String, dynamic>> activeLock(String studentId) =>
      _school.collection('activePrograms').doc(studentId);
  CollectionReference<Map<String, dynamic>> get stats =>
      _school.collection('studentStats');

  Stream<StudentStats?> watchStats(String studentId) => stats
      .doc(studentId)
      .snapshots()
      .map(
        (doc) => doc.exists ? StudentStats.fromMap(doc.id, doc.data()!) : null,
      );

  Stream<Program?> watchProgram(String programId) => programs
      .doc(programId)
      .snapshots()
      .map((doc) => doc.exists ? Program.fromMap(doc.id, doc.data()!) : null);

  /// Newest first. A teacher must pass [classId] (one class per query) so the
  /// rules can prove access; a student reads their own.
  Stream<List<Program>> watchPrograms(String studentId, {String? classId}) {
    var query = programs.where('studentId', isEqualTo: studentId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    return query
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              Program.fromMap(doc.id, doc.data()),
          ],
        );
  }

  /// Newest first. Metadata changes are included so "waiting to sync" clears
  /// the moment the server acknowledges a journal.
  Stream<List<Journal>> watchJournals(String programId, {required int limit}) =>
      journals(programId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs)
                Journal.fromSnapshot(programId, doc),
            ],
          );

  Stream<Journal?> watchJournal(String programId, String date) =>
      journals(programId)
          .doc(date)
          .snapshots(includeMetadataChanges: true)
          .map(
            (doc) => doc.exists ? Journal.fromSnapshot(programId, doc) : null,
          );

  Stream<List<JournalComment>> watchComments(String programId, String date) =>
      comments(programId, date)
          .orderBy('createdAt')
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs) JournalComment.fromSnapshot(doc),
            ],
          );
}

@riverpod
ReadingRepository readingRepository(Ref ref) => ReadingRepository(
  ref.watch(firestoreProvider),
  ref.watch(currentSessionProvider.select((session) => session.schoolId)),
);

@riverpod
Stream<Program?> program(Ref ref, String programId) =>
    ref.watch(readingRepositoryProvider).watchProgram(programId);

@riverpod
Stream<Journal?> journal(Ref ref, String programId, String date) =>
    ref.watch(readingRepositoryProvider).watchJournal(programId, date);

@riverpod
Stream<List<Journal>> journals(Ref ref, String programId, int limit) =>
    ref.watch(readingRepositoryProvider).watchJournals(programId, limit: limit);

@riverpod
Stream<List<JournalComment>> journalComments(
  Ref ref,
  String programId,
  String date,
) => ref.watch(readingRepositoryProvider).watchComments(programId, date);
