import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/time/date_id.dart';
import 'package:sabusaku/core/time/wib_clock.dart';

void main() {
  group('DateId', () {
    test('validates format and real calendar dates', () {
      expect(DateId.isValid('2026-10-07'), isTrue);
      expect(DateId.isValid('2026-02-30'), isFalse);
      expect(DateId.isValid('2026-1-7'), isFalse);
      expect(DateId.isValid('07-10-2026'), isFalse);
    });

    test('adds days across month and year boundaries', () {
      expect(DateId.addDays('2026-10-31', 1), '2026-11-01');
      expect(DateId.addDays('2026-12-31', 1), '2027-01-01');
      expect(DateId.addDays('2026-03-01', -1), '2026-02-28');
      expect(DateId.addDays('2028-03-01', -1), '2028-02-29');
    });

    test('counts whole days between dates', () {
      expect(DateId.daysBetween('2026-10-05', '2026-10-07'), 2);
      expect(DateId.daysBetween('2026-10-07', '2026-10-05'), -2);
      expect(DateId.daysBetween('2026-10-07', '2026-10-07'), 0);
    });

    test('finds month boundaries', () {
      expect(DateId.monthOf('2026-10-07'), '2026-10');
      expect(DateId.endOfMonth('2026-10-07'), '2026-10-31');
      expect(DateId.endOfMonth('2026-02-10'), '2026-02-28');
      expect(DateId.endOfNextMonth('2026-10-07'), '2026-11-30');
      expect(DateId.endOfNextMonth('2026-12-15'), '2027-01-31');
    });
  });

  group('WibClock', () {
    WibClock at(DateTime instant) => WibClock(() => instant);

    test('23:59 WIB is still the same day', () {
      // 16:59 UTC = 23:59 WIB
      expect(at(DateTime.utc(2026, 10, 7, 16, 59)).today(), '2026-10-07');
    });

    test('00:01 WIB is the next day', () {
      // 17:01 UTC = 00:01 WIB the following day
      expect(at(DateTime.utc(2026, 10, 7, 17, 1)).today(), '2026-10-08');
    });

    test('does not depend on the device time zone', () {
      final utc = DateTime.utc(2026, 12, 31, 18);
      expect(WibClock.dateIdOf(utc), '2027-01-01');
      expect(WibClock.dateIdOf(utc.toLocal()), '2027-01-01');
    });
  });
}
