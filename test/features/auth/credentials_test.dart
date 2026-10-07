import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/features/auth/domain/credentials.dart';

void main() {
  test('usernames allow letters, digits and single separators', () {
    for (final ok in ['12345678', 'budi', 'budi.santoso', 'a-b_c.d', 'abc']) {
      expect(isValidUsername(ok), isTrue, reason: ok);
    }
    for (final bad in [
      'ab',
      'Budi',
      '.budi',
      'budi.',
      'bu..di',
      'budi santoso',
      'budi@x',
      'a' * 31,
    ]) {
      expect(isValidUsername(bad), isFalse, reason: bad);
    }
  });

  test('school codes are 3–20 lowercase letters and digits', () {
    expect(isValidSchoolCode('sman1'), isTrue);
    expect(isValidSchoolCode('sm'), isFalse);
    expect(isValidSchoolCode('sma-n1'), isFalse);
    expect(isValidSchoolCode('SMAN1'), isFalse);
  });

  test('input is trimmed and lowercased before use', () {
    expect(normalizeIdentity('  SMAN1 '), 'sman1');
  });

  test('sign-in email is deterministic and on an unroutable domain', () {
    expect(pseudoEmail('sman1', '12345678'), '12345678@sman1.sabusaku.invalid');
  });

  test('new passwords need at least 8 characters', () {
    expect(validateNewPassword('1234567'), isNotNull);
    expect(validateNewPassword('12345678'), isNull);
    expect(validateNewPassword(null), isNotNull);
  });
}
