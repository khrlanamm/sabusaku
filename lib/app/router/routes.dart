import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/session.dart';

/// Route paths. Each role lives under its own prefix so the redirect can keep
/// users inside their shell.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/daftar';
  static const verifyEmail = '/verifikasi-email';
  static const terms = '/ketentuan';
  static const completeProfile = '/lengkapi-akun';
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
  static const studentExplore = '/siswa/buku/jelajahi';
  static String studentCatalogBook(String bookId) =>
      '/siswa/buku/katalog/$bookId';

  // Guru (penanggung jawab)
  static const teacherDashboard = '/guru/dashboard';
  static const teacherActiveBooks = '/guru/dashboard/buku-aktif';
  static const teacherMonthJournals = '/guru/dashboard/jurnal';
  static const teacherStudents = '/guru/siswa';
  static const teacherSchool = '/guru/sekolah';
  static const teacherProfile = '/guru/profil';
  static const teacherAddStudents = '/guru/siswa/tambah';
  static const teacherImportStudents = '/guru/siswa/impor';
  static const teacherSettings = '/guru/sekolah/pengaturan';
  static const teacherReports = '/guru/sekolah/laporan';
  static const teacherAddTeacher = '/guru/sekolah/tambah-pj';

  // Guru: katalog buku (shared by every school)
  static const teacherBooks = '/guru/buku';
  static const teacherAddBook = '/guru/buku/tambah';
  static const teacherSuggestions = '/guru/buku/saran';
  static const teacherDeletedBooks = '/guru/buku/terhapus';
  static String teacherBook(String bookId) => '/guru/buku/$bookId';
  static String teacherEditBook(String bookId) => '/guru/buku/$bookId/ubah';
  static String teacherSuggestion(String id) => '/guru/buku/saran/$id';
  static String teacherStudent(String studentId) => '/guru/siswa/$studentId';
  static String teacherPendingMember(String email) =>
      '/guru/anggota/${Uri.encodeComponent(email)}';
  static String teacherProgram(String studentId, String programId) =>
      '/guru/siswa/$studentId/buku/$programId';
  static String teacherJournal(
    String studentId,
    String programId,
    String date,
  ) => '/guru/siswa/$studentId/buku/$programId/jurnal/$date';

  static String prefixOf(UserRole role) => switch (role) {
    UserRole.siswa => '/siswa',
    UserRole.guru => '/guru',
  };

  static String homeOf(UserRole role) => switch (role) {
    UserRole.siswa => studentHome,
    UserRole.guru => teacherDashboard,
  };
}

/// Where the user must go instead of [location], or null to stay.
///
/// One gate for sign-in state, email verification, the terms of use, profile
/// completion and role separation (docs/05 §3).
String? redirectFor(AuthState auth, String location) {
  switch (auth) {
    case AuthLoading():
      return location == Routes.splash ? null : Routes.splash;
    // The login screen shows the "not registered" dialog, then signs out.
    case AuthSignedOut() || AuthNotRegistered():
      if (location == Routes.login || location == Routes.register) return null;
      return Routes.login;
    case AuthNeedsVerification():
      return location == Routes.verifyEmail ? null : Routes.verifyEmail;
    case AuthSignedIn(:final session):
      if (session.needsTerms) {
        return location == Routes.terms ? null : Routes.terms;
      }
      if (session.needsCompletion) {
        return location == Routes.completeProfile
            ? null
            : Routes.completeProfile;
      }
      if (location == Routes.changePassword) return null;
      if (location.startsWith('${Routes.prefixOf(session.role)}/')) return null;
      return Routes.homeOf(session.role);
  }
}
