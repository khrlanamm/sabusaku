import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/models/school.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/periods.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/journal_list.dart';
import '../../../core/widgets/journal_view.dart';
import '../../../core/widgets/reading_calendar.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/school_repository.dart';
import '../data/student_repository.dart';
import '../domain/journal_filter.dart';
import 'program_detail_header.dart';

/// "Riwayat Jurnal" tab: the journals of every book, month by month, narrowed
/// to one book, a month or a date range, newest or oldest first; or a
/// calendar of the days the student read.
class JournalHistoryTab extends ConsumerStatefulWidget {
  const JournalHistoryTab({super.key});

  @override
  ConsumerState<JournalHistoryTab> createState() => _JournalHistoryTabState();
}

class _JournalHistoryTabState extends ConsumerState<JournalHistoryTab> {
  bool _calendar = false;
  late String _calendarMonth = DateId.monthOf(
    ref.read(wibClockProvider).today(),
  );

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeProgramProvider);
    final programs = ref.watch(myProgramsProvider);
    final filter = ref.watch(journalFilterStateProvider);
    final today = ref.watch(wibClockProvider).today();

    final Widget body;
    if (programs.isLoading && !programs.hasValue) {
      body = const SkeletonList();
    } else if (programs.hasError && !programs.hasValue) {
      body = ErrorState(
        error: programs.error!,
        onRetry: () => ref.invalidate(myProgramsProvider),
      );
    } else if (programs.value!.isEmpty) {
      body = EmptyState(
        icon: Icons.edit_note,
        title: 'Belum ada jurnal',
        message: 'Mulai satu buku, lalu catat bacaanmu setiap hari.',
        action: FilledButton(
          onPressed: () => context.go(Routes.studentBook),
          child: const Text('Mulai Buku'),
        ),
      );
    } else {
      final all = programs.value!;
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                key: const Key('journals-view'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.view_list_outlined),
                    label: Text('Daftar'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('Kalender'),
                  ),
                ],
                selected: {_calendar},
                onSelectionChanged: (selected) =>
                    setState(() => _calendar = selected.first),
              ),
            ),
          ),
          _FilterBar(
            filter: filter,
            programs: all,
            today: today,
            showRange: !_calendar,
          ),
          Expanded(
            child: _calendar
                ? _CalendarView(
                    month: _calendarMonth,
                    programs: all,
                    filter: filter,
                    today: today,
                    onMonthChanged: (month) =>
                        setState(() => _calendarMonth = month),
                  )
                : _MonthList(programs: all, filter: filter, today: today),
          ),
        ],
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

