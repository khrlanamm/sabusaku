import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/states.dart';
import '../data/student_repository.dart';
import '../domain/book_history_filter.dart';
import 'program_history_tile.dart';

/// Every book the student started, searchable and narrowed by status, by
/// when it was read, or to one row per book, in the order they pick.
/// Opened from "Lihat semua" on Beranda and from the Buku tab.
class BookHistoryScreen extends ConsumerStatefulWidget {
  const BookHistoryScreen({super.key, this.initialStatus});

  /// `aktif`, `selesai` or `dihentikan` (from a link), or null for all.
  final String? initialStatus;

  @override
  ConsumerState<BookHistoryScreen> createState() => _BookHistoryScreenState();
}

/// Status names in links.
const _statusParam = {
  'aktif': ProgramStatus.active,
  'selesai': ProgramStatus.completed,
  'dihentikan': ProgramStatus.stopped,
};

class _BookHistoryScreenState extends ConsumerState<BookHistoryScreen> {
  late BookHistoryFilter _filter = BookHistoryFilter(
    status: _statusParam[widget.initialStatus],
  );
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickRange(String today) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateId.parse('2026-01-01'),
      lastDate: DateId.parse(today),
      initialDateRange: _filter.hasRange
          ? DateTimeRange(
              start: DateId.parse(_filter.from!),
              end: DateId.parse(_filter.to!),
            )
          : null,
      helpText: 'Dibaca antara',
      saveText: 'Terapkan',
    );
    if (picked == null) return;
    setState(
      () => _filter = _filter.copyWith(
        range: () => (DateId.format(picked.start), DateId.format(picked.end)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(myProgramsProvider);
    final today = ref.watch(wibClockProvider).today();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat buku')),
      body: AsyncView<List<Program>>(
        value: programs,
        onRetry: () => ref.invalidate(myProgramsProvider),
        data: (all) {
          final items = applyBookHistoryFilter(all, _filter, today);
          final finished = all
              .where((program) => program.status == ProgramStatus.completed)
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextField(
                key: const Key('book-history-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul atau penulis',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _filter.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus',
                          onPressed: () {
                            _search.clear();
                            setState(
                              () => _filter = _filter.copyWith(query: ''),
                            );
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) =>
                    setState(() => _filter = _filter.copyWith(query: value)),
              ),
              const SizedBox(height: 10),
              _ChipRow(
                children: [
                  for (final status in [null, ...ProgramStatus.values])
                    ChoiceChip(
                      key: Key('book-history-status-${status?.wire ?? 'all'}'),
                      label: Text(status?.label ?? 'Semua'),
                      selected: _filter.status == status,
                      onSelected: (_) => setState(
                        () => _filter = _filter.copyWith(status: () => status),
                      ),
                    ),
                ],
              ),
              _ChipRow(
                children: [
                  InputChip(
                    key: const Key('book-history-range'),
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _filter.hasRange
                          ? '${formatDateShort(_filter.from!)} – '
                                '${formatDateShort(_filter.to!)}'
                          : 'Rentang tanggal',
                    ),
                    selected: _filter.hasRange,
                    showCheckmark: false,
                    onPressed: () => _pickRange(today),
                    onDeleted: _filter.hasRange
                        ? () => setState(
                            () => _filter = _filter.copyWith(range: () => null),
                          )
                        : null,
                  ),
                  FilterChip(
                    key: const Key('book-history-distinct'),
                    label: const Text('Buku unik'),
                    selected: _filter.distinct,
                    onSelected: (value) => setState(
                      () => _filter = _filter.copyWith(distinct: value),
                    ),
                  ),
                  PopupMenuButton<BookSort>(
                    key: const Key('book-history-sort'),
                    tooltip: 'Urutkan',
                    initialValue: _filter.sort,
                    onSelected: (sort) =>
                        setState(() => _filter = _filter.copyWith(sort: sort)),
                    itemBuilder: (_) => [
                      for (final sort in BookSort.values)
                        PopupMenuItem(value: sort, child: Text(sort.label)),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.sort, size: 18),
                      label: Text(_filter.sort.label),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _filter.narrows
                    ? '${items.length} dari ${all.length} buku'
                    : '${all.length} buku · $finished selesai',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              if (all.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum ada buku',
                  message: 'Buku yang kamu mulai tampil di sini.',
                )
              else if (items.isEmpty)
                const EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Tidak ada buku yang cocok',
                  message: 'Ubah pencarian atau filter di atas.',
                )
              else
                for (final item in items)
                  ProgramHistoryTile(
                    program: item.program,
                    timesRead: item.timesRead,
                    onTap: () => context.push(
                      Routes.studentProgramJournals(item.program.id),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// One line of chips that scrolls sideways.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: children[index]),
      ),
    );
  }
}
