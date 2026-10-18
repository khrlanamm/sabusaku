import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';
import 'scope_filter_bar.dart';
import 'student_tile.dart' show labelLine;

/// This month's journals of the students in the dashboard's scope: totals,
/// students ranked by how many they wrote, and who has written none. Opened
/// from the "Jurnal \<bulan\>" card; the scope can be changed here too.
class TeacherMonthJournalsScreen extends ConsumerWidget {
  const TeacherMonthJournalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(teacherStudentsProvider);
    final scope = ref.watch(effectiveDashboardScopeProvider);
    final me = ref.watch(currentSessionProvider.select((s) => s.profile));
    final month = formatMonth(ref.watch(wibClockProvider).today());

    return Scaffold(
      appBar: AppBar(title: Text('Jurnal $month')),
      body: Column(
        children: [
          const ScopeFilterBar(padding: EdgeInsets.symmetric(horizontal: 16)),
          Expanded(
            child: AsyncView<List<StudentStats>>(
              value: students,
              onRetry: () => ref.invalidate(teacherStudentsProvider),
              data: (all) {
                final inScope = [
                  for (final stats in all)
                    if (scope.matches(
                      stats.classId,
                      stats.extracurriculars,
                      me,
                    ))
                      stats,
                ];
                if (inScope.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Tidak ada siswa',
                    message: 'Pilih cakupan lain di atas.',
                  );
                }
                final writers =
                    inScope.where((s) => s.journalCountMonth > 0).toList()
                      ..sort(
                        (a, b) => b.journalCountMonth != a.journalCountMonth
                            ? b.journalCountMonth.compareTo(a.journalCountMonth)
                            : a.name.compareTo(b.name),
                      );
                final silent =
                    inScope.where((s) => s.journalCountMonth == 0).toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Summary(students: inScope, writers: writers.length),
                    const SizedBox(height: 16),
                    if (writers.isEmpty)
                      Text(
                        'Belum ada jurnal bulan ini.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (index, stats) in writers.indexed) ...[
                              if (index > 0) const Divider(),
                              _StudentRow(stats: stats, showCount: true),
                            ],
                          ],
                        ),
                      ),
                    if (silent.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          key: const Key('month-journals-silent'),
                          leading: Icon(
                            Icons.edit_off_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Belum menulis bulan ini (${silent.length})',
                          ),
                          children: [
                            for (final stats in silent)
                              _StudentRow(stats: stats),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.students, required this.writers});

  final List<StudentStats> students;
  final int writers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = students.fold(0, (sum, s) => sum + s.journalCountMonth);
    final average = total / students.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total jurnal',
                    key: const Key('month-journals-total'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$writers dari ${students.length} siswa menulis · '
                    'rata-rata ${average.toStringAsFixed(1).replaceAll('.', ',')} '
                    'per siswa',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One student: photo, name, labels, and this month's journal count or
/// their status. Opens the student.
class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.stats, this.showCount = false});

  final StudentStats stats;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: Key('month-journals-${stats.studentId}'),
      onTap: () => context.push(Routes.teacherStudent(stats.studentId)),
      leading: UserAvatar(photoUrl: stats.photoUrl, name: stats.name),
      title: Text(stats.name.isEmpty ? stats.email : stats.name),
      subtitle: Text(labelLine(stats.classId, stats.extracurriculars)),
      trailing: !showCount
          ? StatusChip(status: stats.status)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.journalCountMonth}',
                  style: theme.textTheme.titleLarge,
                ),
                Text('jurnal', style: theme.textTheme.bodySmall),
              ],
            ),
    );
  }
}
