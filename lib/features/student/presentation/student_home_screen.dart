import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/journal_outbox.dart';
import '../data/student_repository.dart';
import 'outbox_notice.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final program = ref.watch(activeProgramProvider);
    final stats = ref.watch(myStatsProvider).value;
    final today = ref.watch(wibClockProvider).today();
    final theme = Theme.of(context);
    final firstName = session.profile.name.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text('Halo, $firstName', style: theme.textTheme.headlineSmall),
            Text(
              formatDateLong(today),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            const OutboxNotice(),
            AsyncView<Program?>(
              value: program,
              onRetry: () => ref.invalidate(activeProgramProvider),
              loading: const SkeletonList(items: 1, itemHeight: 200),
              data: (active) => active == null
                  ? const _NoBookCard()
                  : _BookCard(program: active, today: today),
            ),
            const SizedBox(height: 16),
            _StatsRow(stats: stats, today: today),
            if (program.value case final active?) ...[
              const SizedBox(height: 20),
              _NewComments(programId: active.id),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoBookCard extends StatelessWidget {
  const _NoBookCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.menu_book, size: 44, color: AppColors.blue),
            const SizedBox(height: 10),
            Text(
              'Belum ada buku bulan ini',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih satu buku untuk dibaca, lalu catat bacaanmu setiap hari.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('home-start-book'),
              onPressed: () => context.go(Routes.studentBook),
              icon: const Icon(Icons.add),
              label: const Text('Mulai Buku'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.program, required this.today});

  final Program program;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Read from the local cache, so this flips the moment a journal is saved,
    // also offline.
    final todayJournal = ref.watch(journalProvider(program.id, today)).value;
    final written = todayJournal != null;
    final overdue = program.isOverdue(today);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(title: program.book.title, width: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buku bulan ini',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.blue,
                        ),
                      ),
                      Text(
                        program.book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        program.book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(percent: program.percent),
                      const SizedBox(height: 4),
                      Text(
                        'Halaman ${program.currentPage} dari '
                        '${program.book.totalPages} · ${program.percent}%',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (overdue)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: OverdueLabel(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (written)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jurnal hari ini sudah diisi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.activeText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(Routes.studentJournal(program.id, today)),
                    child: const Text('Lihat'),
                  ),
                ],
              )
            else
              FilledButton.icon(
                key: const Key('home-write-journal'),
                onPressed: () => context.push(Routes.studentWriteJournal),
                icon: const Icon(Icons.edit),
                label: const Text('Isi Jurnal Hari Ini'),
              ),
          ],
        ),
      ),
    );
  }
}

class OverdueLabel extends StatelessWidget {
  const OverdueLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.attentionTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: AppColors.attentionText),
          SizedBox(width: 4),
          Text(
            'Terlambat',
            style: TextStyle(
              color: AppColors.attentionText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.stats, required this.today});

  final StudentStats? stats;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysInMonth = DateId.parse(DateId.endOfMonth(today)).day;
    final pending = ref
        .watch(journalOutboxProvider)
        .where((entry) => entry.status == OutboxStatus.pending)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Jurnal bulan ini',
                value: '${stats?.journalCountMonth ?? 0}/$daysInMonth',
                icon: Icons.edit_note,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Streak',
                value: '${stats?.streakCurrent ?? 0} hari',
                icon: Icons.local_fire_department,
                color: const Color(0xFFD98200),
              ),
            ),
          ],
        ),
        if (pending > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: AppColors.attentionText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pending jurnal menunggu sinyal untuk dikirim.',
                    style: const TextStyle(color: AppColors.attentionText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NewComments extends ConsumerWidget {
  const _NewComments({required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(unreadJournalsProvider(programId)).value ?? const <Journal>[];
    if (unread.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble, size: 18, color: AppColors.blue),
            const SizedBox(width: 8),
            Text(
              'Komentar baru dari guru',
              key: const Key('home-new-comments'),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final journal in unread)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text('Jurnal ${formatDateLong(journal.date)}'),
              subtitle: Text(
                journal.keyInformation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(Routes.studentJournal(programId, journal.date)),
            ),
          ),
      ],
    );
  }
}
