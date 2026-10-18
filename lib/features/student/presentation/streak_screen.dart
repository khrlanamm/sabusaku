import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/models/program.dart';
import '../../../core/models/school.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/periods.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/reading_calendar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/data/school_repository.dart';
import '../../ranking/domain/ranking.dart';
import '../data/student_repository.dart';
import '../domain/journal_filter.dart';

/// The student's streak: now and best (across books), how it is counted, and
/// a calendar of the days they read. Opened from the Streak card on Beranda.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  late String _month = DateId.monthOf(ref.read(wibClockProvider).today());

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(myStatsProvider).value;
    final programs = ref.watch(myProgramsProvider).value ?? const <Program>[];
    final settings = ref.watch(schoolProvider).value?.settings;
    final today = ref.watch(wibClockProvider).today();
    final theme = Theme.of(context);
    final dates = journalDatesOf(programs);
    final month = RankPeriod.month(_month);
    final previous = month.previous!;
    final next = month.next!;

    void openJournal(String date) {
      final program = programs.firstWhere(
        (program) => program.journalDates?.contains(date) ?? false,
      );
      context.push(Routes.studentJournal(program.id, date));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Streak')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCardRow(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Streak sekarang',
                  value: '${stats?.streakCurrent ?? 0} hari',
                  icon: Icons.local_fire_department,
                  color: context.palette.streak,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Streak terbaik',
                  value: '${stats?.streakBest ?? 0} hari',
                  icon: Icons.emoji_events_outlined,
                  color: context.palette.streak,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cara menghitung', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  for (final line in const [
                    'Setiap hari yang punya jurnal menambah streak.',
                    'Hari Minggu dan hari libur sekolah tidak memutus streak.',
                    'Selesai satu buku lalu mulai buku baru tidak memutus streak.',
                    'Streak putus bila ada hari sekolah tanpa jurnal sebelum hari ini. '
                        'Jurnal boleh diisi sampai 2 hari ke belakang.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(
                            child: Text(
                              line,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
              child: Column(
                children: [
                  PeriodStepper(
                    label: month.label,
                    onPrevious:
                        previous.from!.compareTo(
                              '${RankPeriod.earliestMonth}-01',
                            ) >=
                            0
                        ? () => setState(() => _month = previous.key!)
                        : null,
                    onNext: next.from!.compareTo(today) <= 0
                        ? () => setState(() => _month = next.key!)
                        : null,
                  ),
                  ReadingCalendar(
                    month: _month,
                    journalDates: dates,
                    today: today,
                    settings: settings ?? const SchoolSettings(),
                    onTapDay: openJournal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('streak-ranking'),
            onPressed: () => context.push(
              Routes.studentRankingWith(metric: RankMetric.streak.wire),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Lihat peringkat streak'),
          ),
        ],
      ),
    );
  }
}
