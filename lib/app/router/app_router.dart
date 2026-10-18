import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/widgets/brand.dart';
import '../../core/widgets/role_shell.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/session.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/terms_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/books/presentation/book_explore_screen.dart';
import '../../features/books/presentation/catalog_book_screen.dart';
import '../../features/books/presentation/teacher/book_editor_screen.dart';
import '../../features/books/presentation/teacher/deleted_books_screen.dart';
import '../../features/books/presentation/teacher/suggestions_screen.dart';
import '../../features/books/presentation/teacher/teacher_book_screen.dart';
import '../../features/books/presentation/teacher/teacher_books_screen.dart';
import '../../features/student/presentation/book_screen.dart';
import '../../features/student/presentation/journal_detail_screen.dart';
import '../../features/student/presentation/journal_form_screen.dart';
import '../../features/student/presentation/journal_history_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/student_profile_screen.dart';
import '../../features/teacher/presentation/add_students_screen.dart';
import '../../features/teacher/presentation/add_teacher_screen.dart';
import '../../features/teacher/presentation/import_students_screen.dart';
import '../../features/teacher/presentation/pending_member_screen.dart';
import '../../features/teacher/presentation/reports_screen.dart';
import '../../features/teacher/presentation/school_screen.dart';
import '../../features/teacher/presentation/school_settings_screen.dart';
import '../../features/teacher/presentation/teacher_active_books_screen.dart';
import '../../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../../features/teacher/presentation/teacher_journal_detail_screen.dart';
import '../../features/teacher/presentation/teacher_month_journals_screen.dart';
import '../../features/teacher/presentation/teacher_profile_screen.dart';
import '../../features/teacher/presentation/teacher_student_detail_screen.dart';
import '../../features/teacher/presentation/teacher_students_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

