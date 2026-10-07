import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/data/reading_repository.dart';
import 'package:sabusaku/core/models/journal.dart';
import 'package:sabusaku/core/models/program.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/student/data/journal_outbox.dart';
import 'package:sabusaku/features/student/data/student_repository.dart';
import 'package:sabusaku/features/student/domain/journal_draft.dart';
import 'package:sabusaku/features/student/presentation/journal_form_screen.dart';

class _MockWriter extends Mock implements JournalWriter {}

const _today = '2026-10-07';
const _program = Program(
  id: 'p1',
  studentId: 's1',
  book: Book(title: 'Laskar Pelangi', author: 'Andrea Hirata', totalPages: 300),
  startDate: '2026-10-01',
  targetDate: '2026-10-31',
  currentPage: 120,
);
const _text = 'Ikal mulai menyadari bahwa pendidikan mengubah hidupnya.';

void main() {
  late _MockWriter writer;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    registerFallbackValue(
      const JournalDraft(
        date: _today,
        pageStart: 1,
        pageEnd: 1,
        durationRange: DurationRange.lt15,
        keyInformation: '',
      ),
    );
  });

  setUp(() => writer = _MockWriter());

  Future<void> pump(WidgetTester tester, {Journal? existing}) async {
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('beranda')),
          routes: [
            GoRoute(path: 'form', builder: (_, _) => const JournalFormScreen()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wibClockProvider.overrideWithValue(
            WibClock(() => DateTime.utc(2026, 10, 7, 3)),
          ),
          activeProgramProvider.overrideWith((_) => Stream.value(_program)),
          journalProvider.overrideWith(
            (_, args) => Stream.value(args.$2 == _today ? existing : null),
          ),
          journalsProvider.overrideWith((_, _) => Stream.value(const [])),
          journalWriterProvider.overrideWithValue(writer),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.byKey(const Key('journal-save'));
    // A focused field keeps scrolling its caret back into view.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('starts after the last page read and offers three dates', (
    tester,
  ) async {
    await pump(tester);
    final start = tester.widget<TextFormField>(
      find.byKey(const Key('journal-page-start')),
    );
    expect(start.controller!.text, '121');
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
    expect(find.text('2 hari lalu'), findsOneWidget);
  });

  testWidgets('an incomplete journal is not saved and says why', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('journal-page-end')), '400');
    await tester.enterText(
      find.byKey(const Key('journal-key-information')),
      'Terlalu pendek',
    );
    await tapSave(tester);

    expect(find.text('Buku ini hanya 300 halaman'), findsOneWidget);
    expect(find.textContaining('Minimal 30 karakter'), findsOneWidget);
    expect(find.text('Pilih durasi membaca'), findsOneWidget);
    verifyNever(
      () => writer.save(
        programId: any(named: 'programId'),
        bookTitle: any(named: 'bookTitle'),
        draft: any(named: 'draft'),
        isNew: any(named: 'isNew'),
      ),
    );
  });

  testWidgets('a valid journal is handed to the outbox and the form closes', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('journal-page-end')), '140');
    await tester.tap(find.byKey(const Key('journal-duration-15to30')));
    await tester.enterText(
      find.byKey(const Key('journal-key-information')),
      _text,
    );
    await tapSave(tester);

    final draft =
        verify(
              () => writer.save(
                programId: 'p1',
                bookTitle: 'Laskar Pelangi',
                draft: captureAny(named: 'draft'),
                isNew: true,
              ),
            ).captured.single
            as JournalDraft;
    expect(draft.date, _today);
    expect(draft.pageStart, 121);
    expect(draft.pageEnd, 140);
    expect(draft.durationRange, DurationRange.m15to30);
    expect(draft.keyInformation, _text);
    expect(find.text('beranda'), findsOneWidget);
  });

  testWidgets('an existing journal for the date opens in edit mode', (
    tester,
  ) async {
    await pump(
      tester,
      existing: const Journal(
        programId: 'p1',
        date: _today,
        studentId: 's1',
        pageStart: 100,
        pageEnd: 120,
        durationRange: DurationRange.gt60,
        keyInformation: _text,
      ),
    );
    expect(find.text('Simpan perubahan'), findsOneWidget);
    expect(find.text(_text), findsOneWidget);

    await tester.enterText(find.byKey(const Key('journal-page-end')), '125');
    await tapSave(tester);
    verify(
      () => writer.save(
        programId: 'p1',
        bookTitle: 'Laskar Pelangi',
        draft: any(named: 'draft'),
        isNew: false,
      ),
    ).called(1);
  });
}
