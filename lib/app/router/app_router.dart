import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/widgets/brand.dart';
import '../../core/widgets/role_shell.dart';
import '../../core/widgets/states.dart';
import '../../features/admin/presentation/add_user_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/presentation/class_detail_screen.dart';
import '../../features/admin/presentation/classes_screen.dart';
import '../../features/admin/presentation/import_csv_screen.dart';
import '../../features/admin/presentation/user_detail_screen.dart';
import '../../features/admin/presentation/users_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/session.dart';
import '../../features/auth/presentation/account_section.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/student/presentation/book_screen.dart';
import '../../features/student/presentation/journal_detail_screen.dart';
import '../../features/student/presentation/journal_form_screen.dart';
import '../../features/student/presentation/journal_history_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/student_profile_screen.dart';
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
  (label: 'Profil', icon: Icons.person_outline, selectedIcon: Icons.person),
];

const _adminTabs = <ShellTab>[
  (label: 'Beranda', icon: Icons.home_outlined, selectedIcon: Icons.home),
  (label: 'Kelas', icon: Icons.class_outlined, selectedIcon: Icons.class_),
  (label: 'Pengguna', icon: Icons.groups_outlined, selectedIcon: Icons.groups),
  (
    label: 'Pengaturan',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
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
      GoRoute(
        path: Routes.forceChangePassword,
        builder: (_, _) => const ChangePasswordScreen(forced: true),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => const ChangePasswordScreen(forced: false),
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

      // ---------- Guru ----------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            RoleShell(navigationShell: shell, tabs: _teacherTabs),
        branches: [
          tab(Routes.teacherDashboard, const _Placeholder('Dashboard')),
          tab(Routes.teacherStudents, const _Placeholder('Siswa')),
          tab(Routes.teacherProfile, const _Placeholder('Profil')),
        ],
      ),

      // ---------- Admin ----------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            RoleShell(navigationShell: shell, tabs: _adminTabs),
        branches: [
          tab(Routes.adminHome, const AdminHomeScreen()),
          tab(Routes.adminClasses, const ClassesScreen()),
          tab(Routes.adminUsers, const UsersScreen()),
          tab(Routes.adminSettings, const AdminSettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/admin/kelas/:classId',
        builder: (_, state) =>
            ClassDetailScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: Routes.adminAddUser,
        builder: (_, _) => const AddUserScreen(),
      ),
      GoRoute(
        path: Routes.adminImport,
        builder: (_, _) => const ImportCsvScreen(),
      ),
      GoRoute(
        path: '/admin/pengguna/detail/:uid',
        builder: (_, state) =>
            UserDetailScreen(uid: state.pathParameters['uid']!),
      ),
    ],
  );
}

/// Stand-in for tabs whose feature lands in a later stage.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AccountSection(),
          SizedBox(height: 24),
          EmptyState(
            icon: Icons.construction,
            title: 'Segera hadir',
            message: 'Fitur ini sedang dibangun.',
          ),
        ],
      ),
    );
  }
}
