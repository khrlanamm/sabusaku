import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sabusaku/app/theme/theme.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/books/data/catalog_repository.dart';
import 'package:sabusaku/features/student/presentation/start_book_form.dart';

import 'sample_catalog.dart';

String fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

Future<void> pumpForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wibClockProvider.overrideWithValue(
          WibClock(() => DateTime.utc(2026, 10, 16, 3)),
        ),
        catalogIndexProvider.overrideWith((_) => Stream.value(sampleEntries)),
        catalogBookProvider('bk_laskar')
            .overrideWith((_) => Stream.value(sampleBook)),
        recommendedBookIdsProvider.overrideWithValue(const ['bk_bumi']),
        schoolBookStatsProvider.overrideWith((_) => Stream.value(const {})),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: StartBookForm()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('picking a catalog book fills the form; edits are flagged', (
    tester,
  ) async {
    await pumpForm(tester);

    // Before typing, the school's recommendation is offered.
    expect(find.text('Rekomendasi sekolah'), findsWidgets);
    expect(find.text('Bumi Manusia'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('book-search')), 'laskar');
    await tester.pump();
    expect(find.byKey(const Key('book-search-result-0')), findsOneWidget);
    expect(find.byKey(const Key('book-search-result-1')), findsNothing);

    await tester.tap(find.byKey(const Key('book-search-result-0')));
    await tester.pump();
    await tester.pump();

    expect(fieldText(tester, 'book-title'), 'Laskar Pelangi');
    expect(fieldText(tester, 'book-author'), 'Andrea Hirata');
    expect(fieldText(tester, 'book-pages'), '529');
    expect(find.byKey(const Key('book-clear-pick')), findsOneWidget);
    // The ISBN comes from the full record.
    expect(find.text('9789793062792'), findsOneWidget);
    expect(find.byKey(const Key('book-edited-note')), findsNothing);

    // The student's copy has a different page count: a suggestion.
    await tester.enterText(find.byKey(const Key('book-pages')), '520');
    await tester.pump();
    expect(find.byKey(const Key('book-edited-note')), findsOneWidget);

    // "Ganti buku" empties the form and brings the search back.
    await tester.tap(find.byKey(const Key('book-clear-pick')));
    await tester.pump();
    expect(fieldText(tester, 'book-title'), isEmpty);
    expect(find.byKey(const Key('book-search')), findsOneWidget);
  });

  testWidgets('a book typed by hand is announced as a suggestion', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.tap(find.byKey(const Key('book-manual')));
    await tester.pump();

    expect(find.byKey(const Key('book-search')), findsNothing);
    expect(find.byKey(const Key('book-cover-photo')), findsOneWidget);
    expect(find.byKey(const Key('book-new-note')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('book-title')), 'Buku Baru');
    await tester.pump();
    expect(find.byKey(const Key('book-new-note')), findsOneWidget);
  });

  testWidgets('a search without results says so', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byKey(const Key('book-search')), 'zzzz');
    await tester.pump();
    expect(find.textContaining('Tidak ada buku yang cocok'), findsOneWidget);
  });
}
