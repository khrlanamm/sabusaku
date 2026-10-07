import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/time/date_format.dart';
import '../data/journal_outbox.dart';

/// "Jurnal belum terkirim": journals the server refused, with the reason and
/// the saved text, so a rejection is never silent (docs/03 §3).
class OutboxNotice extends ConsumerWidget {
  const OutboxNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = [
      for (final entry in ref.watch(journalOutboxProvider))
        if (entry.status == OutboxStatus.failed) entry,
    ];
    if (failed.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final entry in failed) _FailedCard(entry: entry),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FailedCard extends ConsumerWidget {
  const _FailedCard({required this.entry});

  final OutboxEntry entry;

  void _showSavedText(BuildContext context) {
    final draft = entry.draft!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Jurnal ${formatDateShort(entry.date)}'),
        content: SingleChildScrollView(
          child: SelectableText(
            [
              'Halaman ${draft.pageStart}–${draft.pageEnd} · '
                  '${draft.durationRange.label}',
              '',
              'Informasi penting:',
              draft.keyInformation,
              if (draft.reflection.isNotEmpty) ...[
                '',
                'Hal yang menarik:',
                draft.reflection,
              ],
              if (draft.question.isNotEmpty) ...[
                '',
                'Pertanyaan:',
                draft.question,
              ],
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDelete = entry.kind == OutboxKind.delete;
    return Container(
      key: const Key('outbox-failed'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.inactiveTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inactiveText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: AppColors.inactiveText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDelete ? 'Jurnal gagal dihapus' : 'Jurnal belum terkirim',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.inactiveText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${formatDateLong(entry.date)}\n${entry.reason ?? ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inactiveText,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (entry.draft != null)
                TextButton(
                  onPressed: () => _showSavedText(context),
                  child: const Text('Lihat isi'),
                ),
              TextButton(
                key: const Key('outbox-dismiss'),
                onPressed: () =>
                    ref.read(journalOutboxProvider.notifier).dismiss(entry),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
