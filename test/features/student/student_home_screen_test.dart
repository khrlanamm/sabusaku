import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/core/models/program.dart';
import 'package:sabusaku/core/models/student_stats.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:sabusaku/core/time/periods.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/notifications/notification_service.dart';
import 'package:sabusaku/features/ranking/data/ranking_repository.dart';
import 'package:sabusaku/features/ranking/domain/ranking.dart';
import 'package:sabusaku/features/student/data/student_repository.dart';
import 'package:sabusaku/features/student/domain/journal_filter.dart';
import 'package:sabusaku/features/student/presentation/student_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNotifications extends Mock implements NotificationService {}

const _session = Session(
  uid: 's1',
  role: UserRole.siswa,
  schoolId: 'sman1',
  profile: AppUser(
    uid: 's1',
    role: UserRole.siswa,
    name: 'Bima Saputra',
    email: 'bima@sekolah.test',
    classId: 'XII-A1',
  ),
);

Program _book(String id, String title, String start) => Program(
  id: id,
  studentId: 's1',
  book: Book(title: title, author: 'Penulis', totalPages: 100),
  startDate: start,
  targetDate: start,
  status: ProgramStatus.completed,
  currentPage: 100,
  journalCount: 3,
);

final _programs = [
  _book('p4', 'Buku Empat', '2026-10-01'),
  _book('p3', 'Buku Tiga', '2026-09-01'),
  _book('p2', 'Buku Dua', '2026-08-01'),
  _book('p1', 'Buku Satu', '2026-07-01'),
];

void main() {
  late ProviderContainer container;

  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    Widget page(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: Routes.studentHome,
      routes: [
        GoRoute(
          path: Routes.studentHome,
          builder: (_, _) => const StudentHomeScreen(),
        ),
        GoRoute(
          path: Routes.studentJournals,
          builder: (_, _) => page('tab jurnal'),
        ),
        GoRoute(
          path: Routes.studentStreak,
          builder: (_, _) => page('halaman streak'),
        ),
        GoRoute(
          path: Routes.studentBookHistory,
          builder: (_, state) =>
              page('riwayat ${state.uri.queryParameters['status'] ?? 'semua'}'),
        ),
        GoRoute(
          path: Routes.studentRanking,
          builder: (_, _) => page('halaman peringkat'),
        ),
        GoRoute(
          path: Routes.studentBadges,
          builder: (_, _) => page('halaman lencana'),
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = _MockNotifications();
    when(() => notifications.shouldExplainPermission(_session))
        .thenAnswer((_) async => false);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        sessionProvider.overrideWithValue(_session),
        currentSessionProvider.overrideWithValue(_session),
        wibClockProvider.overrideWithValue(
          WibClock(() => DateTime.utc(2026, 10, 18, 3)),
        ),
        activeProgramProvider.overrideWith((_) => Stream.value(null)),
        myProgramsProvider.overrideWith((_) => Stream.value(_programs)),
        myStatsProvider.overrideWith(
          (_) => Stream.value(
            const StudentStats(
              studentId: 's1',
              name: 'Bima Saputra',
              streakCurrent: 4,
              streakBest: 9,
              journalCountMonth: 6,
              journalCountTotal: 12,
              booksCompleted: 4,
            ),
          ),
        ),
        leaderboardProvider('month-2026-10').overrideWith(
          (_) => Stream.value(
            const Leaderboard(
              period: RankPeriod.month('2026-10'),
              entries: [
                RankEntry(studentId: 's2', name: 'Nadia', books: 2, days: 9),
                RankEntry(studentId: 's1', name: 'Bima', books: 1, days: 6),
                RankEntry(studentId: 's3', name: 'Fajar', days: 2),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapCard(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('streak sekarang dan terbaik dalam satu kartu', (tester) async {
    await pump(tester);
    final card = find.byKey(const Key('home-stat-streak'));
    expect(find.descendant(of: card, matching: find.text('4 hari')), findsOne);
    expect(
      find.descendant(of: card, matching: find.text('Terbaik 9 hari')),
      findsOne,
    );
  });

  testWidgets('peringkat bulan ini dari papan sekolah', (tester) async {
    await pump(tester);
    final card = find.byKey(const Key('home-stat-rank'));
    expect(find.descendant(of: card, matching: find.text('#2')), findsOne);
    expect(
      find.descendant(of: card, matching: find.text('Bulan ini, dari 3')),
      findsOne,
    );
  });

  testWidgets('riwayat buku hanya tiga, sisanya lewat Lihat semua', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Buku Empat'), findsOne);
    expect(find.text('Buku Dua'), findsOne);
    expect(find.text('Buku Satu'), findsNothing);
    await tapCard(tester, 'home-book-history');
    expect(find.text('riwayat semua'), findsOne);
  });

  for (final (key, range) in [
    ('home-stat-month', const MonthJournals('2026-10') as JournalRange),
    ('home-stat-journals', const AllJournals()),
  ]) {
    testWidgets('$key membuka tab Jurnal pada rentangnya', (tester) async {
      await pump(tester);
      await tapCard(tester, key);
      expect(find.text('tab jurnal'), findsOne);
      expect(container.read(journalFilterStateProvider).range, range);
    });
  }

  for (final (key, page) in [
    ('home-stat-streak', 'halaman streak'),
    ('home-stat-books', 'riwayat selesai'),
    ('home-stat-rank', 'halaman peringkat'),
    ('home-stat-badges', 'halaman lencana'),
  ]) {
    testWidgets('$key membuka halamannya', (tester) async {
      await pump(tester);
      await tapCard(tester, key);
      expect(find.text(page), findsOne);
    });
  }
}