String _rangeLabel(JournalRange range) => switch (range) {
  AllJournals() => 'Semua waktu',
  MonthJournals(:final month) => formatMonth(month),
  DateRangeJournals(:final from, :final to) =>
    '${formatDayMonth(from)} – ${formatDateShort(to)}',
};

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.filter,
    required this.programs,
    required this.today,
    required this.showRange,
  });

  final JournalFilter filter;
  final List<Program> programs;
  final String today;
  final bool showRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalFilterStateProvider.notifier);
    final selected = programs
        .where((program) => program.id == filter.programId)
        .firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    Future<void> pickMonth() async {
      final months = journalMonths(
        programs,
        filter.copyWith(range: const AllJournals()),
        today,
      );
      final month = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => ListView(
          shrinkWrap: true,
          children: [
            for (final entry in months)
              ListTile(
                title: Text(formatMonth(entry.month)),
                trailing: entry.count == null
                    ? null
                    : Text('${entry.count} jurnal'),
                onTap: () => Navigator.of(sheetContext).pop(entry.month),
              ),
          ],
        ),
      );
      if (month == null) return;
      notifier.set(filter.copyWith(range: MonthJournals(month)));
    }

    Future<void> pickDates() async {
      final range = filter.range;
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateId.parse('${RankPeriod.earliestMonth}-01'),
        lastDate: DateId.parse(today),
        initialDateRange: range is DateRangeJournals
            ? DateTimeRange(
                start: DateId.parse(range.from),
                end: DateId.parse(range.to),
              )
            : null,
        helpText: 'Jurnal antara',
        saveText: 'Terapkan',
      );
      if (picked == null) return;
      notifier.set(
        filter.copyWith(
          range: DateRangeJournals(
            DateId.format(picked.start),
            DateId.format(picked.end),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          PopupMenuButton<String>(
            key: const Key('journals-book'),
            tooltip: 'Buku',
            initialValue: filter.programId ?? '',
            onSelected: (id) => notifier.set(
              filter.copyWith(programId: () => id.isEmpty ? null : id),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Semua buku')),
              for (final program in programs)
                PopupMenuItem(
                  value: program.id,
                  child: Text(
                    '${program.book.title} · ${formatMonth(program.startDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            child: Chip(
              avatar: Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: selected == null ? null : scheme.primary,
              ),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  selected?.book.title ?? 'Semua buku',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              backgroundColor: selected == null
                  ? null
                  : scheme.secondaryContainer,
            ),
          ),
          if (showRange) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              key: const Key('journals-range'),
              tooltip: 'Rentang',
              onSelected: (choice) {
                switch (choice) {
                  case 'all':
                    notifier.set(filter.copyWith(range: const AllJournals()));
                  case 'this':
                    notifier.set(
                      filter.copyWith(
                        range: MonthJournals(DateId.monthOf(today)),
                      ),
                    );
                  case 'month':
                    pickMonth();
                  case 'dates':
                    pickDates();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'all', child: Text('Semua waktu')),
                PopupMenuItem(value: 'this', child: Text('Bulan ini')),
                PopupMenuItem(value: 'month', child: Text('Pilih bulan…')),
                PopupMenuItem(value: 'dates', child: Text('Rentang tanggal…')),
              ],
              child: Chip(
                avatar: Icon(
                  Icons.date_range,
                  size: 18,
                  color: filter.range is AllJournals ? null : scheme.primary,
                ),
                label: Text(_rangeLabel(filter.range)),
                backgroundColor: filter.range is AllJournals
                    ? null
                    : scheme.secondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              key: const Key('journals-order'),
              avatar: Icon(
                filter.oldestFirst ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
              ),
              label: Text(filter.oldestFirst ? 'Terlama' : 'Terbaru'),
              onPressed: () => notifier.set(
                filter.copyWith(oldestFirst: !filter.oldestFirst),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  const _MonthList({
    required this.programs,
    required this.filter,
    required this.today,
  });

  final List<Program> programs;
  final JournalFilter filter;
  final String today;

  @override
  Widget build(BuildContext context) {
    final months = journalMonths(programs, filter, today);
    if (months.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Tidak ada jurnal',
        message: 'Tidak ada jurnal di rentang dan buku ini.',
      );
    }
    // One month at a time: a month's journals are read only when it scrolls
    // into view.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: months.length,
      itemBuilder: (_, index) => _MonthSection(
        month: months[index],
        programs: programs,
        filter: filter,
      ),
    );
  }
}

class _MonthSection extends ConsumerWidget {
  const _MonthSection({
    required this.month,
    required this.programs,
    required this.filter,
  });

  final JournalMonth month;
  final List<Program> programs;
  final JournalFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journals = ref.watch(
      myJournalsBetweenProvider(month.from, month.to, filter.programId),
    );
    final titles = {
      for (final program in programs) program.id: program.book.title,
    };
    final showTitles = filter.programId == null && programs.length > 1;
    final count = journals.value?.length ?? month.count;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              '${formatMonth(month.month)}${count == null ? '' : ' · $count jurnal'}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AsyncView<List<Journal>>(
            // Keep showing the month while it reloads after a book changes
            // (a new journal updates its `journalDates`).
            value: journals.hasValue
                ? AsyncData(journals.requireValue)
                : journals,
            onRetry: () => ref.invalidate(
              myJournalsBetweenProvider(month.from, month.to, filter.programId),
            ),
            loading: SkeletonList(items: math.min(month.count ?? 2, 3)),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  'Tidak ada jurnal.',
                  style: theme.textTheme.bodySmall,
                );
              }
              final ordered = filter.oldestFirst ? items.reversed : items;
              return Column(
                children: [
                  for (final journal in ordered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: JournalListTile(
                        journal: journal,
                        bookTitle: showTitles
                            ? titles[journal.programId]
                            : null,
                        onTap: () => context.push(
                          Routes.studentJournal(
                            journal.programId,
                            journal.date,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  const _CalendarView({
    required this.month,
    required this.programs,
    required this.filter,
    required this.today,
    required this.onMonthChanged,
  });

  final String month;
  final List<Program> programs;
  final JournalFilter filter;
  final String today;
  final ValueChanged<String> onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(schoolProvider).value?.settings;
    final books = [
      for (final program in programs)
        if (filter.programId == null || program.id == filter.programId) program,
    ];
    final period = RankPeriod.month(month);
    final previous = period.previous!;
    final next = period.next!;
    final first = programs
        .map((program) => DateId.monthOf(program.startDate))
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);

    void openDay(String date) {
      final program = books.firstWhere(
        (program) => program.journalDates?.contains(date) ?? false,
      );
      context.push(Routes.studentJournal(program.id, date));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
            child: Column(
              children: [
                PeriodStepper(
                  label: period.label,
                  onPrevious: previous.key!.compareTo(first) >= 0
                      ? () => onMonthChanged(previous.key!)
                      : null,
                  onNext: next.from!.compareTo(today) <= 0
                      ? () => onMonthChanged(next.key!)
                      : null,
                ),
                ReadingCalendar(
                  month: month,
                  journalDates: journalDatesOf(books),
                  today: today,
                  settings: settings ?? const SchoolSettings(),
                  onTapDay: openDay,
                ),
              ],
            ),
          ),
        ),
        _MonthSection(
          month: (
            month: month,
            from: period.from!,
            to: period.to!,
            count: null,
          ),
          programs: programs,
          filter: filter,
        ),
      ],
    );
  }
}

/// One past or current book: its details, then its journals. Opened from
/// the reading history.
class ProgramJournalsScreen extends ConsumerWidget {
  const ProgramJournalsScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider(programId));
    return Scaffold(
      appBar: AppBar(title: Text(program.value?.book.title ?? 'Buku')),
      body: AsyncView<Program?>(
        value: program,
        data: (data) => data == null
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Buku tidak ditemukan',
              )
            : JournalList(
                program: data,
                header: ProgramDetailHeader(program: data),
                onOpen: (journal) =>
                    context.push(Routes.studentJournal(data.id, journal.date)),
              ),
      ),
    );
  }
}
