import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/session.dart';

/// Route paths. Each role lives under its own prefix so the redirect can keep
/// users inside their shell.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const forceChangePassword = '/ganti-password';
  static const changePassword = '/ubah-password';

  // Siswa
  static const studentHome = '/siswa/beranda';
  static const studentBook = '/siswa/buku';
  static const studentJournals = '/siswa/jurnal';
  static const studentProfile = '/siswa/profil';
  static const studentStartBook = '/siswa/buku/mulai';
  static const studentWriteJournal = '/siswa/tulis-jurnal';
  static String studentJournal(String programId, String date) =>
      '/siswa/jurnal/$programId/$date';
  static String studentProgramJournals(String programId) =>
      '/siswa/profil/buku/$programId';

  // Guru
  static const teacherDashboard = '/guru/dashboard';
  static const teacherStudents = '/guru/siswa';
  static const teacherProfile = '/guru/profil';
  static String teacherStudent(String studentId) => '/guru/siswa/$studentId';
  static String teacherProgram(String studentId, String programId) =>
      '/guru/siswa/$studentId/buku/$programId';
  static String teacherJournal(
    String studentId,
    String programId,
    String date,
  ) => '/guru/siswa/$studentId/buku/$programId/jurnal/$date';

  // Admin
  static const adminHome = '/admin/beranda';
  static const adminClasses = '/admin/kelas';
  static const adminUsers = '/admin/pengguna';
  static const adminSettings = '/admin/pengaturan';
  static String adminClass(String classId) => '/admin/kelas/$classId';
  static const adminAddUser = '/admin/pengguna/tambah';
  static const adminImport = '/admin/pengguna/impor';
  static String adminUser(String uid) => '/admin/pengguna/detail/$uid';

  static String prefixOf(UserRole role) => switch (role) {
    UserRole.siswa => '/siswa',
    UserRole.guru => '/guru',
    UserRole.admin => '/admin',
  };

  static String homeOf(UserRole role) => switch (role) {
    UserRole.siswa => studentHome,
    UserRole.guru => teacherDashboard,
    UserRole.admin => adminHome,
  };
}

/// Where the user must go instead of [location], or null to stay.
///
/// One gate for sign-in state, the forced password change and role
/// separation (docs/05 §3).
String? redirectFor(AuthState auth, String location) {
  switch (auth) {
    case AuthLoading():
      return location == Routes.splash ? null : Routes.splash;
    case AuthSignedOut():
      return location == Routes.login ? null : Routes.login;
    case AuthSignedIn(:final session):
      if (session.mustChangePassword) {
        return location == Routes.forceChangePassword
            ? null
            : Routes.forceChangePassword;
      }
      if (location == Routes.changePassword) return null;
      if (location.startsWith('${Routes.prefixOf(session.role)}/')) return null;
      return Routes.homeOf(session.role);
  }
}
