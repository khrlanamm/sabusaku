import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/report.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/journal_view.dart';
import '../../../core/widgets/report_sheet.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';

const _maxCommentLength = 1000;

/// A student's journal with the comment thread. Teachers may add comments
/// and change or delete their own (PRD BR-17).
class TeacherJournalDetailScreen extends ConsumerStatefulWidget {
  const TeacherJournalDetailScreen({
    super.key,
    required this.programId,
    required this.date,
  });

  final String programId;
  final String date;

  @override
  ConsumerState<TeacherJournalDetailScreen> createState() =>
      _TeacherJournalDetailScreenState();
}

class _TeacherJournalDetailScreenState
    extends ConsumerState<TeacherJournalDetailScreen> {
  final _composer = TextEditingController();
  bool _sending = false;

  String get _programId => widget.programId;
  String get _date => widget.date;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(teacherRepositoryProvider)
          .addComment(_programId, _date, text);
      _composer.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _edit(JournalComment comment) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditCommentDialog(initial: comment.text),
    );
    if (text == null || text == comment.text || !mounted) return;
    await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .updateComment(_programId, _date, comment.id, text);
      return true;
    });
  }

  Future<void> _delete(JournalComment comment) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus komentar?',
      message: 'Komentar ini akan hilang dari jurnal siswa.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .deleteComment(_programId, _date, comment.id);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalProvider(_programId, _date));
    final comments = ref.watch(journalCommentsProvider(_programId, _date));
    final program = ref.watch(programProvider(_programId)).value;
    final myUid = ref.watch(currentSessionProvider).uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal siswa'),
        actions: [
          if (journal.value != null)
            PopupMenuButton<ReportTarget>(
              key: const Key('journal-menu'),
              tooltip: 'Lainnya',
              onSelected: (target) =>
                  showReportSheet(context, ref, target: target),
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: const Key('journal-report'),
                  value: ReportTarget.journal(
                    programId: _programId,
                    date: _date,
                  ),
                  child: const Text('Laporkan jurnal'),
                ),
              ],
            ),
        ],
      ),
      body: AsyncView<Journal?>(
        value: journal,
        onRetry: () => ref.invalidate(journalProvider(_programId, _date)),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.edit_note,
              title: 'Jurnal tidak ditemukan',
              message: 'Siswa mungkin sudah menghapus jurnal ini.',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (program != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          program.book.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    JournalContentView(journal: data),
                    const Divider(height: 28),
                    Text('Komentar', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    switch (comments) {
                      AsyncData(:final value) when value.isEmpty => Text(
                        'Belum ada komentar. Tulis tanggapan untuk siswa di '
                        'bawah.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AsyncData(:final value) => Column(
                        children: [
                          for (final comment in value)
                            CommentTile(
                              comment: comment,
                              programId: _programId,
                              date: _date,
                              actions: comment.teacherId == myUid
                                  ? PopupMenuButton<String>(
                                      tooltip: 'Kelola komentar',
                                      onSelected: (action) => action == 'edit'
                                          ? _edit(comment)
                                          : _delete(comment),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Ubah'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus'),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      AsyncError(:final error) => ErrorState(error: error),
                      _ => const SkeletonList(items: 1, itemHeight: 64),
                    },
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('comment-input'),
                          controller: _composer,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: _maxCommentLength,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Tulis komentar untuk siswa',
                            counterText: '',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton.filled(
                        key: const Key('comment-send'),
                        tooltip: 'Kirim komentar',
                        onPressed: _composer.text.trim().isEmpty || _sending
                            ? null
                            : _send,
                        icon: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initial});

  final String initial;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah komentar'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        maxLength: _maxCommentLength,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
