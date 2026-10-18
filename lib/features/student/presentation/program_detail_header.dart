import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/palette.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../domain/reading_rules.dart';

/// Everything about one reading of a book above its journals: dates, how
/// long it took, its own streak and the closing review.
class ProgramDetailHeader extends ConsumerWidget {
  const ProgramDetailHeader({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(wibClockProvider).today();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final end = program.endDate(today);
    final facts = <(String, String)>[
      ('Mulai', formatDateLong(program.startDate)),
      switch (program.status) {
        ProgramStatus.completed => (
          'Selesai',
          formatDateLong(program.completedDate ?? end),
        ),
        ProgramStatus.stopped => ('Terakhir dibaca', formatDateLong(end)),
        ProgramStatus.active => (
          'Target',
          formatDateLong(program.targetDate) +
              (program.extended ? ' (diperpanjang)' : ''),
        ),
      },
      (
        program.isActive ? 'Sudah dibaca' : 'Lama membaca',
        '${readingDays(startDate: program.startDate, endDate: end)} hari',
      ),
      ('Jurnal', '${program.journalCount} hari'),
      ('Streak terbaik', '${program.streakBest} hari'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(
                        title: program.book.title,
                        coverUrl: program.book.coverUrl,
                        width: 64,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.book.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(program.book.author, style: muted),
                            const SizedBox(height: 6),
                            Text(
                              program.status.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: switch (program.status) {
                                  ProgramStatus.completed =>
                                    context.palette.activeText,
                                  ProgramStatus.stopped =>
                                    context.palette.neutralText,
                                  ProgramStatus.active =>
                                    theme.colorScheme.primary,
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppProgressBar(percent: program.percent),
                            const SizedBox(height: 4),
                            Text(
                              'Halaman ${program.currentPage} dari '
                              '${program.book.totalPages} · ${program.percent}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  for (final (label, value) in facts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(label, style: muted),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((program.finalReflection ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Ulasan akhir', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      program.finalReflection!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Jurnal', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
