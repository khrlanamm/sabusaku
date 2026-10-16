import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/journal_view.dart';
import '../../../core/widgets/states.dart';
import '../data/journal_outbox.dart';
import '../data/student_repository.dart';
import '../domain/reading_rules.dart';

/// One journal with the teacher's comments. Opening it marks the comments as
/// read. Also the target of the comment notification deep link.
class StudentJournalDetailScreen extends ConsumerStatefulWidget {
  const StudentJournalDetailScreen({
    super.key,
    required this.programId,
    required this.date,
  });

  final String programId;
  final String date;

  @override
  ConsumerState<StudentJournalDetailScreen> createState() =>
      _StudentJournalDetailScreenState();
}

class _StudentJournalDetailScreenState
    extends ConsumerState<StudentJournalDetailScreen> {
  String get programId => widget.programId;
  String get date => widget.date;

  @override
  void initState() {
    super.initState();
    // Reading the journal is what marks its comments as read, now and when a
    // new comment arrives while the screen is open.
    ref.listenManual(journalProvider(programId, date), (_, next) {
      final value = next.value;
      if (value != null) {
        ref.read(studentRepositoryProvider).markCommentsRead(value);
      }
    }, fireImmediately: true);
  }

  Future<void> _delete(String title) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus jurnal ini?',
      message: 'Jurnal dan komentar guru di dalamnya akan hilang.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    ref
        .read(journalWriterProvider)
        .delete(programId: programId, bookTitle: title, date: date);
    showSnack(context, 'Jurnal dihapus');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalProvider(programId, date));
    final program = ref.watch(programProvider(programId)).value;
    final today = ref.watch(wibClockProvider).today();

    final editable =
        journal.value != null &&
        (program?.isActive ?? false) &&
        canEditJournal(journalDate: date, today: today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal'),
        actions: [
          if (editable) ...[
            IconButton(
              key: const Key('journal-edit'),
              tooltip: 'Ubah',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('${Routes.studentWriteJournal}?date=$date'),
            ),
            IconButton(
              key: const Key('journal-delete'),
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(program?.book.title ?? ''),
            ),
          ],
        ],
      ),
      body: AsyncView<Journal?>(
        value: journal,
        onRetry: () => ref.invalidate(journalProvider(programId, date)),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.edit_note,
              title: 'Jurnal tidak ditemukan',
              message: 'Jurnal ini mungkin sudah dihapus.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (program != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    program.book.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              JournalContentView(journal: data),
              const Divider(height: 28),
              _Comments(programId: programId, date: date),
            ],
          );
        },
      ),
    );
  }
}

class _Comments extends ConsumerWidget {
  const _Comments({required this.programId, required this.date});

  final String programId;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(journalCommentsProvider(programId, date));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Komentar guru', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        switch (comments) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Belum ada komentar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final comment in value)
                CommentTile(comment: comment, programId: programId, date: date),
            ],
          ),
          AsyncError() => Text(
            'Komentar belum bisa dimuat.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          _ => const SkeletonList(items: 1, itemHeight: 64),
        },
      ],
    );
  }
}
