import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/time/periods.dart';
import 'package:sabusaku/features/ranking/data/ranking_repository.dart';
import 'package:sabusaku/features/ranking/domain/ranking.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/core/models/school.dart';
import 'package:sabusaku/core/models/student_stats.dart';
import 'package:sabusaku/core/models/student_status.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/data/school_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/notifications/notification_service.dart';
import 'package:sabusaku/features/teacher/data/teacher_repository.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_active_books_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_month_journals_screen.dart';

class _MockNotifications extends Mock implements NotificationService {}

const _teacher = Session(
  uid: 'guru1',
  role: UserRole.guru,
  schoolId: 'sman1',
  profile: AppUser(
    uid: 'guru1',
    role: UserRole.guru,
    name: 'Bu Sari',
    email: 'sari@gmail.com',
    homeroomClass: 'XI-A1',
  ),
);

const _school = School(
  id: 'sman1',
  name: 'SMA Negeri 1',
  classes: ['XI-A1', 'XI-B1'],
  extracurriculars: ['Masis-KIR', 'PMR'],
);

ActiveProgramSummary _book(String title, int percent) => ActiveProgramSummary(
  programId: 'p-$title',
  title: title,
  author: 'Penulis',
  totalPages: 100,
  currentPage: percent,
  percent: percent,
  startDate: '2026-10-01',
  targetDate: '2026-10-31',
);

final _students = [
  StudentStats(
    studentId: 's1',
    name: 'Anisa',
    classId: 'XI-A1',
    extracurriculars: const ['Masis-KIR'],
    status: StudentStatus.aktif,
    activeProgram: _book('Bumi', 40),
    journalCountMonth: 5,
  ),
  const StudentStats(
    studentId: 's2',
    name: 'Bima',
    classId: 'XI-A1',
    status: StudentStatus.perluPerhatian,
    journalCountMonth: 2,
  ),
  StudentStats(
    studentId: 's3',
    name: 'Citra',
    classId: 'XI-B1',
    extracurriculars: const ['Masis-KIR', 'PMR'],
    status: StudentStatus.aktif,
    activeProgram: _book('Laskar Pelangi', 70),
    journalCountMonth: 7,
  ),
];

void main() {
  late ProviderContainer container;

  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(WidgetTester tester, {Session session = _teacher}) async {
    final router = GoRouter(
      initialLocation: Routes.teacherDashboard,
      routes: [
        GoRoute(
          path: Routes.teacherDashboard,
          builder: (_, _) => const TeacherDashboardScreen(),
        ),
        GoRoute(
          path: Routes.teacherActiveBooks,
          builder: (_, _) => const TeacherActiveBooksScreen(),
        ),
        GoRoute(
          path: Routes.teacherMonthJournals,
          builder: (_, _) => const TeacherMonthJournalsScreen(),
        ),
        GoRoute(
          path: Routes.teacherStudents,
          builder: (_, _) => const Text('daftar siswa'),
        ),
        GoRoute(
          path: Routes.teacherProfile,
          builder: (_, _) => const Text('profil'),
        ),
      ],
    );
    final notifications = _MockNotifications();
    when(() => notifications.shouldExplainPermission(session))
        .thenAnswer((_) async => false);
    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        sessionProvider.overrideWithValue(session),
        currentSessionProvider.overrideWithValue(session),
        wibClockProvider.overrideWithValue(
          WibClock(() => DateTime.utc(2026, 10, 18, 3)),
        ),
        schoolProvider.overrideWith((_) => Stream.value(_school)),
        teacherStudentsProvider.overrideWith((_) => Stream.value(_students)),
        pendingStudentsProvider.overrideWith((_) => Stream.value(const [])),
        leaderboardProvider('month-2026-10').overrideWith(
          (_) => Stream.value(
            const Leaderboard(period: RankPeriod.month('2026-10')),
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

  String cardValue(WidgetTester tester, String key) {
    final texts = find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(texts.first).data!;
  }

  Future<void> pickMenu(WidgetTester tester, String key, String item) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opens on "Binaan saya" and names the month on the journal card',
    (tester) async {
      await pump(tester);
      expect(find.text('Jurnal Oktober 2026'), findsOneWidget);
      // Anisa and Bima are in the homeroom class XI-A1.
      expect(cardValue(tester, 'dashboard-card-students'), '2');
      expect(cardValue(tester, 'dashboard-card-books'), '1');
      expect(cardValue(tester, 'dashboard-card-journals'), '7');

      await tester.tap(find.byKey(const Key('scope-all')));
      await tester.pumpAndSettle();
      expect(cardValue(tester, 'dashboard-card-students'), '3');

      await pickMenu(tester, 'scope-ekskul', 'PMR');
      expect(find.text('PMR'), findsOneWidget);
      expect(cardValue(tester, 'dashboard-card-students'), '1');

      await pickMenu(tester, 'scope-class', 'XI-B1');
      expect(find.text('Kelas XI-B1'), findsOneWidget);
      expect(cardValue(tester, 'dashboard-card-journals'), '7');
    },
  );

  testWidgets('a teacher without a group starts on every student', (
    tester,
  ) async {
    await pump(
      tester,
      session: _teacher.copyWith(
        profile: _teacher.profile.copyWith(homeroomClass: null),
      ),
    );
    expect(find.byKey(const Key('scope-mine')), findsNothing);
    expect(cardValue(tester, 'dashboard-card-students'), '3');
    await tester.scrollUntilVisible(
      find.byKey(const Key('dashboard-set-roles')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('dashboard-set-roles')), findsOneWidget);
  });

  testWidgets('the cards open their lists in the same scope', (tester) async {
    await pump(tester);
    await pickMenu(tester, 'scope-ekskul', 'Masis-KIR');

    await tester.tap(find.byKey(const Key('dashboard-card-books')));
    await tester.pumpAndSettle();
    expect(find.text('Buku aktif'), findsOneWidget);
    expect(find.text('Bumi'), findsOneWidget);
    expect(find.text('Laskar Pelangi'), findsOneWidget);
    expect(find.text('Masis-KIR'), findsOneWidget); // the scope chip

    // Narrowing here carries back to the dashboard.
    await pickMenu(tester, 'scope-class', 'XI-B1');
    expect(find.text('Bumi'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(cardValue(tester, 'dashboard-card-students'), '1');

    await tester.tap(find.byKey(const Key('dashboard-card-journals')));
    await tester.pumpAndSettle();
    expect(find.text('Jurnal Oktober 2026'), findsOneWidget);
    expect(find.text('Citra'), findsOneWidget);
    expect(find.text('Anisa'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-card-students')));
    await tester.pumpAndSettle();
    expect(find.text('daftar siswa'), findsOneWidget);
    expect(container.read(studentListFilterProvider), (
      mine: false,
      classId: 'XI-B1',
      extracurricular: null,
      status: null,
    ));
  });

  testWidgets('a status row opens the list with "Binaan saya" and the status', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('dashboard-status-perlu_perhatian')));
    await tester.pumpAndSettle();
    expect(find.text('daftar siswa'), findsOneWidget);
    expect(container.read(studentListFilterProvider), (
      mine: true,
      classId: null,
      extracurricular: null,
      status: StudentStatus.perluPerhatian,
    ));
  });
}
