import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/reading_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/utils/streams.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../domain/journal_draft.dart';
import '../domain/reading_rules.dart';

part 'student_repository.g.dart';

/// Everything a student writes. Journals are plain writes so they queue while
/// offline; book actions are transactions, which need the server, because
/// their rules depend on today's server date and on the BR-1 lock.
class StudentRepository {
  StudentRepository(
    this._firestore,
    this._reading,
    this._session,
    this._clock,
    this._storage,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ReadingRepository _reading;
  final Session _session;
  final WibClock _clock;

  String get _uid => _session.uid;

  // ---------- Book ----------

  /// Creates the program and its BR-1 lock atomically.
  ///
  /// [bookId] and [coverUrl] link the program to the catalog book it was
  /// picked from. The server compares the details with the catalog and turns
  /// any difference (or a book without [bookId]) into a suggestion for the
  /// teachers.
  Future<void> startBook({
    required String title,
    required String author,
    required int totalPages,
    String? isbn,
    String? bookId,
    String? coverUrl,
  }) => _online(() async {
    final today = _clock.today();
    final programRef = _reading.programs.doc();
    final lockRef = _reading.activeLock(_uid);
    await _firestore.runTransaction((transaction) async {
      final lock = await transaction.get(lockRef);
      if (lock.exists) {
        throw const AppException(
          AppErrorCode.alreadyExists,
          message: 'Kamu masih punya buku yang sedang dibaca.',
        );
      }
      transaction
        ..set(programRef, {
          'studentId': _uid,
          'classId': _session.profile.classId,
          'book': {
            'title': title,
            'author': author,
            'totalPages': totalPages,
            if (isbn != null && isbn.isNotEmpty) 'isbn': isbn,
            'bookId': ?bookId,
            'coverUrl': ?coverUrl,
          },
          'month': DateId.monthOf(today),
          'startDate': today,
          'targetDate': defaultTargetDate(today),
          'extended': false,
          'status': ProgramStatus.active.wire,
          // Derived fields start empty; only Cloud Functions change them.
          'currentPage': 0,
          'journalCount': 0,
          'lastJournalDate': null,
          'streakCurrent': 0,
          'streakBest': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..set(lockRef, {'programId': programRef.id});
    });
  });

  /// Uploads the student's own cover photo for a book they start (already
  /// cropped and compressed on the device) and returns its download URL, for
  /// `book.coverUrl`. The server offers it to the teachers as a suggestion;
  /// the catalog never points at this file.
  Future<String> uploadProgramCover(Uint8List bytes) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref(
      'schools/${_session.schoolId}/programCovers/$_uid/$stamp.jpg',
    );
    try {
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      // Storage refuses files that are not images or are too large; the
      // date hint of _online does not apply here.
      if (error.code == 'unauthorized') {
        throw AppException(
          AppErrorCode.permissionDenied,
          message:
              'Foto cover tidak bisa diunggah. Pilih foto lain lalu coba lagi.',
          cause: error,
        );
      }
      throw mapError(error);
    }
  }

  Future<void> extendTarget(Program program) => _online(
    () => _firestore.runTransaction((transaction) async {
      transaction.update(_reading.programs.doc(program.id), {
        'targetDate': extendedTargetDate(program.targetDate),
        'extended': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }),
  );

  /// Only possible at 100% progress; releases the lock in the same commit.
  Future<void> completeBook(Program program, {String? finalReflection}) =>
      _online(
        () => _firestore.runTransaction((transaction) async {
          transaction
            ..update(_reading.programs.doc(program.id), {
              'status': ProgramStatus.completed.wire,
              if (finalReflection != null && finalReflection.isNotEmpty)
                'finalReflection': finalReflection,
              'completedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            ..delete(_reading.activeLock(_uid));
        }),
      );

  Future<void> stopBook(Program program) => _online(
    () => _firestore.runTransaction((transaction) async {
      transaction
        ..update(_reading.programs.doc(program.id), {
          'status': ProgramStatus.stopped.wire,
          'stoppedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..delete(_reading.activeLock(_uid));
    }),
  );

  // ---------- Journal ----------

  /// The write itself. The returned future completes when the server
  /// acknowledges it, which can be long after the call when offline; the
  /// outbox tracks it instead of the screen awaiting it.
  Future<void> writeJournal(
    String programId,
    JournalDraft draft, {
    required bool isNew,
  }) {
    final ref = _reading.journals(programId).doc(draft.date);
    final reflection = draft.reflection.trim();
    final question = draft.question.trim();
    if (isNew) {
      return ref.set({
        'studentId': _uid,
        'date': draft.date,
        'pageStart': draft.pageStart,
        'pageEnd': draft.pageEnd,
        'durationRange': draft.durationRange.wire,
        'keyInformation': draft.keyInformation.trim(),
        if (reflection.isNotEmpty) 'reflection': reflection,
        if (question.isNotEmpty) 'question': question,
        'hasUnreadTeacherComment': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return ref.update({
      'pageStart': draft.pageStart,
      'pageEnd': draft.pageEnd,
      'durationRange': draft.durationRange.wire,
      'keyInformation': draft.keyInformation.trim(),
      'reflection': reflection.isEmpty ? FieldValue.delete() : reflection,
      'question': question.isEmpty ? FieldValue.delete() : question,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJournal(String programId, String date) =>
      _reading.journals(programId).doc(date).delete();

  /// Fire-and-forget: the badge clears locally at once and syncs later.
  void markCommentsRead(Journal journal) {
    if (!journal.hasUnreadTeacherComment) return;
    _reading.journals(journal.programId).doc(journal.date).update({
      'hasUnreadTeacherComment': false,
    }).ignore();
  }

  /// Reads the journal as the device currently knows it, without waiting for
  /// the network.
  Future<DocumentSnapshot<Map<String, dynamic>>?> cachedJournal(
    String programId,
    String date,
  ) async {
    try {
      return await _reading
          .journals(programId)
          .doc(date)
          .get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      return null; // not in the cache
    }
  }

  // ---------- Reads specific to the student ----------

  /// The ID of the student's active program, from the BR-1 lock.
  Stream<String?> watchActiveProgramId() => _reading
      .activeLock(_uid)
      .snapshots()
      .map((doc) => doc.data()?['programId'] as String?);

  /// Journals of one program that carry an unread teacher comment.
  Stream<List<Journal>> watchUnreadJournals(String programId) => _reading
      .journals(programId)
      .where('hasUnreadTeacherComment', isEqualTo: true)
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) Journal.fromSnapshot(programId, doc),
        ],
      );

  Future<T> _online<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      // The rules compare dates with the server clock; a wrong device date is
      // the usual reason a correct-looking book action is refused.
      if (error.code == 'permission-denied') {
        throw AppException(
          AppErrorCode.permissionDenied,
          message:
              'Server menolak permintaan ini. Periksa tanggal dan jam di '
              'HP kamu, lalu coba lagi.',
          cause: error,
        );
      }
      throw mapError(error);
    } catch (error) {
      throw mapError(error);
    }
  }
}

@riverpod
StudentRepository studentRepository(Ref ref) => StudentRepository(
  ref.watch(firestoreProvider),
  ref.watch(readingRepositoryProvider),
  ref.watch(currentSessionProvider),
  ref.watch(wibClockProvider),
  ref.watch(storageProvider),
);

/// The student's own summary (server-written).
@riverpod
Stream<StudentStats?> myStats(Ref ref) => ref
    .watch(readingRepositoryProvider)
    .watchStats(ref.watch(currentSessionProvider.select((s) => s.uid)));

/// The book being read, or null. Follows the lock document, so it is correct
/// offline and the instant a book is started or finished.
@riverpod
Stream<Program?> activeProgram(Ref ref) {
  final reading = ref.watch(readingRepositoryProvider);
  return ref
      .watch(studentRepositoryProvider)
      .watchActiveProgramId()
      .switchMap(
        (id) => id == null
            ? Stream<Program?>.value(null)
            : reading.watchProgram(id),
      );
}

/// All of the student's books, newest first.
@riverpod
Stream<List<Program>> myPrograms(Ref ref) => ref
    .watch(readingRepositoryProvider)
    .watchPrograms(ref.watch(currentSessionProvider.select((s) => s.uid)));

/// The student's journals from [from] to [to] (inclusive) over all their
/// books, or one book when [programId] is given; newest first. Only books
/// with a journal in the range are queried (`journalDates`).
@riverpod
Stream<List<Journal>> myJournalsBetween(
  Ref ref,
  String from,
  String to,
  String? programId,
) async* {
  final reading = ref.watch(readingRepositoryProvider);
  final today = ref.watch(wibClockProvider).today();
  final programs = await ref.watch(myProgramsProvider.future);
  final streams = [
    for (final program in programs)
      if ((programId == null || program.id == programId) &&
          program.mayHaveJournalsBetween(from, to, today))
        reading.watchJournalsBetween(program.id, from, to),
  ];
  yield* combineLatest(streams).map(
    (lists) => [for (final list in lists) ...list]
      ..sort((a, b) => b.date.compareTo(a.date)),
  );
}

@riverpod
Stream<List<Journal>> unreadJournals(Ref ref, String programId) =>
    ref.watch(studentRepositoryProvider).watchUnreadJournals(programId);
