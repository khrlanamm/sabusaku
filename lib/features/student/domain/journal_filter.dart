import 'package:flutter/foundation.dart';

import '../../../core/models/program.dart';
import '../../../core/time/date_id.dart';

/// Which days the journal history covers.
sealed class JournalRange {
  const JournalRange();

  /// First and last day, inclusive; null for no bound.
  String? get from;
  String? get to;
}

final class AllJournals extends JournalRange {
  const AllJournals();

  @override
  String? get from => null;
  @override
  String? get to => null;

  @override
  bool operator ==(Object other) => other is AllJournals;
  @override
  int get hashCode => (AllJournals).hashCode;
}

final class MonthJournals extends JournalRange {
  const MonthJournals(this.month);

  /// `yyyy-MM`.
  final String month;

  @override
  String get from => '$month-01';
  @override
  String get to => DateId.endOfMonth(from);

  @override
  bool operator ==(Object other) =>
      other is MonthJournals && other.month == month;
  @override
  int get hashCode => Object.hash(MonthJournals, month);
}

final class DateRangeJournals extends JournalRange {
  const DateRangeJournals(this.from, this.to);

  @override
  final String from;
  @override
  final String to;

  @override
  bool operator ==(Object other) =>
      other is DateRangeJournals && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(DateRangeJournals, from, to);
}

/// What the student narrowed "Jurnal" to.
@immutable
class JournalFilter {
  const JournalFilter({
    this.range = const AllJournals(),
    this.programId,
    this.oldestFirst = false,
  });

  final JournalRange range;

  /// One book, or every book when null.
  final String? programId;
  final bool oldestFirst;

  JournalFilter copyWith({
    JournalRange? range,
    String? Function()? programId,
    bool? oldestFirst,
  }) => JournalFilter(
    range: range ?? this.range,
    programId: programId == null ? this.programId : programId(),
    oldestFirst: oldestFirst ?? this.oldestFirst,
  );

  @override
  bool operator ==(Object other) =>
      other is JournalFilter &&
      other.range == range &&
      other.programId == programId &&
      other.oldestFirst == oldestFirst;
  @override
  int get hashCode => Object.hash(range, programId, oldestFirst);
}

/// One month of the journal history, with how many journals it holds when
/// the books' `journalDates` tell (null when a book does not have them yet).
typedef JournalMonth = ({String month, String from, String to, int? count});

/// The months [filter] covers that may hold a journal, in display order.
/// Each month is clipped to the range.
List<JournalMonth> journalMonths(
  List<Program> programs,
  JournalFilter filter,
  String today,
) {
  final books = [
    for (final program in programs)
      if (filter.programId == null || program.id == filter.programId) program,
  ];
  final from = filter.range.from;
  final to = filter.range.to;
  bool inRange(String date) =>
      (from == null || date.compareTo(from) >= 0) &&
      (to == null || date.compareTo(to) <= 0);

  final counts = <String, int>{};
  final unknown = <String>{};
  for (final program in books) {
    final dates = program.journalDates;
    if (dates != null) {
      for (final date in dates.where(inRange)) {
        counts.update(DateId.monthOf(date), (n) => n + 1, ifAbsent: () => 1);
      }
      continue;
    }
    // Not filled in yet: every month the book was being read.
    var month = DateId.monthOf(program.startDate);
    final last = DateId.monthOf(program.endDate(today));
    while (month.compareTo(last) <= 0) {
      final start = '$month-01';
      if ((to == null || start.compareTo(to) <= 0) &&
          (from == null || DateId.endOfMonth(start).compareTo(from) >= 0)) {
        unknown.add(month);
      }
      month = DateId.monthOf(DateId.addDays(DateId.endOfMonth(start), 1));
    }
  }

  final months = {...counts.keys, ...unknown}.toList()..sort();
  return [
    for (final month in filter.oldestFirst ? months : months.reversed)
      (
        month: month,
        from: _later('$month-01', from),
        to: _earlier(DateId.endOfMonth('$month-01'), to),
        count: unknown.contains(month) ? null : counts[month],
      ),
  ];
}

String _later(String a, String? b) => b == null || a.compareTo(b) >= 0 ? a : b;
String _earlier(String a, String? b) =>
    b == null || a.compareTo(b) <= 0 ? a : b;

/// Every journal date of [programs], for the calendar.
Set<String> journalDatesOf(Iterable<Program> programs) => {
  for (final program in programs) ...?program.journalDates,
};
