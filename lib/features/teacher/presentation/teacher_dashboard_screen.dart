import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/school_repository.dart';
import '../data/teacher_repository.dart';
import '../domain/student_scope.dart';
import 'scope_filter_bar.dart';
import 'student_tile.dart';

/// Who is active, who needs attention, without opening students one by one,
/// for every student, the teacher's own, one class or one extracurricular.
/// Built from the summary documents; nothing is recomputed here beyond
/// counting (PRD §8.5).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final school = ref.watch(schoolProvider).value;
    final students = ref.watch(teacherStudentsProvider);
    final pending = ref.watch(pendingStudentsProvider).value ?? const [];
    final scope = ref.watch(effectiveDashboardScopeProvider);
    final me = session.profile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: AsyncView<List<StudentStats>>(
        value: students,
        onRetry: () => ref.invalidate(teacherStudentsProvider),
        data: (all) {
          final inScope = [
            for (final stats in all)
              if (scope.matches(stats.classId, stats.extracurriculars, me))
                stats,
          ];
          final pendingInScope = pending
              .where((m) => scope.matches(m.classId, m.extracurriculars, me))
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Halo, ${me.name}', style: theme.textTheme.titleLarge),
              if (school != null)
                Text(
                  school.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              const ScopeFilterBar(),
              const SizedBox(height: 8),
              _Summary(students: inScope, scope: scope),
              if (pendingInScope > 0) ...[
                const SizedBox(height: 12),
                _PendingNotice(count: pendingInScope, scope: scope),
              ],
              const SizedBox(height: 20),
              _StatusBreakdown(students: inScope, scope: scope),
              const SizedBox(height: 20),
              _NeedsAttention(students: inScope),
              if (!me.hasGroup) ...[
                const SizedBox(height: 20),
                const _SetRolesHint(),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// How many added students have never signed in. Opens the student list.
class _PendingNotice extends ConsumerWidget {
  const _PendingNotice({required this.count, required this.scope});

  final int count;
  final StudentScope scope;

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
          ref.read(studentListFilterProvider.notifier).showScope(scope);
          context.go(Routes.teacherStudents);
        },
      ),
    );
  }
}

/// Students, active books and this month's journals in scope. Each card
/// opens a list in the same scope.
class _Summary extends ConsumerWidget {
  const _Summary({required this.students, required this.scope});

  final List<StudentStats> students;
  final StudentScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBooks = students.where((s) => s.activeProgram != null).length;
    final journals = students.fold(0, (sum, s) => sum + s.journalCountMonth);
    final month = formatMonth(ref.watch(wibClockProvider).today());
    return StatCardRow(
      children: [
        Expanded(
          child: StatCard(
            key: const Key('dashboard-card-students'),
            label: 'Siswa',
            value: '${students.length}',
            icon: Icons.groups,
            onTap: () {
              ref.read(studentListFilterProvider.notifier).showScope(scope);
              context.go(Routes.teacherStudents);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            key: const Key('dashboard-card-books'),
            label: 'Buku aktif',
            value: '$activeBooks',
            icon: Icons.menu_book,
            color: context.palette.success,
            onTap: () => context.push(Routes.teacherActiveBooks),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            key: const Key('dashboard-card-journals'),
            label: 'Jurnal $month',
            value: '$journals',
            icon: Icons.edit_note,
            color: context.palette.heading,
            onTap: () => context.push(Routes.teacherMonthJournals),
          ),
        ),
      ],
    );
  }
}

class _StatusBreakdown extends ConsumerWidget {
  const _StatusBreakdown({required this.students, required this.scope});

  final List<StudentStats> students;
  final StudentScope scope;

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
                    ref
                        .read(studentListFilterProvider.notifier)
                        .showScope(scope, status: status);
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
                  Icon(Icons.check_circle, color: context.palette.success),
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

/// Asks a teacher without a homeroom class or supervised extracurricular to
/// set them, which turns on "Binaan saya".
class _SetRolesHint extends StatelessWidget {
  const _SetRolesHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('dashboard-set-roles'),
        leading: Icon(
          Icons.star_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Wali kelas atau pembina ekskul?'),
        subtitle: const Text(
          'Atur di Profil agar siswa binaan Anda bisa dilihat sekaligus.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(Routes.teacherProfile),
      ),
    );
  }
}
