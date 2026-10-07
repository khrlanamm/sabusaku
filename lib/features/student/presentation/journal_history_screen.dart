import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/widgets/journal_view.dart';
import '../../../core/widgets/states.dart';
import '../data/student_repository.dart';

const _pageSize = 20;

/// "Riwayat Jurnal" tab: journals of the book being read, or of the most
/// recent book when none is active.
class JournalHistoryTab extends ConsumerWidget {
  const JournalHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProgramProvider);
    final programs = ref.watch(myProgramsProvider);

    final Widget body;
    if (active.isLoading || (active.value == null && programs.isLoading)) {
      body = const SkeletonList();
    } else if (active.hasError) {
      body = ErrorState(
        error: active.error!,
        onRetry: () => ref.invalidate(activeProgramProvider),
      );
    } else {
      final program = active.value ?? programs.value?.firstOrNull;
      body = program == null
          ? EmptyState(
              icon: Icons.edit_note,
              title: 'Belum ada jurnal',
              message: 'Mulai satu buku, lalu catat bacaanmu setiap hari.',
              action: FilledButton(
                onPressed: () => context.go(Routes.studentBook),
                child: const Text('Mulai Buku'),
              ),
            )
          : JournalList(program: program);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Jurnal')),
      floatingActionButton: active.value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('journals-write'),
              // Shell tabs stay mounted together; default hero tags would clash.
              heroTag: 'fab-journals',
              onPressed: () => context.push(Routes.studentWriteJournal),
              icon: const Icon(Icons.edit),
              label: const Text('Isi Jurnal'),
            ),
      body: body,
    );
  }
}

/// Journals of one past or current book, opened from the profile.
class ProgramJournalsScreen extends ConsumerWidget {
  const ProgramJournalsScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider(programId));
    return Scaffold(
      appBar: AppBar(title: Text(program.value?.book.title ?? 'Jurnal')),
      body: AsyncView<Program?>(
        value: program,
        data: (data) => data == null
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Buku tidak ditemukan',
              )
            : JournalList(program: data),
      ),
    );
  }
}

/// Newest first, 20 at a time.
class JournalList extends ConsumerStatefulWidget {
  const JournalList({super.key, required this.program});

  final Program program;

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
            message: program.isActive
                ? 'Tulis jurnal pertamamu untuk "${program.book.title}".'
                : null,
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
                  color: AppColors.inkMuted,
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
              onTap: () =>
                  context.push(Routes.studentJournal(program.id, journal.date)),
            );
          },
        );
      },
    );
  }
}
