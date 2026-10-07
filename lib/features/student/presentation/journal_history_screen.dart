import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/program.dart';
import '../../../core/widgets/journal_list.dart';
import '../../../core/widgets/states.dart';
import '../data/student_repository.dart';

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
          : JournalList(
              program: program,
              onOpen: (journal) =>
                  context.push(Routes.studentJournal(program.id, journal.date)),
            );
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
            : JournalList(
                program: data,
                onOpen: (journal) =>
                    context.push(Routes.studentJournal(data.id, journal.date)),
              ),
      ),
    );
  }
}
