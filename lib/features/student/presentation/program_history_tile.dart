import 'package:flutter/material.dart';

import '../../../app/theme/palette.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/book_cover.dart';
import '../domain/reading_rules.dart';

/// One book in a reading history, with its month, status and progress.
class ProgramHistoryTile extends StatelessWidget {
  const ProgramHistoryTile({
    super.key,
    required this.program,
    required this.onTap,
    this.timesRead = 1,
  });

  final Program program;
  final VoidCallback onTap;

  /// How often the student read this book, when a list shows each book once.
  final int timesRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedDate = program.completedDate;
    final (color, tint) = switch (program.status) {
      ProgramStatus.active => (
        Theme.of(context).colorScheme.primary,
        context.palette.infoTint,
      ),
      ProgramStatus.completed => (
        context.palette.activeText,
        context.palette.activeTint,
      ),
      ProgramStatus.stopped => (
        context.palette.neutralText,
        context.palette.neutralTint,
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(
                title: program.book.title,
                coverUrl: program.book.coverUrl,
                width: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      [
                        formatMonth(program.startDate),
                        '${program.journalCount} jurnal',
                        '${program.percent}%',
                        if (timesRead > 1) 'Dibaca $timesRead×',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            program.status.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Read as one phrase with the "Selesai" chip.
                        if (program.status == ProgramStatus.completed &&
                            completedDate != null)
                          Text(
                            '${formatDayMonthLong(completedDate)} · '
                            'Lama membaca: ${readingDays(startDate: program.startDate, endDate: completedDate)} hari',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
