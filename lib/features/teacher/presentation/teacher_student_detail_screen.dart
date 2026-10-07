import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/credential.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/credentials_dialog.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/journal_list.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';
import '../../student/presentation/student_home_screen.dart' show OverdueLabel;
import '../../student/presentation/student_profile_screen.dart'
    show ProgramHistoryTile;
import '../data/teacher_repository.dart';

class TeacherStudentDetailScreen extends ConsumerWidget {
  const TeacherStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(studentStatsProvider(studentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail siswa')),
      body: AsyncView<StudentStats?>(
        value: stats,
        onRetry: () => ref.invalidate(studentStatsProvider(studentId)),
        data: (data) => data == null
            ? const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Siswa tidak ditemukan',
                message:
                    'Siswa ini mungkin sudah pindah kelas atau dinonaktifkan.',
              )
            : _Body(stats: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.stats});

  final StudentStats stats;

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset password?',
      message:
          '${stats.name} akan keluar dari semua perangkat dan harus masuk '
          'dengan password sementara.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;
    final password = await runWithProgress(
      context,
      () => ref
          .read(teacherRepositoryProvider)
          .resetStudentPassword(stats.studentId),
    );
    if (password == null || !context.mounted) return;
    await showCredentialDialog(
      context,
      Credential(
        name: stats.name,
        username: stats.nis ?? '',
        password: password,
        role: UserRole.siswa,
        className: stats.className ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final book = stats.activeProgram;
    final classId = stats.classId;
    final programs = classId == null
        ? const AsyncData(<Program>[])
        : ref.watch(studentProgramsProvider(stats.studentId, classId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stats.name, style: theme.textTheme.titleLarge),
                  Text(
                    [
                      if (stats.className != null) stats.className!,
                      if (stats.nis != null) 'NIS ${stats.nis}',
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(status: stats.status),
          ],
        ),
        const SizedBox(height: 16),
        if (book == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada buku yang sedang dibaca.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('student-active-book'),
              onTap: () => context.push(
                Routes.teacherProgram(stats.studentId, book.programId),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(title: book.title, width: 60),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buku aktif',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.blue,
                            ),
                          ),
                          Text(book.title, style: theme.textTheme.titleSmall),
                          Text(
                            book.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppProgressBar(percent: book.percent),
                          const SizedBox(height: 4),
                          Text(
                            'Halaman ${book.currentPage} dari '
                            '${book.totalPages} · ${book.percent}%',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Target ${formatDateShort(book.targetDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          if (book.overdue)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: OverdueLabel(),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Streak',
                value: '${stats.streakCurrent}',
                icon: Icons.local_fire_department,
                color: const Color(0xFFD98200),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Jurnal bulan ini',
                value: '${stats.journalCountMonth}',
                icon: Icons.edit_note,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Buku selesai',
                value: '${stats.booksCompleted}',
                icon: Icons.menu_book,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Aktivitas terakhir', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (stats.recentDates.isEmpty)
          Text(
            'Belum pernah menulis jurnal.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final date in stats.recentDates)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatDayMonth(date),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
          if (book != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                stats.daysSinceLastJournal == 0
                    ? 'Sudah menulis jurnal hari ini.'
                    : '${stats.daysSinceLastJournal} hari efektif sejak '
                          'jurnal terakhir.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        Text('Riwayat buku', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ketuk buku untuk melihat semua jurnalnya.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 10),
        switch (programs) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Belum ada buku.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final program in value)
                ProgramHistoryTile(
                  program: program,
                  onTap: () => context.push(
                    Routes.teacherProgram(stats.studentId, program.id),
                  ),
                ),
            ],
          ),
          AsyncError(:final error) => ErrorState(error: error),
          _ => const SkeletonList(items: 2, itemHeight: 72),
        },
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('student-reset-password'),
          onPressed: () => _resetPassword(context, ref),
          icon: const Icon(Icons.lock_reset),
          label: const Text('Reset password siswa'),
        ),
      ],
    );
  }
}

/// All journals of one of the student's books.
class TeacherProgramJournalsScreen extends ConsumerWidget {
  const TeacherProgramJournalsScreen({
    super.key,
    required this.studentId,
    required this.programId,
  });

  final String studentId;
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider(programId));
    return Scaffold(
      appBar: AppBar(title: Text(program.value?.book.title ?? 'Jurnal')),
      body: AsyncView<Program?>(
        value: program,
        onRetry: () => ref.invalidate(programProvider(programId)),
        data: (data) => data == null
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Buku tidak ditemukan',
              )
            : JournalList(
                program: data,
                showUnreadBadge: false,
                onOpen: (journal) => context.push(
                  Routes.teacherJournal(studentId, programId, journal.date),
                ),
              ),
      ),
    );
  }
}
