// Widget tests and light/dark goldens of the teacher's book catalog screens.
//
//   flutter test test/features/books/teacher --update-goldens
//
// The goldens were made on macOS; other platforms skip the comparison
// because font rasterisation differs (as in test/app/theme).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/app/theme/theme.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/books/data/book_admin_repository.dart';
import 'package:sabusaku/features/books/data/catalog_repository.dart';
import 'package:sabusaku/features/books/domain/book_history.dart';
import 'package:sabusaku/features/books/domain/book_suggestion.dart';
import 'package:sabusaku/features/books/domain/catalog_book.dart';
import 'package:sabusaku/features/books/presentation/teacher/book_format.dart';
import 'package:sabusaku/features/books/presentation/teacher/book_review_widgets.dart';
import 'package:sabusaku/features/books/presentation/teacher/deleted_books_screen.dart';
import 'package:sabusaku/features/books/presentation/teacher/suggestions_screen.dart';
import 'package:sabusaku/features/books/presentation/teacher/teacher_book_screen.dart';
import 'package:sabusaku/features/books/presentation/teacher/teacher_books_screen.dart';

class _MockRepository extends Mock implements BookAdminRepository {}

const _teacher = Session(
  uid: 'g1',
  role: UserRole.guru,
  schoolId: 'sman1sukodadi',
  profile: AppUser(
    uid: 'g1',
    role: UserRole.guru,
    name: 'Sugito, S.T., M.Pd.',
    email: 'githo82@gmail.com',
  ),
);

const _sugito = BookActor(
  uid: 'g1',
  name: 'Sugito, S.T., M.Pd.',
  schoolId: 'sman1sukodadi',
  schoolName: 'SMA Negeri 1 Sukodadi',
);
const _anam = BookActor(
  uid: 'g2',
  name: 'Khoirul Anam, S.Kom.',
  schoolId: 'sman1sukodadi',
  schoolName: 'SMA Negeri 1 Sukodadi',
);
const _import = BookActor(name: 'Impor awal', kind: 'import');

final _now = DateTime.now();

final _laskar = CatalogBook(
  id: 'b1',
  title: 'Laskar Pelangi',
  authors: const ['Andrea Hirata'],
  publisher: 'Bentang Pustaka',
  publishedYear: 2005,
  isbn13: '9789793062792',
  pageCount: 529,
  categories: const ['Novel'],
  description:
      'Sepuluh anak dari keluarga miskin bersekolah di sebuah sekolah '
      'Muhammadiyah di Belitung yang hampir ditutup. Dengan guru yang '
      'gigih, mereka belajar, bermimpi, dan membuktikan bahwa pendidikan '
      'adalah jalan untuk mengubah hidup. Kisah persahabatan, cinta '
      'pertama, dan semangat yang tidak pernah padam di tengah segala '
      'keterbatasan.',
  readerCount: 12,
  createdBy: _import,
  updatedBy: _sugito,
  updatedAt: _now.subtract(const Duration(hours: 2)),
  version: 3,
);

final _deleted = CatalogBook(
  id: 'b2',
  title: 'Laskar Pelangi (Edisi Lama)',
  authors: const ['Andrea Hirata'],
  pageCount: 534,
  categories: const ['Novel'],
  active: false,
  // Older than a week, so every relative label shows a fixed date.
  deletedAt: DateTime(2026, 9, 1, 9, 30),
  deletedBy: _anam,
  deleteReason: 'Duplikat edisi baru',
  duplicateOf: 'b1',
  createdBy: _import,
);

final _history = [
  BookHistoryEntry(
    id: 'h3',
    type: BookHistoryType.suggestionApplied,
    changes: {'pageCount': (from: 534, to: 529)},
    by: _sugito,
    at: _now.subtract(const Duration(hours: 2)),
    suggestionId: 's0',
  ),
  BookHistoryEntry(
    id: 'h2',
    type: BookHistoryType.updated,
    changes: {
      'publisher': (from: 'Bentang', to: 'Bentang Pustaka'),
      'categories': (from: <Object?>['Lainnya'], to: <Object?>['Novel']),
    },
    by: _anam,
    at: _now.subtract(const Duration(days: 2)),
  ),
  BookHistoryEntry(
    id: 'h1',
    type: BookHistoryType.created,
    by: _import,
    at: _now.subtract(const Duration(days: 3)),
  ),
];

