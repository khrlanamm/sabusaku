import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AppErrorCode {
  network,
  sessionExpired,
  permissionDenied,
  invalidCredentials,
  accountDisabled,
  wrongPassword,
  weakPassword,
  tooManyRequests,
  alreadyExists,
  notFound,
  invalidInput,
  unknown,
}

/// One exception type for the whole app, carrying a code the UI can map to a
/// friendly Indonesian message.
class AppException implements Exception {
  const AppException(this.code, {this.message, this.cause});

  final AppErrorCode code;

  /// Overrides the default message, e.g. a reason returned by a callable.
  final String? message;
  final Object? cause;

  String get userMessage => message ?? _defaultMessages[code]!;

  @override
  String toString() => 'AppException(${code.name}, $userMessage)';
}

const _defaultMessages = <AppErrorCode, String>{
  AppErrorCode.network:
      'Tidak ada sinyal. Periksa koneksi internet lalu coba lagi.',
  AppErrorCode.sessionExpired: 'Sesi berakhir. Silakan masuk kembali.',
  AppErrorCode.permissionDenied: 'Akses ditolak.',
  AppErrorCode.invalidCredentials: 'Email atau password salah.',
  AppErrorCode.accountDisabled:
      'Akun dinonaktifkan. Hubungi penanggung jawab sekolah.',
  AppErrorCode.wrongPassword: 'Password saat ini salah.',
  AppErrorCode.weakPassword:
      'Password harus minimal 8 karakter, berisi huruf besar dan kecil, '
      'angka, dan karakter khusus.',
  AppErrorCode.tooManyRequests:
      'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
  AppErrorCode.alreadyExists: 'Data sudah ada.',
  AppErrorCode.notFound: 'Data tidak ditemukan.',
  AppErrorCode.invalidInput: 'Data yang diisi belum sesuai.',
  AppErrorCode.unknown: 'Terjadi kesalahan. Coba lagi.',
};

/// Maps any thrown object to an [AppException].
AppException mapError(Object error) {
  if (error is AppException) return error;

  if (error is FirebaseAuthException) {
    final message = switch (error.code) {
      'email-already-in-use' =>
        'Email ini sudah punya akun. Silakan masuk, atau pakai Lupa password.',
      'credential-already-in-use' =>
        'Akun Google ini sudah terhubung ke akun lain.',
      'provider-already-linked' => 'Akun ini sudah punya password.',
      _ => null,
    };
    return AppException(
      switch (error.code) {
        'network-request-failed' => AppErrorCode.network,
        'too-many-requests' => AppErrorCode.tooManyRequests,
        'weak-password' ||
        'password-does-not-meet-requirements' => AppErrorCode.weakPassword,
        'user-disabled' => AppErrorCode.accountDisabled,
        'user-token-expired' ||
        'requires-recent-login' => AppErrorCode.sessionExpired,
        'email-already-in-use' ||
        'credential-already-in-use' ||
        'provider-already-linked' => AppErrorCode.alreadyExists,
        // Kept uniform so the screen never reveals which accounts exist.
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' => AppErrorCode.invalidCredentials,
        _ => AppErrorCode.unknown,
      },
      message: message,
      cause: error,
    );
  }

  if (error is FirebaseFunctionsException) {
    final code = switch (error.code) {
      'unavailable' || 'deadline-exceeded' => AppErrorCode.network,
      'unauthenticated' => AppErrorCode.sessionExpired,
      'permission-denied' => AppErrorCode.permissionDenied,
      'already-exists' => AppErrorCode.alreadyExists,
      'not-found' => AppErrorCode.notFound,
      'invalid-argument' ||
      'failed-precondition' ||
      'out-of-range' => AppErrorCode.invalidInput,
      'resource-exhausted' => AppErrorCode.tooManyRequests,
      _ => AppErrorCode.unknown,
    };
    // Callables return Indonesian messages meant for the user, except for
    // transport and internal failures.
    final passMessage =
        code != AppErrorCode.network && code != AppErrorCode.unknown;
    return AppException(
      code,
      message: passMessage ? error.message : null,
      cause: error,
    );
  }

  if (error is FirebaseException) {
    return AppException(switch (error.code) {
      'unavailable' || 'deadline-exceeded' => AppErrorCode.network,
      'unauthenticated' => AppErrorCode.sessionExpired,
      'permission-denied' => AppErrorCode.permissionDenied,
      'already-exists' => AppErrorCode.alreadyExists,
      'not-found' => AppErrorCode.notFound,
      _ => AppErrorCode.unknown,
    }, cause: error);
  }

  return AppException(AppErrorCode.unknown, cause: error);
}
