import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../student/presentation/student_home_screen.dart' show OverdueLabel;
import '../data/teacher_repository.dart';
import 'scope_filter_bar.dart';
import 'student_tile.dart' show labelLine;
import 'teacher_student_detail_screen.dart' show ExtendedLabel;

/// The books students in the dashboard's scope are reading now, those past
/// their target first, then by the nearest target. Opened from the "Buku
/// aktif" card; the scope can be changed here too.
class TeacherActiveBooksScreen extends ConsumerWidget {
  const TeacherActiveBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(teacherStudentsProvider);
    final scope = ref.watch(effectiveDashboardScopeProvider);
    final me = ref.watch(currentSessionProvider.select((s) => s.profile));

    return Scaffold(
      appBar: AppBar(title: const Text('Buku aktif')),
      body: Column(
        children: [
          const ScopeFilterBar(padding: EdgeInsets.symmetric(horizontal: 16)),
          Expanded(
            child: AsyncView<List<StudentStats>>(
              value: students,
              onRetry: () => ref.invalidate(teacherStudentsProvider),
              data: (all) {
                final reading = [
                  for (final stats in all)
                    if (stats.activeProgram != null &&
                        scope.matches(
                          stats.classId,
                          stats.extracurriculars,
                          me,
                        ))
                      stats,
                ]..sort(_byUrgency);
                if (reading.isEmpty) {
                  return const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Belum ada buku aktif',
                    message: 'Tidak ada siswa yang sedang membaca buku.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Summary(reading: reading),
                    const SizedBox(height: 12),
                    for (final stats in reading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookTile(stats: stats),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Past the target first, then the nearest target, then by name.
  static int _byUrgency(StudentStats a, StudentStats b) {
    final bookA = a.activeProgram!;
    final bookB = b.activeProgram!;
    if (bookA.overdue != bookB.overdue) return bookA.overdue ? -1 : 1;
    final byTarget = bookA.targetDate.compareTo(bookB.targetDate);
    return byTarget != 0 ? byTarget : a.name.compareTo(b.name);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.reading});

  final List<StudentStats> reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average =
        reading.fold(0, (sum, s) => sum + s.activeProgram!.percent) ~/
        reading.length;
    final overdue = reading.where((s) => s.activeProgram!.overdue).length;
    return Text(
      [
        '${reading.length} buku aktif',
        'rata-rata progres $average%',
        if (overdue > 0) '$overdue lewat target',
      ].join(' · '),
      key: const Key('active-books-summary'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.stats});

  final StudentStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final book = stats.activeProgram!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          Routes.teacherProgram(stats.studentId, book.programId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(title: book.title, coverUrl: book.coverUrl, width: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(book.author, style: muted),
                    const SizedBox(height: 6),
                    Text(
                      stats.name.isEmpty ? stats.email : stats.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      labelLine(stats.classId, stats.extracurriculars),
                      style: muted,
                    ),
                    const SizedBox(height: 8),
                    AppProgressBar(percent: book.percent, height: 6),
                    const SizedBox(height: 4),
                    Text(
                      '${book.percent}% · target '
                      '${formatDateShort(book.targetDate)}',
                      style: muted,
                    ),
                    if (book.extended || book.overdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (book.extended) const ExtendedLabel(),
                            if (book.overdue) const OverdueLabel(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