final _editSuggestion = BookSuggestion(
  id: 's1',
  kind: SuggestionKind.edit,
  bookId: 'b1',
  proposed: const {'pageCount': 520, 'isbn13': '9789793062808'},
  count: 3,
  from: const [
    (
      schoolId: 'sman1sukodadi',
      schoolName: 'SMA Negeri 1 Sukodadi',
      programId: 'p1',
    ),
    (schoolId: 'smauji', schoolName: 'SMA Uji Coba', programId: 'p9'),
  ],
  updatedAt: _now.subtract(const Duration(minutes: 40)),
);

final _newSuggestion = BookSuggestion(
  id: 's2',
  kind: SuggestionKind.newBook,
  proposed: const {
    'title': 'Hujan',
    'authors': ['Tere Liye'],
    'pageCount': 320,
    'publisher': 'Gramedia Pustaka Utama',
  },
  from: const [
    (
      schoolId: 'sman1sukodadi',
      schoolName: 'SMA Negeri 1 Sukodadi',
      programId: 'p2',
    ),
  ],
  updatedAt: _now.subtract(const Duration(hours: 5)),
);

const _entries = [
  CatalogEntry(
    id: 'b1',
    title: 'Laskar Pelangi',
    authors: 'Andrea Hirata',
    pageCount: 529,
    year: 2005,
    categories: ['Novel'],
    readerCount: 12,
  ),
  CatalogEntry(
    id: 'b3',
    title: 'Bumi Manusia',
    authors: 'Pramoedya Ananta Toer',
    pageCount: 535,
    year: 1980,
    categories: ['Novel', 'Sastra Klasik'],
    readerCount: 7,
  ),
  CatalogEntry(
    id: 'b4',
    title: 'Ronggeng Dukuh Paruk',
    authors: 'Ahmad Tohari',
    pageCount: 408,
    year: 1982,
    categories: ['Novel', 'Sastra Klasik'],
  ),
  CatalogEntry(
    id: 'b5',
    title: 'Filosofi Teras',
    authors: 'Henry Manampiring',
    pageCount: 344,
    year: 2018,
    categories: ['Pengembangan Diri'],
    readerCount: 3,
  ),
  CatalogEntry(
    id: 'b6',
    title: 'Hujan',
    authors: 'Tere Liye',
    pageCount: 320,
    year: 2016,
    categories: ['Novel', 'Remaja'],
    readerCount: 5,
  ),
  CatalogEntry(
    id: 'b7',
    title: 'Siti Nurbaya',
    authors: 'Marah Rusli',
    pageCount: 271,
    year: 1922,
    categories: ['Sastra Klasik'],
  ),
];

