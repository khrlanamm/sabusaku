import 'package:intl/intl.dart';

import 'date_id.dart';

const _locale = 'id_ID';

/// "Selasa, 6 Oktober 2026"
String formatDateLong(String dateId) =>
    DateFormat('EEEE, d MMMM y', _locale).format(DateId.parse(dateId));

/// "6 Okt 2026"
String formatDateShort(String dateId) =>
    DateFormat('d MMM y', _locale).format(DateId.parse(dateId));

/// "6 Okt"
String formatDayMonth(String dateId) =>
    DateFormat('d MMM', _locale).format(DateId.parse(dateId));

/// "6 Oktober"
String formatDayMonthLong(String dateId) =>
    DateFormat('d MMMM', _locale).format(DateId.parse(dateId));

/// "Oktober 2026" from `yyyy-MM` or `yyyy-MM-dd`.
String formatMonth(String monthOrDateId) {
  final id = monthOrDateId.length == 7 ? '$monthOrDateId-01' : monthOrDateId;
  return DateFormat('MMMM y', _locale).format(DateId.parse(id));
}

/// "Hari ini", "Kemarin", "2 hari lalu", otherwise the short date.
String formatRelativeDay(String dateId, String today) {
  final days = DateId.daysBetween(dateId, today);
  return switch (days) {
    0 => 'Hari ini',
    1 => 'Kemarin',
    2 => '2 hari lalu',
    _ => formatDateShort(dateId),
  };
}
