import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reading_repository.dart';
import '../models/journal.dart';
import '../models/program.dart';
import 'journal_view.dart';
import 'states.dart';

const _pageSize = 20;

/// Journals of one book, newest first, 20 at a time. Used by the student's
/// history and by the teacher's view of a student.
class JournalList extends ConsumerStatefulWidget {
  const JournalList({
    super.key,
    required this.program,
    required this.onOpen,
    this.showUnreadBadge = true,
  });

  final Program program;
  final ValueChanged<Journal> onOpen;

  /// The "unread comment" marker is the student's; teachers do not see it.
  final bool showUnreadBadge;

  @override
  ConsumerState<JournalList> createState() => _JournalListState();
}

class _JournalListState extends ConsumerState<JournalList> {
  int _limit = _pageSize;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final journals = ref.watch(journalsProvider(program.id, _limit));
    final theme = Theme.of(context);

    return AsyncView<List<Journal>>(
      value: journals,
      onRetry: () => ref.invalidate(journalsProvider(program.id, _limit)),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.edit_note,
            title: 'Belum ada jurnal',
            message: 'Buku: "${program.book.title}"',
          );
        }
        final hasMore = items.length >= _limit;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: items.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                '${program.book.title} · ${program.status.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            if (index == items.length + 1) {
              return hasMore
                  ? OutlinedButton(
                      onPressed: () => setState(() => _limit += _pageSize),
                      child: const Text('Muat lebih banyak'),
                    )
                  : const SizedBox.shrink();
            }
            final journal = items[index - 1];
            return JournalListTile(
              journal: journal,
              showUnreadBadge: widget.showUnreadBadge,
              onTap: () => widget.onOpen(journal),
            );
          },
        );
      },
    );
  }
}
