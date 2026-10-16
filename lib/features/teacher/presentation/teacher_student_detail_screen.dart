import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/journal_list.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../student/presentation/student_home_screen.dart' show OverdueLabel;
import '../../student/presentation/student_profile_screen.dart'
    show ProgramHistoryTile;
import '../data/teacher_repository.dart';
import 'student_form.dart';
import 'student_tile.dart' show labelLine;

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
                message: 'Siswa ini mungkin sudah dikeluarkan dari sekolah.',
              )
            : _Body(stats: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.stats});

  final StudentStats stats;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final edit = await showStudentEditor(
      context,
      title: 'Ubah data siswa',
      initial: (
        name: stats.name,
        classId: stats.classId,
        extracurriculars: stats.extracurriculars,
      ),
    );
    if (edit == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .updateStudent(
            stats.studentId,
            name: edit.name,
            classId: edit.classId,
            extracurriculars: edit.extracurriculars,
          );
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Data siswa disimpan.');
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluarkan dari sekolah?',
      message:
          '${stats.name} tidak bisa lagi membuka Sabu Saku di sekolah ini. '
          'Akunnya tetap ada. Jurnal dan riwayat bukunya disimpan dan muncul '
          'kembali bila emailnya ditambahkan lagi.',
      confirmLabel: 'Keluarkan',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(teacherRepositoryProvider).removeStudent(stats.email);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, '${stats.name} dikeluarkan dari sekolah.');
      context.pop();
    }
  }

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showTypedConfirmDialog(
      context,
      title: 'Hapus data permanen?',
      message:
          'Semua buku, jurnal, dan komentar ${stats.name} di sekolah ini '
          'dihapus selamanya dan tidak bisa dikembalikan. Siswa juga '
          'dikeluarkan dari sekolah. Akunnya sendiri tetap ada.',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(teacherRepositoryProvider).eraseStudent(stats.email);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Data ${stats.name} dihapus.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final book = stats.activeProgram;
    final programs = ref.watch(studentProgramsProvider(stats.studentId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(photoUrl: stats.photoUrl, name: stats.name, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stats.name, style: theme.textTheme.titleLarge),
                  Text(
                    labelLine(stats.classId, stats.extracurriculars),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    stats.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(status: stats.status),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('student-edit'),
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ubah nama, kelas, ekskul'),
          ),
        ),
        const SizedBox(height: 16),
        if (book == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada buku yang sedang dibaca.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(book.title, style: theme.textTheme.titleSmall),
                          Text(
                            book.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatDayMonth(date),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        Text('Riwayat buku', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ketuk buku untuk melihat semua jurnalnya.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        switch (programs) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Belum ada buku.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('student-remove'),
          onPressed: () => _remove(context, ref),
          icon: const Icon(Icons.logout),
          label: const Text('Keluarkan dari sekolah'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('student-erase'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _erase(context, ref),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Hapus data permanen'),
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

/// Confirmation for an irreversible action: the button only enables after
/// typing HAPUS.
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String word = 'HAPUS',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) =>
        _TypedConfirmDialog(title: title, message: message, word: word),
  );
  return result ?? false;
}

class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({
    required this.title,
    required this.message,
    required this.word,
  });

  final String title;
  final String message;
  final String word;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            key: const Key('typed-confirm-field'),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Ketik ${widget.word} untuk melanjutkan',
            ),
            onChanged: (value) => setState(() => _typed = value.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('typed-confirm-ok'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _typed == widget.word
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Hapus permanen'),
        ),
      ],
    );
  }
}
