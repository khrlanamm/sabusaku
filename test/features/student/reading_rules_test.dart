import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/features/student/domain/reading_rules.dart';

void main() {
  group('journalDateChoices (BR-3)', () {
    test('offers today and the two days before, newest first', () {
      expect(
        journalDateChoices(today: '2026-10-07', programStartDate: '2026-10-01'),
        ['2026-10-07', '2026-10-06', '2026-10-05'],
      );
    });

    test('never offers a date before the book was started', () {
      expect(
        journalDateChoices(today: '2026-10-07', programStartDate: '2026-10-06'),
        ['2026-10-07', '2026-10-06'],
      );
      expect(
        journalDateChoices(today: '2026-10-07', programStartDate: '2026-10-07'),
        ['2026-10-07'],
      );
    });

    test('crosses month boundaries', () {
      expect(
        journalDateChoices(today: '2026-11-01', programStartDate: '2026-10-01'),
        ['2026-11-01', '2026-10-31', '2026-10-30'],
      );
    });
  });

  group('canEditJournal (BR-4)', () {
    test('editable on its date and the day after, then locked', () {
      expect(
        canEditJournal(journalDate: '2026-10-07', today: '2026-10-07'),
        isTrue,
      );
      expect(
        canEditJournal(journalDate: '2026-10-06', today: '2026-10-07'),
        isTrue,
      );
      expect(
        canEditJournal(journalDate: '2026-10-05', today: '2026-10-07'),
        isFalse,
      );
    });
  });

  group('pages (BR-5)', () {
    test('the start page continues after the last page read', () {
      expect(defaultPageStart(currentPage: 0, totalPages: 300), 1);
      expect(defaultPageStart(currentPage: 230, totalPages: 300), 231);
      expect(defaultPageStart(currentPage: 300, totalPages: 300), 300);
    });

    test('start must be a number from 1', () {
      expect(validatePageStart(''), isNotNull);
      expect(validatePageStart('0'), isNotNull);
      expect(validatePageStart('abc'), isNotNull);
      expect(validatePageStart(' 12 '), isNull);
    });

    test('end must be between start and the last page of the book', () {
      String? check(String end, {String start = '10'}) =>
          validatePageEnd(end, pageStartInput: start, totalPages: 300);
      expect(check('10'), isNull);
      expect(check('300'), isNull);
      expect(check('9'), contains('halaman awal'));
      expect(check('301'), contains('300'));
      expect(check(''), isNotNull);
    });
  });

  group('text (BR-7)', () {
    test('key information needs 30 to 1000 characters after trimming', () {
      expect(validateKeyInformation('x' * 29), contains('kurang 1'));
      expect(validateKeyInformation('  ${'x' * 29}  '), isNotNull);
      expect(validateKeyInformation('x' * 30), isNull);
      expect(validateKeyInformation('x' * 1000), isNull);
      expect(validateKeyInformation('x' * 1001), isNotNull);
      expect(validateKeyInformation(null), isNotNull);
    });

    test('optional fields may be empty but not over 1000', () {
      expect(validateOptionalText(''), isNull);
      expect(validateOptionalText(null), isNull);
      expect(validateOptionalText('x' * 1001), isNotNull);
    });
  });

  group('book (BR-8, BR-9)', () {
    test('title, author and page count limits', () {
      expect(validateBookTitle('L'), isNotNull);
      expect(validateBookTitle('Laskar Pelangi'), isNull);
      expect(validateBookTitle('x' * 121), isNotNull);
      expect(validateBookAuthor('A'), isNotNull);
      expect(validateBookAuthor('Andrea Hirata'), isNull);
      expect(validateTotalPages('9'), isNotNull);
      expect(validateTotalPages('10'), isNull);
      expect(validateTotalPages('2000'), isNull);
      expect(validateTotalPages('2001'), isNotNull);
      expect(validateTotalPages(''), isNotNull);
      expect(validateIsbn(''), isNull);
      expect(validateIsbn('9' * 21), isNotNull);
    });

    test('the default target is the end of the month', () {
      expect(defaultTargetDate('2026-10-07'), '2026-10-31');
      expect(defaultTargetDate('2026-02-10'), '2026-02-28');
    });

    test('an extension runs to the end of the next month, 31 days at most', () {
      expect(extendedTargetDate('2026-10-31'), '2026-11-30');
      expect(extendedTargetDate('2026-11-30'), '2026-12-31');
      expect(extendedTargetDate('2026-12-31'), '2027-01-31');
      expect(extendedTargetDate('2026-01-31'), '2026-02-28');
      // A mid-month target would otherwise jump more than the rules allow.
      expect(extendedTargetDate('2026-10-15'), '2026-11-15');
    });

    test('reading days count both the start and the end date', () {
      expect(readingDays(startDate: '2026-10-01', endDate: '2026-10-01'), 1);
      expect(readingDays(startDate: '2026-10-01', endDate: '2026-10-12'), 12);
      expect(readingDays(startDate: '2026-10-25', endDate: '2026-12-05'), 42);
    });
  });
}
