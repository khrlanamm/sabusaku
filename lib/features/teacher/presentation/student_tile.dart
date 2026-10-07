import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/status_chip.dart';

/// One student in a teacher's list: status, current book and progress.
class StudentTile extends StatelessWidget {
  const StudentTile({super.key, required this.stats, required this.onTap});

  final StudentStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = stats.activeProgram;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stats.name, style: theme.textTheme.titleSmall),
                        Text(
                          [
                            if (stats.className != null) stats.className!,
                            if (stats.nis != null) 'NIS ${stats.nis}',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: stats.status),
                ],
              ),
              if (book != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '${book.percent}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppProgressBar(percent: book.percent, height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
