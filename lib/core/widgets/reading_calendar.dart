import 'package:flutter/material.dart';

import '../models/school.dart';
import '../time/date_id.dart';

const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// One month of reading: days with a journal are filled, today is outlined,
/// and neutral weekdays and school holidays (which never break a streak) are
/// dimmed. Weeks start on Monday.
class ReadingCalendar extends StatelessWidget {
  const ReadingCalendar({
    super.key,
    required this.month,
    required this.journalDates,
    required this.today,
    this.settings = const SchoolSettings(),
    this.onTapDay,
  });

  /// `yyyy-MM`.
  final String month;
  final Set<String> journalDates;
  final String today;
  final SchoolSettings settings;

  /// Called with the date of a tapped day that has a journal.
  final ValueChanged<String>? onTapDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = DateId.parse('$month-01');
    final days = DateId.parse(DateId.endOfMonth('$month-01')).day;
    // DateTime.weekday: Monday = 1 … Sunday = 7.
    final leading = first.weekday - 1;
    final cells = leading + days;
    final rows = (cells / 7).ceil();

    Widget cell(int index) {
      final day = index - leading + 1;
      if (day < 1 || day > days) return const SizedBox.shrink();
      final date = '$month-${day.toString().padLeft(2, '0')}';
      final hasJournal = journalDates.contains(date);
      final isToday = date == today;
      final isFuture = date.compareTo(today) > 0;
      // School settings count Sunday as 0; DateTime counts it as 7.
      final neutral =
          settings.neutralWeekdays.contains(DateId.parse(date).weekday % 7) ||
          settings.holidays.contains(date);
      final textColor = hasJournal
          ? scheme.onPrimary
          : neutral || isFuture
          ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
          : scheme.onSurface;
      return Semantics(
        label: hasJournal ? '$day, ada jurnal' : '$day',
        button: hasJournal && onTapDay != null,
        child: InkResponse(
          key: ValueKey('calendar-$date'),
          onTap: hasJournal && onTapDay != null ? () => onTapDay!(date) : null,
          radius: 22,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasJournal ? scheme.primary : null,
                border: isToday
                    ? Border.all(
                        color: hasJournal ? scheme.onSurface : scheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Text(
                '$day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: hasJournal || isToday ? FontWeight.w700 : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: 42,
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(child: cell(row * 7 + column)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _Legend(
              dot: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
              label: 'Ada jurnal',
            ),
            _Legend(
              dot: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 2),
              ),
              label: 'Hari ini',
            ),
            Text(
              'Minggu dan libur tidak memutus streak',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.dot, required this.label});

  final BoxDecoration dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: dot),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// ‹ Oktober 2026 ›: steps through periods, or months.
class PeriodStepper extends StatelessWidget {
  const PeriodStepper({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;

  /// Null where the steps end.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('period-previous'),
          tooltip: 'Sebelumnya',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('period-next'),
          tooltip: 'Berikutnya',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