const _studentTabs = <ShellTab>[
  (label: 'Beranda', icon: Icons.home_outlined, selectedIcon: Icons.home),
  (
    label: 'Buku',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
  (
    label: 'Jurnal',
    icon: Icons.edit_note_outlined,
    selectedIcon: Icons.edit_note,
  ),
  (label: 'Profil', icon: Icons.person_outline, selectedIcon: Icons.person),
];

const _teacherTabs = <ShellTab>[
  (
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  (label: 'Siswa', icon: Icons.groups_outlined, selectedIcon: Icons.groups),
  (
    label: 'Buku',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
  (label: 'Sekolah', icon: Icons.school_outlined, selectedIcon: Icons.school),
  (label: 'Profil', icon: Icons.person_outline, selectedIcon: Icons.person),
];

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final auth = ValueNotifier<AuthState>(const AuthLoading());
  ref.listen(authStateProvider, (_, next) {
    auth.value = next.hasError
        ? const AuthSignedOut()
        : next.value ?? const AuthLoading();
  }, fireImmediately: true);
  ref.onDispose(auth.dispose);

  StatefulShellBranch tab(String path, Widget screen) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => screen)],
  );

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (_, state) => redirectFor(auth.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const BrandSplash()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(path: Routes.terms, builder: (_, _) => const TermsScreen()),
      GoRoute(
        path: Routes.completeProfile,
        builder: (_, _) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => const ChangePasswordScreen(),
      ),

      // ---------- Siswa ----------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            RoleShell(navigationShell: shell, tabs: _studentTabs),
        branches: [
          tab(Routes.studentHome, const StudentHomeScreen()),
          tab(Routes.studentBook, const BookScreen()),
          tab(Routes.studentJournals, const JournalHistoryTab()),
          tab(Routes.studentProfile, const StudentProfileScreen()),
        ],
      ),
      GoRoute(
        path: Routes.studentWriteJournal,
        builder: (_, state) =>
            JournalFormScreen(initialDate: state.uri.queryParameters['date']),
      ),
      GoRoute(
        path: '/siswa/jurnal/:programId/:date',
        builder: (_, state) => StudentJournalDetailScreen(
          programId: state.pathParameters['programId']!,
          date: state.pathParameters['date']!,
        ),
      ),
      GoRoute(
        path: '/siswa/profil/buku/:programId',
        builder: (_, state) => ProgramJournalsScreen(
          programId: state.pathParameters['programId']!,
        ),
      ),
      GoRoute(
        path: Routes.studentExplore,
        builder: (_, _) => const BookExploreScreen(),
      ),
      GoRoute(
        path: '/siswa/buku/katalog/:bookId',
        builder: (_, state) =>
            CatalogBookScreen(bookId: state.pathParameters['bookId']!),
      ),

      // ---------- Guru ----------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            RoleShell(navigationShell: shell, tabs: _teacherTabs),
        branches: [
          tab(Routes.teacherDashboard, const TeacherDashboardScreen()),
          tab(Routes.teacherStudents, const TeacherStudentsScreen()),
          tab(Routes.teacherBooks, const TeacherBooksScreen()),
          tab(Routes.teacherSchool, const SchoolScreen()),
          tab(Routes.teacherProfile, const TeacherProfileScreen()),
        ],
      ),
      GoRoute(
        path: Routes.teacherActiveBooks,
        builder: (_, _) => const TeacherActiveBooksScreen(),
      ),
      GoRoute(
        path: Routes.teacherMonthJournals,
        builder: (_, _) => const TeacherMonthJournalsScreen(),
      ),
      // Before '/guru/siswa/:studentId', which would match them too.
      GoRoute(
        path: Routes.teacherAddStudents,
        builder: (_, _) => const AddStudentsScreen(),
      ),
      GoRoute(
        path: Routes.teacherImportStudents,
        builder: (_, _) => const ImportStudentsScreen(),
      ),
      GoRoute(
        path: Routes.teacherSettings,
        builder: (_, _) => const SchoolSettingsScreen(),
      ),
      GoRoute(
        path: Routes.teacherReports,
        builder: (_, _) => const ReportsScreen(),
      ),
      GoRoute(
        path: Routes.teacherAddTeacher,
        builder: (_, _) => const AddTeacherScreen(),
      ),
      GoRoute(
        path: '/guru/anggota/:email',
        builder: (_, state) => PendingMemberScreen(
          email: Uri.decodeComponent(state.pathParameters['email']!),
        ),
      ),
      GoRoute(
        path: '/guru/siswa/:studentId',
        builder: (_, state) => TeacherStudentDetailScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/guru/siswa/:studentId/buku/:programId',
        builder: (_, state) => TeacherProgramJournalsScreen(
          studentId: state.pathParameters['studentId']!,
          programId: state.pathParameters['programId']!,
        ),
      ),
      // Catalog: the static paths before '/guru/buku/:bookId'.
      GoRoute(
        path: Routes.teacherAddBook,
        builder: (_, state) =>
            BookEditorScreen(seed: state.extra as BookEditorSeed?),
      ),
      GoRoute(
        path: Routes.teacherSuggestions,
        builder: (_, _) => const SuggestionsScreen(),
      ),
      GoRoute(
        path: Routes.teacherDeletedBooks,
        builder: (_, _) => const DeletedBooksScreen(),
      ),
      GoRoute(
        path: '/guru/buku/saran/:id',
        builder: (_, state) =>
            SuggestionReviewScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/guru/buku/:bookId',
        builder: (_, state) =>
            TeacherBookScreen(bookId: state.pathParameters['bookId']!),
      ),
      GoRoute(
        path: '/guru/buku/:bookId/ubah',
        builder: (_, state) =>
            BookEditorScreen(bookId: state.pathParameters['bookId']!),
      ),
      GoRoute(
        path: '/guru/siswa/:studentId/buku/:programId/jurnal/:date',
        builder: (_, state) => TeacherJournalDetailScreen(
          programId: state.pathParameters['programId']!,
          date: state.pathParameters['date']!,
        ),
      ),
    ],
  );
}
