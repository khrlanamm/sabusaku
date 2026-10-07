import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';
import 'student_tile.dart';

/// Who is active, who needs attention, without opening students one by one.
/// Built from the summary documents; nothing is recomputed here beyond
/// counting (PRD §8.5).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final students = ref.watch(teacherStudentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: session.classIds.isEmpty
          ? const EmptyState(
              icon: Icons.class_outlined,
              title: 'Belum ada kelas',
              message:
                  'Kamu belum ditugaskan ke kelas mana pun. Hubungi admin '
                  'sekolah.',
            )
          : AsyncView<List<StudentStats>>(
              value: students,
              onRetry: () => ref.invalidate(teacherStudentsProvider),
              data: (all) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Halo, ${session.profile.name}',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '${session.classIds.length} kelas dipantau',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Summary(students: all),
                  const SizedBox(height: 20),
                  _StatusBreakdown(students: all),
                  const SizedBox(height: 20),
                  _NeedsAttention(students: all),
                ],
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.students});

  final List<StudentStats> students;

  @override
  Widget build(BuildContext context) {
    final activeBooks = students.where((s) => s.activeProgram != null).length;
    final journals = students.fold(0, (sum, s) => sum + s.journalCountMonth);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Siswa',
            value: '${students.length}',
            icon: Icons.groups,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            label: 'Buku aktif',
            value: '$activeBooks',
            icon: Icons.menu_book,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            label: 'Jurnal bulan ini',
            value: '$journals',
            icon: Icons.edit_note,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdown extends ConsumerWidget {
  const _StatusBreakdown({required this.students});

  final List<StudentStats> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Status siswa', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, status) in StudentStatus.values.indexed) ...[
                if (index > 0) const Divider(),
                InkWell(
                  key: Key('dashboard-status-${status.wire}'),
                  // Opens the student list filtered by this status.
                  onTap: () {
                    ref.read(studentListFilterProvider.notifier)
                      ..setClass(null)
                      ..setStatus(status);
                    context.go(Routes.teacherStudents);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        StatusChip(status: status),
                        const Spacer(),
                        Text(
                          '${students.where((s) => s.status == status).length}',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.students});

  final List<StudentStats> students;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Longest silence first.
    final list =
        students
            .where(
              (s) =>
                  s.status == StudentStatus.perluPerhatian ||
                  s.status == StudentStatus.tidakAktif,
            )
            .toList()
          ..sort(
            (a, b) => b.daysSinceLastJournal.compareTo(a.daysSinceLastJournal),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Perlu perhatian', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada siswa yang perlu perhatian.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final stats in list.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StudentTile(
                stats: stats,
                onTap: () =>
                    context.push(Routes.teacherStudent(stats.studentId)),
              ),
            ),
      ],
    );
  }
}
