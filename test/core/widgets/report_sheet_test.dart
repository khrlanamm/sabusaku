import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/data/report_repository.dart';
import 'package:sabusaku/core/errors/app_exception.dart';
import 'package:sabusaku/core/models/journal.dart';
import 'package:sabusaku/core/models/report.dart';
import 'package:sabusaku/core/widgets/journal_view.dart';
import 'package:sabusaku/core/widgets/report_sheet.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

const _student = Session(
  uid: 's1',
  role: UserRole.siswa,
  schoolId: 'sman1',
  profile: AppUser(uid: 's1', role: UserRole.siswa, name: 'Raka Pratama'),
);

const _comment = JournalComment(
  id: 'c1',
  teacherId: 'g1',
  teacherName: 'Sari Wulandari',
  text: 'Ringkasanmu jelas.',
);

const _commentTarget = ReportTarget.comment(
  programId: 'p1',
  date: '2026-10-15',
  commentId: 'c1',
);

void main() {
  late _MockReportRepository repository;

  setUpAll(() {
    registerFallbackValue(const ReportTarget.book('b0'));
    registerFallbackValue(ReportReason.other);
  });

  setUp(() {
    repository = _MockReportRepository();
    when(
      () => repository.report(
        any(),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => 'r1');
  });

  Future<void> pumpHost(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(_student),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  /// Opens the sheet for [target] from a button.
  Future<void> openSheet(WidgetTester tester, ReportTarget target) async {
    await pumpHost(
      tester,
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => showReportSheet(context, ref, target: target),
          child: const Text('buka'),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-sheet')), findsOneWidget);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
  }

  test('wrong book data is a reason for books and suggestions only', () {
    for (final kind in ReportKind.values) {
      final reasons = ReportReason.forKind(kind);
      final bookLike = kind == ReportKind.book || kind == ReportKind.suggestion;
      expect(reasons.contains(ReportReason.wrongData), bookLike);
      expect(reasons.length, bookLike ? 6 : 5);
      expect(reasons.last, ReportReason.other);
    }
  });

  test('the target becomes the callable arguments', () {
    expect(_commentTarget.toMap(), {
      'kind': 'comment',
      'programId': 'p1',
      'date': '2026-10-15',
      'commentId': 'c1',
    });
    // Whether the user is a teacher stays in the app.
    expect(const ReportTarget.user('u9', teacher: true).toMap(), {
      'kind': 'user',
      'userId': 'u9',
    });
  });

  test('reports about a teacher go to the developer only', () {
    expect(_commentTarget.developerOnly, isTrue);
    expect(const ReportTarget.user('g1', teacher: true).developerOnly, isTrue);
    expect(const ReportTarget.user('s1').developerOnly, isFalse);
    expect(
      const ReportTarget.journal(
        programId: 'p1',
        date: '2026-10-15',
      ).developerOnly,
      isFalse,
    );
    expect(const ReportTarget.book('b1').developerOnly, isFalse);
  });

  testWidgets('a comment report offers the comment reasons', (tester) async {
    await openSheet(tester, _commentTarget);

    expect(find.text('Laporkan komentar'), findsOneWidget);
    expect(find.textContaining('hanya dibaca pengembang'), findsOneWidget);
    for (final reason in ReportReason.forKind(ReportKind.comment)) {
      expect(find.byKey(Key('report-reason-${reason.wire}')), findsOneWidget);
      expect(find.text(reason.label), findsOneWidget);
    }
    expect(find.byKey(const Key('report-reason-wrong_data')), findsNothing);
  });

  testWidgets('a book report also offers "Data buku salah"', (tester) async {
    await openSheet(tester, const ReportTarget.book('b1'));

    expect(find.text('Laporkan buku'), findsOneWidget);
    expect(find.textContaining('ditinjau penanggung jawab'), findsOneWidget);
    expect(find.byKey(const Key('report-reason-wrong_data')), findsOneWidget);
    expect(find.text('Data buku salah'), findsOneWidget);
  });

  testWidgets('the note stops at 500 characters', (tester) async {
    await openSheet(tester, _commentTarget);

    await tester.enterText(find.byKey(const Key('report-note')), 'a' * 620);
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('report-note')),
    );
    expect(field.controller!.text.length, maxReportNoteLength);
  });

  testWidgets('sending needs a reason, then reports and confirms', (
    tester,
  ) async {
    await openSheet(tester, _commentTarget);

    final submit = find.byKey(const Key('report-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tapKey(tester, 'report-reason-harassment');
    await tester.enterText(
      find.byKey(const Key('report-note')),
      '  Kata-katanya kasar.  ',
    );
    await tapKey(tester, 'report-submit');
    await tester.pumpAndSettle();

    verify(
      () => repository.report(
        _commentTarget,
        reason: ReportReason.harassment,
        note: 'Kata-katanya kasar.',
      ),
    ).called(1);
    expect(find.byKey(const Key('report-sheet')), findsNothing);
    expect(find.text(reportSentToDeveloperMessage), findsOneWidget);
  });

  testWidgets('an empty note is left out', (tester) async {
    await openSheet(tester, const ReportTarget.book('b1'));

    await tapKey(tester, 'report-reason-wrong_data');
    await tapKey(tester, 'report-submit');
    await tester.pumpAndSettle();

    verify(
      () => repository.report(
        const ReportTarget.book('b1'),
        reason: ReportReason.wrongData,
        note: null,
      ),
    ).called(1);
    expect(find.text(reportSentMessage), findsOneWidget);
  });

  testWidgets('a refused report keeps the sheet open with the reason', (
    tester,
  ) async {
    when(
      () => repository.report(
        any(),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenThrow(
      const AppException(
        AppErrorCode.tooManyRequests,
        message: 'Terlalu banyak laporan. Coba lagi besok.',
      ),
    );
    await openSheet(tester, _commentTarget);

    await tapKey(tester, 'report-reason-other');
    await tapKey(tester, 'report-submit');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-sheet')), findsOneWidget);
    expect(
      find.text('Terlalu banyak laporan. Coba lagi besok.'),
      findsOneWidget,
    );
    expect(find.text(reportSentToDeveloperMessage), findsNothing);
  });

  group('CommentTile', () {
    testWidgets('a reader can report the comment or its author', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const CommentTile(
          comment: _comment,
          programId: 'p1',
          date: '2026-10-15',
        ),
      );

      await tester.tap(find.byKey(const Key('comment-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Laporkan komentar'), findsOneWidget);
      expect(find.text('Laporkan pengguna'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comment-report-user')));
      await tester.pumpAndSettle();
      expect(find.text('Laporkan pengguna'), findsOneWidget);
      await tapKey(tester, 'report-reason-inappropriate');
      await tapKey(tester, 'report-submit');
      await tester.pumpAndSettle();

      verify(
        () => repository.report(
          const ReportTarget.user('g1', teacher: true),
          reason: ReportReason.inappropriate,
          note: null,
        ),
      ).called(1);
    });

    testWidgets('the author sees no report menu', (tester) async {
      await pumpHost(
        tester,
        CommentTile(
          comment: _comment.copyWith(teacherId: 's1'),
          programId: 'p1',
          date: '2026-10-15',
        ),
      );

      expect(find.byKey(const Key('comment-menu')), findsNothing);
    });
  });
}
