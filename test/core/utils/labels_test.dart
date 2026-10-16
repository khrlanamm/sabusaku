import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/utils/labels.dart';

import '../../helpers/sample_password.dart';

void main() {
  test('normalises what people type into class labels', () {
    const cases = {
      '12  A1': 'XII-A1',
      'XIIC2': 'XII-C2',
      'Xll-A1': 'XII-A1',
      'XI A4': 'XI-A4',
      'XD': 'X-D',
      'XII-b2': 'XII-B2',
      ' X-G2 ': 'X-G2',
      '10 F': 'X-F',
      '12C1': 'XII-C1',
      'XI-L1': 'XI-L1',
    };
    cases.forEach((raw, label) {
      expect(normalizeClassLabel(raw), label, reason: raw);
    });
  });

  test('rejects text that is not a class label', () {
    for (final raw in [
      'abc',
      '',
      'XIII-A1',
      'XII-A123',
      'IPA 1',
      'XII',
      'XI',
      'X',
    ]) {
      expect(normalizeClassLabel(raw), isNull, reason: raw);
    }
  });

  test('sorts class labels by grade, then by name', () {
    final labels = ['XII-A1', 'X-G', 'XI-B2', 'X-D', 'XI-A4']
      ..sort(compareClassLabels);
    expect(labels, ['X-D', 'X-G', 'XI-A4', 'XI-B2', 'XII-A1']);
  });

  test('normalises extracurriculars and emails', () {
    expect(normalizeExtracurricular('  Masis   KIR '), 'Masis KIR');
    expect(normalizeExtracurricular('A'), isNull);
    expect(normalizeEmail('  Siswa@Gmail.COM '), 'siswa@gmail.com');
    expect(isValidEmail('siswa@gmail.com'), isTrue);
    expect(isValidEmail('siswa@gmail'), isFalse);
    expect(isValidEmail('bukan email@gmail.com'), isFalse);
  });

  test('a new password needs length, mixed case, a digit and a symbol', () {
    expect(validateNewPassword(samplePassword()), isNull);
    for (final weak in [
      '',
      samplePassword(length: 4),
      samplePassword(upper: false),
      samplePassword(lower: false),
      samplePassword(digit: false),
      samplePassword(symbol: false),
    ]) {
      expect(validateNewPassword(weak), isNotNull, reason: weak);
    }
    final lowerOnly = samplePassword(upper: false, digit: false, symbol: false);
    final unmet = [
      for (final rule in passwordRules)
        if (!rule.isMet(lowerOnly)) rule.label,
    ];
    expect(unmet, hasLength(3));
  });
}
