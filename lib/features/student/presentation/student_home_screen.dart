import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/time/periods.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/notification_prompt.dart';
import '../../ranking/data/ranking_repository.dart';
import '../../ranking/domain/badges.dart';
import '../../ranking/domain/ranking.dart';
import '../data/journal_outbox.dart';
import '../data/student_repository.dart';
import '../domain/journal_filter.dart';
import 'outbox_notice.dart';
import 'program_history_tile.dart';

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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const NotificationPermissionPrompt(),
            const OutboxNotice(),
            AsyncView<Program?>(
              value: program,
              onRetry: () => ref.invalidate(activeProgramProvider),
              loading: const SkeletonList(items: 1, itemHeight: 200),
              data: (active) => active == null
                  ? const _NoBookCard()
                  : _BookCard(program: active, today: today),
            ),
            if (program.value case final active?) ...[
              const SizedBox(height: 20),
              _NewComments(programId: active.id),
            ],
            const SizedBox(height: 20),
            Text('Statistik', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            _Stats(stats: stats, today: today),
            const SizedBox(height: 20),
            const _RecentBooks(),
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
            Icon(
              Icons.menu_book,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                BookCover(
                  title: program.book.title,
                  coverUrl: program.book.coverUrl,
                  width: 72,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buku bulan ini',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  Icon(Icons.check_circle, color: context.palette.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jurnal hari ini sudah diisi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.palette.activeText,
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
        color: context.palette.attentionTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: context.palette.attentionText),
          SizedBox(width: 4),
          Text(
            'Terlambat',
            style: TextStyle(
              color: context.palette.attentionText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Six cards, each opening the page behind its number.
class _Stats extends ConsumerWidget {
  const _Stats({required this.stats, required this.today});

  final StudentStats? stats;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysInMonth = DateId.parse(DateId.endOfMonth(today)).day;
    final pending = ref
        .watch(journalOutboxProvider)
        .where((entry) => entry.status == OutboxStatus.pending)
        .length;
    final programs = ref.watch(myProgramsProvider).value ?? const <Program>[];
    final badges = badgesFor(
      programs: programs,
      bestStreak: stats?.streakBest ?? 0,
    );
    final month = RankPeriod.of(PeriodKind.month, today);
    final board = ref.watch(leaderboardProvider(month.id)).value;
    final uid = ref.watch(currentSessionProvider.select((s) => s.uid));
    final ranked = rankEntries(board?.entries ?? const [], RankMetric.books);
    final mine = ranked.where((row) => row.entry.studentId == uid).firstOrNull;

    void openJournals(JournalRange range) {
      ref
          .read(journalFilterStateProvider.notifier)
          .set(JournalFilter(range: range));
      context.go(Routes.studentJournals);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatCardRow(
          children: [
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-month'),
                label: 'Jurnal bulan ini',
                value: '${stats?.journalCountMonth ?? 0}/$daysInMonth',
                icon: Icons.edit_note,
                onTap: () => openJournals(MonthJournals(DateId.monthOf(today))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-streak'),
                label: 'Streak',
                value: '${stats?.streakCurrent ?? 0} hari',
                caption: 'Terbaik ${stats?.streakBest ?? 0} hari',
                icon: Icons.local_fire_department,
                color: context.palette.streak,
                onTap: () => context.push(Routes.studentStreak),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCardRow(
          children: [
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-books'),
                label: 'Buku selesai',
                value: '${stats?.booksCompleted ?? 0}',
                icon: Icons.menu_book,
                color: context.palette.success,
                onTap: () => context.push(
                  Routes.studentBookHistoryWith(status: 'selesai'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-journals'),
                label: 'Total jurnal',
                value: '${stats?.journalCountTotal ?? 0}',
                icon: Icons.history_edu,
                onTap: () => openJournals(const AllJournals()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatCardRow(
          children: [
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-rank'),
                label: 'Peringkat',
                value: mine == null ? '–' : '#${mine.rank}',
                caption: mine == null
                    ? 'Bulan ini, belum masuk'
                    : 'Bulan ini, dari ${ranked.length}',
                icon: Icons.leaderboard,
                color: context.palette.goldText,
                onTap: () => context.push(Routes.studentRanking),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                compact: true,
                key: const Key('home-stat-badges'),
                label: 'Lencana',
                value:
                    '${badges.where((progress) => progress.earned).length}'
                    '/${badges.length}',
                icon: Icons.workspace_premium,
                color: context.palette.info,
                onTap: () => context.push(Routes.studentBadges),
              ),
            ),
          ],
        ),
        if (pending > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: context.palette.attentionText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pending jurnal menunggu sinyal untuk dikirim.',
                    style: TextStyle(color: context.palette.attentionText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The three most recent books, and the way to all of them.
class _RecentBooks extends ConsumerWidget {
  const _RecentBooks();

  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(myProgramsProvider).value ?? const <Program>[];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Riwayat buku', style: theme.textTheme.titleMedium),
            ),
            if (programs.isNotEmpty)
              TextButton(
                key: const Key('home-book-history'),
                onPressed: () => context.push(Routes.studentBookHistory),
                child: Text('Lihat semua (${programs.length})'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (programs.isEmpty)
          Text(
            'Buku yang kamu mulai tampil di sini.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final program in programs.take(_shown))
            ProgramHistoryTile(
              program: program,
              onTap: () =>
                  context.push(Routes.studentProgramJournals(program.id)),
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
            Icon(
              Icons.chat_bubble,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
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
