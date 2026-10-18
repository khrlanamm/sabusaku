// Renders the main screens in the light and the dark theme as golden images,
// so a colour change can be checked by eye in both modes:
//
//   flutter test test/app/theme --update-goldens
//
// then open test/app/theme/goldens/*.png. The images were made on macOS and
// font rasterisation differs between platforms, so other platforms (CI on
// Linux) skip the comparison.
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
import 'package:sabusaku/core/data/reading_repository.dart';
import 'package:sabusaku/core/data/report_repository.dart';
import 'package:sabusaku/core/models/journal.dart';
import 'package:sabusaku/core/models/member.dart';
import 'package:sabusaku/core/models/program.dart';
import 'package:sabusaku/core/models/report.dart';
import 'package:sabusaku/core/models/school.dart';
import 'package:sabusaku/core/models/student_stats.dart';
import 'package:sabusaku/core/models/student_status.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:sabusaku/core/time/wib_clock.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/data/school_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/auth/presentation/complete_profile_screen.dart';
import 'package:sabusaku/features/auth/presentation/login_screen.dart';
import 'package:sabusaku/features/auth/presentation/register_screen.dart';
import 'package:sabusaku/features/auth/presentation/terms_screen.dart';
import 'package:sabusaku/features/notifications/notification_service.dart';
import 'package:sabusaku/features/student/data/student_repository.dart';
import 'package:sabusaku/features/student/presentation/book_screen.dart';
import 'package:sabusaku/features/student/presentation/journal_detail_screen.dart';
import 'package:sabusaku/features/student/presentation/journal_form_screen.dart';
import 'package:sabusaku/features/student/presentation/journal_history_screen.dart';
import 'package:sabusaku/features/student/presentation/student_home_screen.dart';
import 'package:sabusaku/features/student/presentation/student_profile_screen.dart';
import 'package:sabusaku/features/teacher/data/teacher_repository.dart';
import 'package:sabusaku/features/teacher/presentation/add_students_screen.dart';
import 'package:sabusaku/features/teacher/presentation/reports_screen.dart';
import 'package:sabusaku/features/teacher/presentation/school_screen.dart';
import 'package:sabusaku/features/teacher/presentation/add_teacher_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_active_books_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_month_journals_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_journal_detail_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_profile_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_student_detail_screen.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_students_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockNotifications extends Mock implements NotificationService {}

class _MockReportRepository extends Mock implements ReportRepository {}

const _today = '2026-10-16';
// 10:00 WIB on the 16th.
final _clock = WibClock(() => DateTime.utc(2026, 10, 16, 3));

const _school = School(
  id: 'sman1sukodadi',
  name: 'SMA Negeri 1 Sukodadi',
  classes: ['X-D', 'X-G', 'XI-A4', 'XI-B2', 'XII-A1', 'XII-A2'],
  extracurriculars: ['Masis-KIR', 'Paskibra', 'Pala', 'PMR'],
);

const _studentProfile = AppUser(
  uid: 's1',
  role: UserRole.siswa,
  name: 'Bima Saputra',
  email: 'bima.saputra@gmail.com',
  classId: 'XII-A1',
  extracurriculars: ['Masis-KIR'],
);

const _student = Session(
  uid: 's1',
  role: UserRole.siswa,
  schoolId: 'sman1sukodadi',
  profile: _studentProfile,
  hasGoogle: true,
);

const _teacher = Session(
  uid: 'g1',
  role: UserRole.guru,
  schoolId: 'sman1sukodadi',
  profile: AppUser(
    uid: 'g1',
    role: UserRole.guru,
    name: 'Sugito, S.T., M.Pd.',
    email: 'sugito@sekolah.test',
    extracurriculars: ['Masis-KIR'],
  ),
);

const _program = Program(
  id: 'p1',
  studentId: 's1',
  classId: 'XII-A1',
  book: Book(title: 'Laskar Pelangi', author: 'Andrea Hirata', totalPages: 300),
  startDate: '2026-10-01',
  targetDate: '2026-10-31',
  currentPage: 186,
  journalCount: 11,
  lastJournalDate: '2026-10-15',
  streakCurrent: 5,
  streakBest: 7,
);

final _finished = Program(
  id: 'p0',
  studentId: 's1',
  book: Book(
    title: 'Bumi Manusia',
    author: 'Pramoedya A. Toer',
    totalPages: 240,
  ),
  startDate: '2026-09-01',
  targetDate: '2026-09-30',
  status: ProgramStatus.completed,
  completedAt: DateTime.utc(2026, 9, 26, 5),
  currentPage: 240,
  journalCount: 22,
);

