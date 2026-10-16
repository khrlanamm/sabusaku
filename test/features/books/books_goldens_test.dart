// Golden images of the student's book catalog screens in both themes:
//
//   flutter test test/features/books/books_goldens_test.dart --update-goldens
//
// Made on macOS; other platforms skip the comparison (font rasterisation
// differs). Network covers cannot load in tests, so the automatic covers
// show, as they do while a cover is loading.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sabusaku/app/theme/theme.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/books/data/catalog_repository.dart';
import 'package:sabusaku/features/books/domain/catalog_book.dart';
import 'package:sabusaku/features/books/presentation/book_explore_screen.dart';
import 'package:sabusaku/features/books/presentation/catalog_book_screen.dart';
import 'package:sabusaku/features/student/data/student_repository.dart';
import 'package:sabusaku/features/student/presentation/start_book_form.dart';

import 'sample_catalog.dart';

/// Starts with a catalog book already picked, as after "Baca buku ini".
class _PresetPick extends PendingBookPick {
  @override
  CatalogEntry? build() => sampleEntries.first;
}

final _cases = <String, Widget>{
  'book_explore': const BookExploreScreen(),
  'catalog_book': const CatalogBookScreen(bookId: 'bk_laskar'),
  'start_book_picked': const Scaffold(body: StartBookForm()),
};

Future<void> _loadFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = (entry['family'] as String).replaceFirst('packages/', '');
    final loader = FontLoader(family.split('/').last);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    await initializeDateFormatting('id_ID');
  });

  for (final mode in ['light', 'dark']) {
    for (final MapEntry(key: name, value: screen) in _cases.entries) {
      testWidgets('$name ($mode)', skip: !Platform.isMacOS, (tester) async {
        debugDisableShadows = false;
        try {
          tester.view.physicalSize = const Size(1080, 2340);
          tester.view.devicePixelRatio = 2.625;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                wibClockProvider.overrideWithValue(
                  WibClock(() => DateTime.utc(2026, 10, 16, 3)),
                ),
                catalogIndexProvider.overrideWith(
                  (_) => Stream.value(sampleEntries),
                ),
                catalogBookProvider('bk_laskar')
                    .overrideWith((_) => Stream.value(sampleBook)),
                recommendedBookIdsProvider.overrideWithValue(const [
                  'bk_bumi',
                  'bk_filosofi',
                ]),
                schoolBookStatsProvider.overrideWith(
                  (_) => Stream.value(const {
                    'bk_laskar': (readers: 5, active: 2),
                    'bk_cantik': (readers: 2, active: 1),
                  }),
                ),
                activeProgramProvider.overrideWith((_) => Stream.value(null)),
                if (name == 'start_book_picked')
                  pendingBookPickProvider.overrideWith(_PresetPick.new),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                darkTheme: buildDarkTheme(),
                themeMode: mode == 'dark' ? ThemeMode.dark : ThemeMode.light,
                locale: const Locale('id', 'ID'),
                supportedLocales: const [Locale('id', 'ID')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: screen,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          // Let fields filled after the first frame (the ISBN) finish
          // floating their labels.
          await tester.pump(const Duration(seconds: 1));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_$mode.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
}
