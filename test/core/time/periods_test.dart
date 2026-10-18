import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sabusaku/core/time/periods.dart';

// The same cases as functions/test/domain/ranking.test.ts, so the app and
// the server agree on every period.
void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('tahun ajaran mulai 1 Juli', () {
    expect(schoolYearOf('2026-06-30'), 2025);
    expect(schoolYearOf('2026-07-01'), 2026);
    expect(schoolYearOf('2027-01-15'), 2026);
    final period = RankPeriod.schoolYear(2026);
    expect(period.id, 'schoolYear-2026');
    expect((period.from, period.to), ('2026-07-01', '2027-06-30'));
    expect(period.label, '2026/2027');
  });

  test('batas bulan dan tahun', () {
    const february = RankPeriod.month('2026-02');
    expect(
      (february.id, february.from, february.to),
      ('month-2026-02', '2026-02-01', '2026-02-28'),
    );
    expect(const RankPeriod.month('2028-02').to, '2028-02-29');
    expect(RankPeriod.year(2026).id, 'year-2026');
    expect(
      (RankPeriod.year(2026).from, RankPeriod.year(2026).to),
      ('2026-01-01', '2026-12-31'),
    );
    expect(const RankPeriod.month('2026-10').label, 'Oktober 2026');
    expect(RankPeriod.all.label, 'Sepanjang waktu');
  });

  test('periode yang memuat satu hari', () {
    expect(
      [
        for (final kind in PeriodKind.values)
          RankPeriod.of(kind, '2026-10-18').id,
      ],
      ['month-2026-10', 'year-2026', 'schoolYear-2026', 'all'],
    );
    expect(
      RankPeriod.of(PeriodKind.schoolYear, '2027-03-02').id,
      'schoolYear-2026',
    );
  });

  test('ID dokumen bolak-balik', () {
    for (final kind in PeriodKind.values) {
      final period = RankPeriod.of(kind, '2027-03-02');
      expect(RankPeriod.fromId(period.id), period);
    }
    expect(RankPeriod.fromId('month-2026-13'), isNull);
    expect(RankPeriod.fromId('week-2026'), isNull);
  });

  test('melangkah maju dan mundur', () {
    expect(
      const RankPeriod.month('2026-01').previous,
      const RankPeriod.month('2025-12'),
    );
    expect(
      const RankPeriod.month('2026-12').next,
      const RankPeriod.month('2027-01'),
    );
    expect(RankPeriod.schoolYear(2026).next, RankPeriod.schoolYear(2027));
    expect(RankPeriod.all.previous, isNull);
    expect(const RankPeriod.month('2026-10').contains('2026-10-31'), isTrue);
    expect(const RankPeriod.month('2026-10').contains('2026-11-01'), isFalse);
    expect(RankPeriod.all.contains('2001-01-01'), isTrue);
  });
}