const _summary = ActiveProgramSummary(
  programId: 'p1',
  title: 'Laskar Pelangi',
  author: 'Andrea Hirata',
  totalPages: 300,
  currentPage: 186,
  percent: 62,
  startDate: '2026-10-01',
  targetDate: '2026-11-30',
  extended: true,
);

const _myStats = StudentStats(
  studentId: 's1',
  name: 'Bima Saputra',
  email: 'bima.saputra@gmail.com',
  classId: 'XII-A1',
  extracurriculars: ['Masis-KIR'],
  status: StudentStatus.aktif,
  activeProgram: _summary,
  streakCurrent: 5,
  streakBest: 7,
  lastJournalDate: '2026-10-15',
  journalCountMonth: 11,
  journalCountTotal: 33,
  booksCompleted: 1,
  recentDates: ['2026-10-15', '2026-10-14', '2026-10-13'],
);

const _students = [
  _myStats,
  StudentStats(
    studentId: 's2',
    name: 'Nadia Putri Lestari',
    email: 'nadia.putri@gmail.com',
    classId: 'XII-A2',
    extracurriculars: ['Masis-KIR', 'PMR'],
    status: StudentStatus.perluPerhatian,
    daysSinceLastJournal: 5,
    activeProgram: ActiveProgramSummary(
      programId: 'p2',
      title: 'Negeri 5 Menara',
      author: 'Ahmad Fuadi',
      totalPages: 416,
      currentPage: 120,
      percent: 28,
      startDate: '2026-10-02',
      targetDate: '2026-10-31',
    ),
  ),
  StudentStats(
    studentId: 's3',
    name: 'Fajar Ramadhan',
    email: 'nadia.lestari@gmail.com',
    classId: 'X-D',
    extracurriculars: ['Masis-KIR'],
    status: StudentStatus.tidakAktif,
    daysSinceLastJournal: 9,
  ),
  StudentStats(
    studentId: 's4',
    name: 'Salsabila Azzahra',
    email: 'salsabila@gmail.com',
    classId: 'X-G',
    status: StudentStatus.belumMulai,
  ),
];

const _pending = [
  Member(
    email: 'rizky.maulana@gmail.com',
    schoolId: 'sman1sukodadi',
    role: UserRole.siswa,
    name: 'Rizky Maulana',
    classId: 'XII-A1',
    extracurriculars: ['Masis-KIR'],
  ),
];

const _journals = [
  Journal(
    programId: 'p1',
    date: '2026-10-15',
    studentId: 's1',
    pageStart: 170,
    pageEnd: 186,
    durationRange: DurationRange.m30to60,
    keyInformation:
        'Ikal mulai menyadari bahwa pendidikan adalah jalan untuk mengubah '
        'hidupnya dan hidup teman-temannya di Belitong.',
    reflection: 'Perjuangan Bu Mus sangat menginspirasi.',
    question: 'Mengapa Lintang tetap bersekolah walau rumahnya jauh?',
    hasUnreadTeacherComment: true,
  ),
  Journal(
    programId: 'p1',
    date: '2026-10-14',
    studentId: 's1',
    pageStart: 150,
    pageEnd: 169,
    durationRange: DurationRange.m15to30,
    keyInformation:
        'Laskar Pelangi menang lomba karnaval berkat ide Mahar yang unik.',
    pendingSync: true,
  ),
];

final _comments = [
  JournalComment(
    id: 'c1',
    teacherId: 'g1',
    teacherName: 'Sugito, S.T., M.Pd.',
    text: 'Ringkasanmu jelas. Coba tuliskan juga pendapatmu tentang Lintang.',
    createdAt: DateTime(2026, 10, 15, 19, 30),
  ),
];

// Relative to now, so the cards always read "2 jam lalu", "5 jam lalu".
final _reportsNow = DateTime.now();

