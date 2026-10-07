import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'date_id.dart';

part 'wib_clock.g.dart';

/// The only place that turns "now" into a WIB calendar date.
///
/// WIB is UTC+7 with no daylight saving, so the conversion is a fixed offset
/// and does not depend on the device time zone.
class WibClock {
  const WibClock([this._now = DateTime.now]);

  final DateTime Function() _now;

  static const _offset = Duration(hours: 7);

  DateTime now() => _now();

  /// Today's date in WIB as `yyyy-MM-dd`.
  String today() => dateIdOf(_now());

  static String dateIdOf(DateTime instant) =>
      DateId.format(instant.toUtc().add(_offset));
}

@Riverpod(keepAlive: true)
WibClock wibClock(Ref ref) => const WibClock();
