/// Calendar dates are `yyyy-MM-dd` strings in WIB everywhere (docs/02).
/// These helpers do pure calendar arithmetic and never touch a time zone.
abstract final class DateId {
  static final _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool isValid(String id) {
    if (!_pattern.hasMatch(id)) return false;
    return format(parse(id)) == id;
  }

  /// The date as a UTC midnight, used only as a calendar value.
  static DateTime parse(String id) {
    final parts = id.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String addDays(String id, int days) =>
      format(parse(id).add(Duration(days: days)));

  /// Whole days from [from] to [to]; positive when [to] is later.
  static int daysBetween(String from, String to) =>
      parse(to).difference(parse(from)).inDays;

  /// `yyyy-MM` of the date.
  static String monthOf(String id) => id.substring(0, 7);

  static String endOfMonth(String id) {
    final date = parse(id);
    return format(DateTime.utc(date.year, date.month + 1, 0));
  }

  /// End of the month after the one containing [id].
  static String endOfNextMonth(String id) {
    final date = parse(id);
    return format(DateTime.utc(date.year, date.month + 2, 0));
  }
}
