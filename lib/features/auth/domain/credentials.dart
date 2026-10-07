/// Sign-in identity rules. Must stay in sync with
/// functions/src/domain/identity.ts and functions/src/config.ts.
library;

/// `.invalid` can never receive mail, so no password-reset email can ever
/// reach anyone (docs/07 §0).
const emailDomain = 'sabusaku.invalid';

final _usernamePattern = RegExp(r'^[a-z0-9]+(?:[._-][a-z0-9]+)*$');
final _schoolCodePattern = RegExp(r'^[a-z0-9]{3,20}$');

const minPasswordLength = 8;

String normalizeIdentity(String raw) => raw.trim().toLowerCase();

bool isValidUsername(String username) =>
    username.length >= 3 &&
    username.length <= 30 &&
    _usernamePattern.hasMatch(username);

bool isValidSchoolCode(String code) => _schoolCodePattern.hasMatch(code);

/// Firebase Auth is email based; users sign in with a username or NIS.
String pseudoEmail(String schoolCode, String username) =>
    '$username@$schoolCode.$emailDomain';

String? validateNewPassword(String? value) {
  if (value == null || value.length < minPasswordLength) {
    return 'Password minimal $minPasswordLength karakter';
  }
  if (value.length > 64) return 'Password maksimal 64 karakter';
  return null;
}
