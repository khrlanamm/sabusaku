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
import '../../auth/data/school_repository.dart';
import '../data/teacher_repository.dart';
import 'student_tile.dart';

/// Who is active, who needs attention, without opening students one by one,
/// for the whole school or one extracurricular.
/// Built from the summary documents; nothing is recomputed here beyond
/// counting (PRD §8.5).
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  /// Narrows the whole dashboard to one extracurricular.
  String? _extracurricular;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final school = ref.watch(schoolProvider).value;
    final students = ref.watch(teacherStudentsProvider);
    final pending = ref.watch(pendingStudentsProvider).value ?? const [];
    final theme = Theme.of(context);
    final extracurriculars = school?.extracurriculars ?? const <String>[];
    final scope = extracurriculars.contains(_extracurricular)
        ? _extracurricular
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: AsyncView<List<StudentStats>>(
        value: students,
        onRetry: () => ref.invalidate(teacherStudentsProvider),
        data: (all) {
          final inScope = [
            for (final stats in all)
              if (scope == null || stats.extracurriculars.contains(scope))
                stats,
          ];
          final pendingInScope = pending
              .where((m) => scope == null || m.extracurriculars.contains(scope))
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Halo, ${session.profile.name}',
                style: theme.textTheme.titleLarge,
              ),
              if (school != null)
                Text(
                  school.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (extracurriculars.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final label in [null, ...extracurriculars])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: Key('dashboard-scope-${label ?? 'all'}'),
                            label: Text(label ?? 'Semua siswa'),
                            selected: scope == label,
                            onSelected: (_) =>
                                setState(() => _extracurricular = label),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _Summary(students: inScope),
              if (pendingInScope > 0) ...[
                const SizedBox(height: 12),
                _PendingNotice(count: pendingInScope, extracurricular: scope),
              ],
              const SizedBox(height: 20),
              _StatusBreakdown(students: inScope, extracurricular: scope),
              const SizedBox(height: 20),
              _NeedsAttention(students: inScope),
            ],
          );
        },
      ),
    );
  }
}

/// How many added students have never signed in. Opens the student list.
class _PendingNotice extends ConsumerWidget {
  const _PendingNotice({required this.count, required this.extracurricular});

  final int count;
  final String? extracurricular;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('dashboard-pending'),
        leading: Icon(
          Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('$count siswa belum masuk aplikasi'),
        subtitle: const Text(
          'Ingatkan mereka masuk dengan email yang didaftarkan.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ref.read(studentListFilterProvider.notifier)
            ..reset()
            ..setExtracurricular(extracurricular);
          context.go(Routes.teacherStudents);
        },
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
  const _StatusBreakdown({required this.students, this.extracurricular});

  final List<StudentStats> students;
  final String? extracurricular;

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
                      ..reset()
                      ..setExtracurricular(extracurricular)
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
