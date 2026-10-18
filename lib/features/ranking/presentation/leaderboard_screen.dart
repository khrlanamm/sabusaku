import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/time/periods.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/reading_calendar.dart' show PeriodStepper;
import '../../../core/widgets/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../teacher/data/teacher_repository.dart';
import '../../teacher/domain/student_scope.dart';
import '../../teacher/presentation/scope_filter_bar.dart';
import '../../teacher/presentation/student_tile.dart' show labelLine;
import '../data/ranking_repository.dart';
import '../domain/ranking.dart';

/// The school's leaderboard for one period, by books, streak or days read.
/// Students see every schoolmate's name, class and numbers (docs/07, 18 Oct
/// 2026) and can narrow it to their class or an extracurricular; teachers
/// narrow it with the dashboard's scope and open a student from a row.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, this.periodId, this.metric});

  /// The period to open on (a `leaderboards` document ID); this month when
  /// null.
  final String? periodId;
  final RankMetric? metric;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late RankPeriod _period;
  late RankMetric _metric;

  /// The student's own narrowing; teachers use the dashboard's scope.
  StudentScope _studentScope = const AllStudents();

  @override
  void initState() {
    super.initState();
    final today = ref.read(wibClockProvider).today();
    _period =
        RankPeriod.fromId(widget.periodId ?? '') ??
        RankPeriod.of(PeriodKind.month, today);
    _metric = widget.metric ?? RankMetric.books;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final isTeacher = session.role == UserRole.guru;
    final me = session.profile;
    final today = ref.watch(wibClockProvider).today();
    final board = ref.watch(leaderboardProvider(_period.id));
    final scope = isTeacher
        ? ref.watch(effectiveDashboardScopeProvider)
        : _studentScope;

    final earliest = RankPeriod.of(
      _period.kind,
      '${RankPeriod.earliestMonth}-01',
    );
    final previous = _period.previous;
    final next = _period.next;
    final canGoBack =
        previous != null && previous.to!.compareTo(earliest.from!) >= 0;
    final canGoForward = next != null && next.from!.compareTo(today) <= 0;

    final ranked = switch (board.value) {
      final value? => rankEntries(
        value.entries.where(
          (entry) => scope.matches(entry.classId, entry.extracurriculars, me),
        ),
        _metric,
      ),
      null => const <RankedEntry>[],
    };
    final mine = isTeacher
        ? null
        : ranked.where((row) => row.entry.studentId == session.uid).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Peringkat')),
      bottomNavigationBar: mine == null
          ? null
          : _MyRankBar(row: mine, metric: _metric, of: ranked.length),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final kind in PeriodKind.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('rank-period-${kind.name}'),
                      label: Text(kind.label),
                      selected: _period.kind == kind,
                      onSelected: (_) =>
                          setState(() => _period = RankPeriod.of(kind, today)),
                    ),
                  ),
              ],
            ),
          ),
          if (_period.kind != PeriodKind.all)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PeriodStepper(
                label: _period.label,
                onPrevious: canGoBack
                    ? () => setState(() => _period = previous)
                    : null,
                onNext: canGoForward
                    ? () => setState(() => _period = next)
                    : null,
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SegmentedButton<RankMetric>(
              key: const Key('rank-metric'),
              showSelectedIcon: false,
              segments: [
                for (final metric in RankMetric.values)
                  ButtonSegment(
                    value: metric,
                    label: Text(metric.label, maxLines: 1),
                  ),
              ],
              selected: {_metric},
              onSelectionChanged: (selected) =>
                  setState(() => _metric = selected.first),
            ),
          ),
          if (isTeacher)
            const ScopeFilterBar(padding: EdgeInsets.symmetric(horizontal: 16))
          else
            _StudentScopeBar(
              me: me,
              scope: _studentScope,
              onChanged: (scope) => setState(() => _studentScope = scope),
            ),
          Expanded(
            child: AsyncView(
              value: board,
              onRetry: () => ref.invalidate(leaderboardProvider(_period.id)),
              data: (value) => ranked.isEmpty
                  ? EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'Belum ada data periode ini',
                      message: value.entries.isEmpty
                          ? 'Peringkat terisi begitu ada jurnal atau buku selesai.'
                          : 'Tidak ada siswa di pilihan ini.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: ranked.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == ranked.length) {
                          return _Footer(
                            metric: _metric,
                            updatedAt: value.updatedAt,
                          );
                        }
                        final row = ranked[index];
                        return _RankTile(
                          row: row,
                          metric: _metric,
                          highlighted: row.entry.studentId == session.uid,
                          onTap: isTeacher
                              ? () => context.push(
                                  Routes.teacherStudent(row.entry.studentId),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentScopeBar extends StatelessWidget {
  const _StudentScopeBar({
    required this.me,
    required this.scope,
    required this.onChanged,
  });

  final AppUser me;
  final StudentScope scope;
  final ValueChanged<StudentScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final classId = me.classId;
    final options = <(String, StudentScope)>[
      ('Sekolah', const AllStudents()),
      if (classId != null) ('Kelas $classId', ClassScope(classId)),
      for (final label in me.extracurriculars)
        (label, ExtracurricularScope(label)),
    ];
    if (options.length == 1) return const SizedBox(height: 4);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (label, option) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: scope == option,
                onSelected: (_) => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

/// "3 buku", "12 hari".
String rankValueText(RankMetric metric, int value) => switch (metric) {
  RankMetric.books => '$value buku',
  RankMetric.streak || RankMetric.days => '$value hari',
};

/// Gold, silver and bronze for the first three ranks.
(Color text, Color tint)? medalColors(BuildContext context, int rank) {
  final palette = context.palette;
  return switch (rank) {
    1 => (palette.goldText, palette.goldTint),
    2 => (palette.silverText, palette.silverTint),
    3 => (palette.bronzeText, palette.bronzeTint),
    _ => null,
  };
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 36});

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = medalColors(context, rank);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal?.$2 ?? theme.colorScheme.surfaceContainerHighest,
      ),
      child: medal == null
          ? Text(
              '$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: size * 0.42, color: medal.$1),
                Text(
                  '$rank',
                  style: TextStyle(
                    color: medal.$1,
                    fontSize: size * 0.3,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.row,
    required this.metric,
    required this.highlighted,
    this.onTap,
  });

  final RankedEntry row;
  final RankMetric metric;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = row.entry;
    final others = [
      for (final other in RankMetric.values)
        if (other != metric) other.describe(entry.valueOf(other)),
    ];
    return Card(
      key: ValueKey('rank-${entry.studentId}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: highlighted ? context.palette.infoTint : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            children: [
              RankBadge(rank: row.rank),
              const SizedBox(width: 10),
              UserAvatar(name: entry.name, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highlighted ? '${entry.name} (kamu)' : entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      labelLine(entry.classId, entry.extracurriculars),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      others.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rankValueText(metric, entry.valueOf(metric)),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRankBar extends StatelessWidget {
  const _MyRankBar({required this.row, required this.metric, required this.of});

  final RankedEntry row;
  final RankMetric metric;
  final int of;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            key: const Key('rank-mine'),
            children: [
              RankBadge(rank: row.rank, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Posisimu #${row.rank} dari $of',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                rankValueText(metric, row.entry.valueOf(metric)),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.metric, required this.updatedAt});

  final RankMetric metric;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updated = updatedAt == null
        ? null
        : DateFormat(
            'd MMM y, HH.mm',
            'id_ID',
          ).format(WibClock.wibOf(updatedAt!));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        [
          '${metric.description}. Nilai sama diurutkan menurut '
              '${metric.order.skip(1).map((other) => other.label.toLowerCase()).join(', lalu ')}.',
          if (updated != null) 'Diperbarui $updated WIB.',
        ].join(' '),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