final _reports = [
  Report(
    id: 'r1',
    kind: ReportKind.journal,
    reason: ReportReason.harassment,
    target: const ReportTarget.journal(programId: 'p2', date: '2026-10-11'),
    note: 'Ada kalimat yang mengejek teman sekelas.',
    reporterName: 'Khoirul Anam, S.Kom.',
    reporterRole: UserRole.guru,
    subjectId: 's2',
    snapshot: const {
      'studentName': 'Nadia Putri Lestari',
      'date': '2026-10-11',
      'keyInformation':
          'Alif dan teman-temannya di Pondok Madani berjanji menjadi orang '
          'besar.',
    },
    createdAt: _reportsNow.subtract(const Duration(hours: 2)),
  ),
  Report(
    id: 'r2',
    kind: ReportKind.book,
    reason: ReportReason.wrongData,
    target: const ReportTarget.book('b1'),
    note: 'Jumlah halamannya 529, bukan 534.',
    reporterName: 'Bima Saputra',
    reporterRole: UserRole.siswa,
    snapshot: const {
      'title': 'Laskar Pelangi',
      'authors': ['Andrea Hirata'],
    },
    createdAt: _reportsNow.subtract(const Duration(hours: 5)),
  ),
  Report(
    id: 'r3',
    kind: ReportKind.user,
    reason: ReportReason.inappropriate,
    target: const ReportTarget.user('s3'),
    resolved: true,
    reporterName: 'Sugito, S.T., M.Pd.',
    reporterRole: UserRole.guru,
    subjectId: 's3',
    snapshot: const {'name': 'Fajar Ramadhan', 'role': 'siswa'},
    createdAt: _reportsNow.subtract(const Duration(days: 3)),
    resolvedAt: _reportsNow.subtract(const Duration(days: 2)),
    resolvedByName: 'Sugito, S.T., M.Pd.',
    resolution: 'Foto profil sudah diganti.',
  ),
];

/// Every family instance the screens below read, with fixed data.
List<Override> _data() => [
  wibClockProvider.overrideWithValue(_clock),
  schoolProvider.overrideWith((_) => Stream.value(_school)),
  activeProgramProvider.overrideWith((_) => Stream.value(_program)),
  myProgramsProvider.overrideWith((_) => Stream.value([_program, _finished])),
  myStatsProvider.overrideWith((_) => Stream.value(_myStats)),
  unreadJournalsProvider('p1')
      .overrideWith((_) => Stream.value([_journals.first])),
  programProvider('p1').overrideWith((_) => Stream.value(_program)),
  programProvider('p0').overrideWith((_) => Stream.value(_finished)),
  journalProvider('p1', _today).overrideWith((_) => Stream.value(null)),
  journalProvider(
    'p1',
    '2026-10-15',
  ).overrideWith((_) => Stream.value(_journals.first)),
  journalsProvider('p1', 5).overrideWith((_) => Stream.value(_journals)),
  journalsProvider('p1', 20).overrideWith((_) => Stream.value(_journals)),
  journalCommentsProvider(
    'p1',
    '2026-10-15',
  ).overrideWith((_) => Stream.value(_comments)),
  teacherStudentsProvider.overrideWith((_) => Stream.value(_students)),
  pendingStudentsProvider.overrideWith((_) => Stream.value(_pending)),
  schoolTeachersProvider.overrideWith(
    (_) => Stream.value([
      _teacher.profile,
      const AppUser(
        uid: 'g2',
        role: UserRole.guru,
        name: 'Khoirul Anam, S.Kom.',
        email: 'khoirul@sekolah.test',
        homeroomClass: 'XII-A1',
      ),
    ]),
  ),
  pendingTeachersProvider.overrideWith(
    (_) => Stream.value([
      const Member(
        email: 'dewi@sekolah.test',
        schoolId: 'sman1',
        role: UserRole.guru,
        name: 'Dewi Lestari, S.Pd.',
        extracurriculars: ['PMR'],
      ),
    ]),
  ),
  studentStatsProvider('s1').overrideWith((_) => Stream.value(_myStats)),
  schoolReportsProvider.overrideWith((_) => Stream.value(_reports)),
  studentProgramsProvider('s1')
      .overrideWith((_) => Stream.value([_program, _finished])),
];

class _Case {
  const _Case(
    this.name,
    this.screen, {
    this.session,
    this.state,
    this.nav,
    this.open,
  });

  final String name;
  final Widget screen;
  final Session? session;
  final AuthState? state;

  /// Bottom navigation labels, to show the shell around a tab.
  final List<String>? nav;

  /// Taps through to what the golden shows, e.g. an open sheet.
  final Future<void> Function(WidgetTester tester)? open;
}

