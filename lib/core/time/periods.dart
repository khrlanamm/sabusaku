import 'package:flutter/foundation.dart';

import 'date_format.dart';
import 'date_id.dart';

enum PeriodKind {
  month('Bulan'),
  year('Tahun'),
  schoolYear('Tahun ajaran'),
  all('Semua');

  const PeriodKind(this.label);

  final String label;
}

/// A school year runs from 1 July to 30 June and is named by its first year.
int schoolYearOf(String dateId) {
  final year = int.parse(dateId.substring(0, 4));
  return int.parse(dateId.substring(5, 7)) >= 7 ? year : year - 1;
}

/// A leaderboard period (docs/02 §3.17). Mirrors
/// functions/src/domain/ranking.ts; the document ID is [id].
@immutable
class RankPeriod {
  const RankPeriod._(this.kind, this.key);

  const RankPeriod.month(String month) : this._(PeriodKind.month, month);
  factory RankPeriod.year(int year) => RankPeriod._(PeriodKind.year, '$year');
  factory RankPeriod.schoolYear(int startYear) =>
      RankPeriod._(PeriodKind.schoolYear, '$startYear');

  static const all = RankPeriod._(PeriodKind.all, null);

  /// No school used the app before this month; the period stepper stops here.
  static const earliestMonth = '2026-07';

  /// The period of [kind] that contains [dateId].
  factory RankPeriod.of(PeriodKind kind, String dateId) => switch (kind) {
    PeriodKind.month => RankPeriod.month(DateId.monthOf(dateId)),
    PeriodKind.year => RankPeriod.year(int.parse(dateId.substring(0, 4))),
    PeriodKind.schoolYear => RankPeriod.schoolYear(schoolYearOf(dateId)),
    PeriodKind.all => all,
  };

  /// The period of a document ID, or null when the ID is not one.
  static RankPeriod? fromId(String id) {
    if (id == 'all') return all;
    final month = RegExp(r'^month-(\d{4}-(0[1-9]|1[0-2]))$').firstMatch(id);
    if (month != null) return RankPeriod.month(month.group(1)!);
    final year = RegExp(r'^(year|schoolYear)-(\d{4})$').firstMatch(id);
    if (year == null) return null;
    final number = int.parse(year.group(2)!);
    return year.group(1) == 'year'
        ? RankPeriod.year(number)
        : RankPeriod.schoolYear(number);
  }

  final PeriodKind kind;

  /// `yyyy-MM` for a month, `yyyy` for a year and a school year (its first
  /// year), null for all time.
  final String? key;

  String get id => switch (kind) {
    PeriodKind.month => 'month-$key',
    PeriodKind.year => 'year-$key',
    PeriodKind.schoolYear => 'schoolYear-$key',
    PeriodKind.all => 'all',
  };

  /// First day, inclusive; null for all time.
  String? get from => switch (kind) {
    PeriodKind.month => '$key-01',
    PeriodKind.year => '$key-01-01',
    PeriodKind.schoolYear => '$key-07-01',
    PeriodKind.all => null,
  };

  /// Last day, inclusive; null for all time.
  String? get to => switch (kind) {
    PeriodKind.month => DateId.endOfMonth('$key-01'),
    PeriodKind.year => '$key-12-31',
    PeriodKind.schoolYear => '${int.parse(key!) + 1}-06-30',
    PeriodKind.all => null,
  };

  /// "Oktober 2026", "2026", "2026/2027", "Sepanjang waktu".
  String get label => switch (kind) {
    PeriodKind.month => formatMonth(key!),
    PeriodKind.year => key!,
    PeriodKind.schoolYear => '$key/${int.parse(key!) + 1}',
    PeriodKind.all => 'Sepanjang waktu',
  };

  bool contains(String dateId) =>
      (from == null || dateId.compareTo(from!) >= 0) &&
      (to == null || dateId.compareTo(to!) <= 0);

  /// The period before this one; null for all time.
  RankPeriod? get previous => _shift(-1);

  /// The period after this one; null for all time.
  RankPeriod? get next => _shift(1);

  RankPeriod? _shift(int step) {
    switch (kind) {
      case PeriodKind.month:
        final date = DateId.parse('$key-01');
        final shifted = DateTime.utc(date.year, date.month + step);
        return RankPeriod.month(DateId.monthOf(DateId.format(shifted)));
      case PeriodKind.year:
        return RankPeriod.year(int.parse(key!) + step);
      case PeriodKind.schoolYear:
        return RankPeriod.schoolYear(int.parse(key!) + step);
      case PeriodKind.all:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RankPeriod && other.kind == kind && other.key == key;

  @override
  int get hashCode => Object.hash(kind, key);

  @override
  String toString() => id;
}
