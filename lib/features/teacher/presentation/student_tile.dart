import 'package:flutter/material.dart';

import '../../../core/models/member.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/user_avatar.dart';

/// Class and extracurricular labels on one line, e.g. `XII-A1 · Masis-KIR`.
String labelLine(String? classId, List<String> extracurriculars) =>
    [classId ?? 'Kelas belum diisi', ...extracurriculars].join(' · ');

/// One student in a teacher's list: photo, labels, status, current book and
/// progress.
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
                  UserAvatar(photoUrl: stats.photoUrl, name: stats.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.name.isEmpty ? stats.email : stats.name,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          labelLine(stats.classId, stats.extracurriculars),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.primary,
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

/// A student added by a teacher who has not signed in yet.
class PendingMemberTile extends StatelessWidget {
  const PendingMemberTile({
    super.key,
    required this.member,
    required this.onTap,
  });

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(member.name.isEmpty ? member.email : member.name),
      subtitle: Text(
        [
          if (member.name.isNotEmpty) member.email,
          labelLine(member.classId, member.extracurriculars),
        ].join('\n'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      isThreeLine: member.name.isNotEmpty,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