/// The report sheet on the teacher's comment, as a student opens it.
Future<void> _openCommentReport(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('comment-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('comment-report')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('report-reason-harassment')));
  await tester.pumpAndSettle();
}

const _studentTabs = ['Beranda', 'Buku', 'Jurnal', 'Profil'];

/// The icons of the real shells (lib/app/router/app_router.dart).
const _tabIcons = {
  'Beranda': Icons.home_outlined,
  'Buku': Icons.menu_book_outlined,
  'Jurnal': Icons.edit_note_outlined,
  'Profil': Icons.person_outline,
  'Dashboard': Icons.dashboard_outlined,
  'Siswa': Icons.groups_outlined,
  'Sekolah': Icons.school_outlined,
};
const _teacherTabs = ['Dashboard', 'Siswa', 'Buku', 'Sekolah', 'Profil'];

final _cases = [
  const _Case('login', LoginScreen(), state: AuthSignedOut()),
  _Case(
    'terms',
    const TermsScreen(),
    session: _student.copyWith(
      profile: _studentProfile.copyWith(termsVersion: 0),
    ),
  ),
  const _Case('register', RegisterScreen(), state: AuthSignedOut()),
  _Case(
    'complete_profile',
    const CompleteProfileScreen(),
    session: _student.copyWith(
      hasPassword: false,
      profile: _studentProfile.copyWith(classId: null),
    ),
  ),
  const _Case(
    'student_home',
    StudentHomeScreen(),
    session: _student,
    nav: _studentTabs,
  ),
  const _Case('student_book', BookScreen(), session: _student),
  const _Case('journal_form', JournalFormScreen(), session: _student),
  const _Case('journal_history', JournalHistoryTab(), session: _student),
  const _Case(
    'journal_detail',
    StudentJournalDetailScreen(programId: 'p1', date: '2026-10-15'),
    session: _student,
  ),
  const _Case(
    'report_sheet',
    StudentJournalDetailScreen(programId: 'p1', date: '2026-10-15'),
    session: _student,
    open: _openCommentReport,
  ),
  const _Case('student_profile', StudentProfileScreen(), session: _student),
  const _Case(
    'teacher_dashboard',
    TeacherDashboardScreen(),
    session: _teacher,
    nav: _teacherTabs,
  ),
  const _Case(
    'teacher_active_books',
    TeacherActiveBooksScreen(),
    session: _teacher,
  ),
  const _Case(
    'teacher_month_journals',
    TeacherMonthJournalsScreen(),
    session: _teacher,
  ),
  const _Case('teacher_students', TeacherStudentsScreen(), session: _teacher),
  const _Case(
    'teacher_student_detail',
    TeacherStudentDetailScreen(studentId: 's1'),
    session: _teacher,
  ),
  const _Case(
    'teacher_journal_detail',
    TeacherJournalDetailScreen(programId: 'p1', date: '2026-10-15'),
    session: _teacher,
  ),
  const _Case('school', SchoolScreen(), session: _teacher),
  const _Case('reports', ReportsScreen(), session: _teacher),
  const _Case('add_students', AddStudentsScreen(), session: _teacher),
  const _Case('add_teacher', AddTeacherScreen(), session: _teacher),
  const _Case('teacher_profile', TeacherProfileScreen(), session: _teacher),
];

/// Loads every font of the app's FontManifest (Poppins and the Material
/// icons), so goldens show real text instead of boxes.
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
    registerFallbackValue(_student);
    await _loadFonts();
    await initializeDateFormatting('id_ID');
  });

  for (final mode in ['light', 'dark']) {
    for (final item in _cases) {
      testWidgets('${item.name} ($mode)', skip: !Platform.isMacOS, (
        tester,
      ) async {
        // Real shadows instead of the test framework's solid outlines. The
        // flag must be back to its default before the test ends.
        debugDisableShadows = false;
        try {
          await _pumpCase(tester, item, dark: mode == 'dark');
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${item.name}_$mode.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
}

Future<void> _pumpCase(
  WidgetTester tester,
  _Case item, {
  required bool dark,
}) async {
  // The stored choice matches the rendered theme, so the "Tema" row agrees.
  SharedPreferences.setMockInitialValues({
    'ui.theme': dark ? 'gelap' : 'terang',
  });
  final prefs = await SharedPreferences.getInstance();
  final auth = _MockAuthRepository();
  when(() => auth.signOut()).thenAnswer((_) async {});
  final notifications = _MockNotifications();
  when(() => notifications.shouldExplainPermission(any()))
      .thenAnswer((_) async => false);
  when(() => notifications.isPermissionGranted()).thenAnswer((_) async => true);

  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  Widget screen = item.screen;
  if (item.nav != null) {
    screen = Scaffold(
      body: screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          for (final (index, label) in item.nav!.indexed)
            NavigationDestination(
              icon: Icon(_tabIcons[label] ?? Icons.circle_outlined),
              selectedIcon: index == 0
                  ? const Icon(Icons.home)
                  : Icon(_tabIcons[label] ?? Icons.circle_outlined),
              label: label,
            ),
        ],
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        notificationServiceProvider.overrideWithValue(notifications),
        reportRepositoryProvider.overrideWithValue(_MockReportRepository()),
        authStateProvider.overrideWithValue(
          AsyncData(
            item.state ??
                (item.session == null
                    ? const AuthSignedOut()
                    : AuthSignedIn(item.session!)),
          ),
        ),
        if (item.session != null)
          currentSessionProvider.overrideWithValue(item.session!),
        ..._data(),
      ],
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
  await item.open?.call(tester);
}