List<Override> _overrides(BookAdminRepository repository) => [
  currentSessionProvider.overrideWithValue(_teacher),
  bookAdminRepositoryProvider.overrideWithValue(repository),
  catalogIndexProvider.overrideWith((_) => Stream.value(_entries)),
  schoolRecommendedBooksProvider.overrideWith(
    (_) => Stream.value(const ['b3']),
  ),
  pendingSuggestionsProvider.overrideWith(
    (_) => Stream.value([_editSuggestion, _newSuggestion]),
  ),
  adminBookProvider('b1').overrideWith((_) => Stream.value(_laskar)),
  adminBookProvider('b2').overrideWith((_) => Stream.value(_deleted)),
  bookHistoryProvider('b1').overrideWith((_) => Stream.value(_history)),
  bookHistoryProvider('b2').overrideWith((_) => Stream.value(const [])),
  bookSuggestionsProvider('b1')
      .overrideWith((_) => Stream.value([_editSuggestion])),
  bookSuggestionsProvider('b2').overrideWith((_) => Stream.value(const [])),
  schoolBookReadersProvider('b1').overrideWith((_) => Stream.value(4)),
  schoolBookReadersProvider('b2').overrideWith((_) => Stream.value(0)),
  suggestionProvider('s1').overrideWith((_) => Stream.value(_editSuggestion)),
  suggestionProvider('s2').overrideWith((_) => Stream.value(_newSuggestion)),
  deletedBooksProvider.overrideWith((_) => Stream.value([_deleted])),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  BookAdminRepository? repository,
  bool dark = false,
  double height = 2340,
}) async {
  tester.view.physicalSize = Size(1080, height);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(repository ?? _MockRepository()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Loads every font of the app's FontManifest so goldens show real text.
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
    await initializeDateFormatting('id_ID');
    await _loadFonts();
  });

  group('formatting', () {
    test('values become one readable line', () {
      expect(formatBookValue('authors', ['A', 'B']), 'A, B');
      expect(formatBookValue('publisher', null), '—');
      expect(formatBookValue('publisher', '  '), '—');
      expect(formatBookValue('status', 'deleted'), 'Dihapus');
      expect(formatBookValue('description', 'x' * 200).length, 141);
      expect(orderedFields(['description', 'pageCount', 'zzz', 'title']), [
        'title',
        'pageCount',
        'description',
        'zzz',
      ]);
    });

    test('actor and source lines', () {
      expect(actorLine(_sugito), 'Sugito, S.T., M.Pd. · SMA Negeri 1 Sukodadi');
      expect(actorLine(_import), 'Impor awal');
      expect(
        suggestionSourceLine(4, ['A', 'B', 'C', 'A']),
        'Dari 4 siswa · A, B +1 sekolah',
      );
    });
  });

  testWidgets('a diff strikes the old value and shows the new one', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: FieldDiff(field: 'pageCount', from: 534, to: 529),
        ),
      ),
    );
    expect(find.text('Jumlah halaman'), findsOneWidget);
    final rich = tester.widget<Text>(find.byType(Text).last);
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.first.text, '534');
    expect(spans.first.style!.decoration, TextDecoration.lineThrough);
    expect(spans.last.text, '529');
  });

  testWidgets('applying part of a suggestion sends only checked fields', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(() => repository.applySuggestion(any(), fields: any(named: 'fields')))
        .thenAnswer((_) async {});
    await _pump(
      tester,
      const TeacherBookScreen(bookId: 'b1'),
      repository: repository,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('suggestion-apply')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Terapkan semua'), findsOneWidget);
    await tester.tap(find.byKey(const Key('suggestion-field-isbn13')));
    await tester.pump();
    expect(find.text('Terapkan 1 perubahan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('suggestion-apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    verify(() => repository.applySuggestion('s1', fields: ['pageCount']))
        .called(1);
  });

  testWidgets('deleting asks for a reason and says any PJ can restore it', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(
      () => repository.deleteBook(
        any(),
        reason: any(named: 'reason'),
        duplicateOf: any(named: 'duplicateOf'),
      ),
    ).thenAnswer((_) async {});
    await _pump(
      tester,
      const TeacherBookScreen(bookId: 'b1'),
      repository: repository,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('book-delete')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('book-delete')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('book-delete')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('mengaktifkannya'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('delete-reason')),
      'Salah data',
    );
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    verify(
      () =>
          repository.deleteBook('b1', reason: 'Salah data', duplicateOf: null),
    ).called(1);
  });

  testWidgets('a deleted book shows who deleted it and can be restored', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(() => repository.restoreBook(any())).thenAnswer((_) async {});
    await _pump(
      tester,
      const TeacherBookScreen(bookId: 'b2'),
      repository: repository,
    );

    expect(find.byKey(const Key('book-deleted-banner')), findsOneWidget);
    expect(find.textContaining('Khoirul Anam, S.Kom.'), findsOneWidget);
    expect(find.textContaining('Duplikat edisi baru'), findsOneWidget);
    expect(find.byKey(const Key('book-delete')), findsNothing);
    await tester.tap(find.byKey(const Key('book-restore')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    verify(() => repository.restoreBook('b2')).called(1);
  });

  testWidgets('the catalog puts the school recommendations on top', (
    tester,
  ) async {
    await _pump(tester, const TeacherBooksScreen());
    expect(find.text('Rekomendasi sekolah'), findsOneWidget);
    expect(find.text('Semua buku (6)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('books-search')), 'pramoedya');
    await tester.pump();
    expect(find.text('Rekomendasi sekolah'), findsNothing);
    expect(find.text('1 buku'), findsOneWidget);
    expect(find.text('Bumi Manusia'), findsOneWidget);
  });

  final goldens = <String, Widget>{
    'teacher_books': const TeacherBooksScreen(),
    'teacher_book': const TeacherBookScreen(bookId: 'b1'),
    'teacher_book_deleted': const TeacherBookScreen(bookId: 'b2'),
    'suggestion_edit': const SuggestionReviewScreen(id: 's1'),
    'suggestion_new': const SuggestionReviewScreen(id: 's2'),
    'suggestions': const SuggestionsScreen(),
    'deleted_books': const DeletedBooksScreen(),
  };
  for (final mode in ['light', 'dark']) {
    for (final MapEntry(key: name, value: screen) in goldens.entries) {
      testWidgets('$name ($mode)', skip: !Platform.isMacOS, (tester) async {
        debugDisableShadows = false;
        try {
          // The book page is long: render it whole to review every section.
          await _pump(
            tester,
            screen,
            dark: mode == 'dark',
            height: name == 'teacher_book' ? 5600 : 2340,
          );
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
