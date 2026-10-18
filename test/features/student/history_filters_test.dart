import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/program.dart';
import 'package:sabusaku/features/student/domain/book_history_filter.dart';
import 'package:sabusaku/features/student/domain/journal_filter.dart';

Program _program(
  String id, {
  required String title,
  String? bookId,
  required String start,
  ProgramStatus status = ProgramStatus.completed,
  String? completed,
  int journals = 5,
  int page = 100,
  List<String>? dates,
}) => Program(
  id: id,
  studentId: 's',
  book: Book(
    title: title,
    author: 'Tere Liye',
    totalPages: 100,
    bookId: bookId,
  ),
  startDate: start,
  targetDate: start,
  status: status,
  completedAt: completed == null
      ? null
      : DateTime.parse('${completed}T03:00:00Z'),
  journalCount: journals,
  currentPage: page,
  journalDates: dates,
);

final _bumi1 = _program(
  'a',
  title: 'Bumi',
  bookId: 'bk1',
  start: '2026-07-01',
  status: ProgramStatus.stopped,
  page: 30,
);
final _bumi2 = _program(
  'b',
  title: 'Bumi',
  bookId: 'bk1',
  start: '2026-09-01',
  completed: '2026-09-20',
  journals: 15,
);
final _bulan = _program(
  'c',
  title: 'Bulan',
  start: '2026-08-01',
  completed: '2026-08-10',
  journals: 8,
);
final _laut = _program(
  'd',
  title: 'Laut Bercerita',
  start: '2026-10-01',
  status: ProgramStatus.active,
  page: 40,
  journals: 9,
);
final _all = [_laut, _bumi2, _bulan, _bumi1];

List<String> _ids(BookHistoryFilter filter) => [
  for (final item in applyBookHistoryFilter(_all, filter, '2026-10-18'))
    item.program.id,
];

void main() {
  group('riwayat buku', () {
    test('urutan bawaan terbaru', () {
      expect(_ids(const BookHistoryFilter()), ['d', 'b', 'c', 'a']);
    });

    test('status, pencarian, dan rentang tanggal', () {
      expect(_ids(const BookHistoryFilter(status: ProgramStatus.completed)), [
        'b',
        'c',
      ]);
      expect(_ids(const BookHistoryFilter(query: 'laut')), ['d']);
      expect(_ids(const BookHistoryFilter(query: 'tere bumi')), ['b', 'a']);
      // Read at some point in August: Bulan only.
      expect(
        _ids(const BookHistoryFilter(from: '2026-08-05', to: '2026-08-31')),
        ['c'],
      );
      // The active book counts as read until today.
      expect(
        _ids(const BookHistoryFilter(from: '2026-10-15', to: '2026-10-18')),
        ['d'],
      );
    });

    test('buku unik menampilkan bacaan terakhir dan berapa kali dibaca', () {
      final items = applyBookHistoryFilter(
        _all,
        const BookHistoryFilter(distinct: true),
        '2026-10-18',
      );
      expect(
        [for (final item in items) (item.program.id, item.timesRead)],
        [('d', 1), ('b', 2), ('c', 1)],
      );
    });

    test('urutan lain', () {
      expect(_ids(const BookHistoryFilter(sort: BookSort.oldest)), [
        'a',
        'c',
        'b',
        'd',
      ]);
      expect(_ids(const BookHistoryFilter(sort: BookSort.title)), [
        'c',
        'b',
        'a',
        'd',
      ]);
      expect(_ids(const BookHistoryFilter(sort: BookSort.mostJournals)), [
        'b',
        'd',
        'c',
        'a',
      ]);
      // Bulan took 10 days, Bumi 20; unfinished books last, newest first.
      expect(_ids(const BookHistoryFilter(sort: BookSort.fastest)), [
        'c',
        'b',
        'd',
        'a',
      ]);
      expect(_ids(const BookHistoryFilter(sort: BookSort.progress)).take(2), [
        'b',
        'c',
      ]);
    });

    test('kunci buku sama untuk judul yang ditulis berbeda', () {
      expect(
        bookKey(
          const Book(
            title: 'Laut  Bercerita!',
            author: 'Leila S. Chudori',
            totalPages: 10,
          ),
        ),
        bookKey(
          const Book(
            title: 'laut bercerita',
            author: 'Leila S Chudori',
            totalPages: 10,
          ),
        ),
      );
    });
  });

  group('bulan di riwayat jurnal', () {
    final withDates = [
      _program(
        'x',
        title: 'X',
        start: '2026-09-28',
        dates: ['2026-09-28', '2026-09-30', '2026-10-01', '2026-10-02'],
      ),
      _program(
        'y',
        title: 'Y',
        start: '2026-10-03',
        status: ProgramStatus.active,
        dates: ['2026-10-03'],
      ),
    ];

    test('semua waktu, terbaru dulu, dengan jumlah dari journalDates', () {
      final months = journalMonths(
        withDates,
        const JournalFilter(),
        '2026-10-18',
      );
      expect(
        [for (final m in months) (m.month, m.count)],
        [('2026-10', 3), ('2026-09', 2)],
      );
      expect(
        (months.first.from, months.first.to),
        ('2026-10-01', '2026-10-31'),
      );
    });

    test('satu buku, terlama dulu', () {
      final months = journalMonths(
        withDates,
        const JournalFilter(programId: 'x', oldestFirst: true),
        '2026-10-18',
      );
      expect(
        [for (final m in months) (m.month, m.count)],
        [('2026-09', 2), ('2026-10', 2)],
      );
    });

    test('rentang tanggal memotong bulan', () {
      final months = journalMonths(
        withDates,
        const JournalFilter(
          range: DateRangeJournals('2026-09-30', '2026-10-02'),
        ),
        '2026-10-18',
      );
      expect(
        [for (final m in months) (m.month, m.from, m.to, m.count)],
        [
          ('2026-10', '2026-10-01', '2026-10-02', 2),
          ('2026-09', '2026-09-30', '2026-09-30', 1),
        ],
      );
    });

    test('buku tanpa journalDates memakai bulan-bulan masa bacanya', () {
      final legacy = [
        _program('z', title: 'Z', start: '2026-08-20', completed: '2026-10-02'),
      ];
      final months = journalMonths(legacy, const JournalFilter(), '2026-10-18');
      expect(
        [for (final m in months) (m.month, m.count)],
        [('2026-10', null), ('2026-09', null), ('2026-08', null)],
      );
    });
  });
}
