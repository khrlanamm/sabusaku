import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/program.dart';
import 'package:sabusaku/features/ranking/domain/badges.dart';
import 'package:sabusaku/features/ranking/domain/ranking.dart';

RankEntry _entry(String id, int books, int streak, int days) => RankEntry(
  studentId: id,
  name: id,
  books: books,
  streak: streak,
  days: days,
);

Program _program(
  String id, {
  ProgramStatus status = ProgramStatus.completed,
  int journals = 10,
  bool extended = false,
  DateTime? completedAt,
  String? review,
}) => Program(
  id: id,
  studentId: 's',
  book: const Book(title: 'B', author: 'A', totalPages: 100),
  startDate: '2026-10-01',
  targetDate: '2026-10-31',
  extended: extended,
  status: status,
  journalCount: journals,
  completedAt: completedAt ?? DateTime.utc(2026, 10, 20, 3),
  finalReflection: review,
);

void main() {
  group('rankEntries', () {
    // Same table as functions/test/domain/ranking.test.ts.
    final entries = [
      _entry('a', 1, 5, 10),
      _entry('b', 2, 3, 8),
      _entry('c', 1, 5, 10),
      _entry('d', 1, 7, 12),
    ];

    Map<String, int> ranks(RankMetric metric) => {
      for (final ranked in rankEntries(entries, metric))
        ranked.entry.studentId: ranked.rank,
    };

    test('peringkat kompetisi dengan pemecah seri', () {
      expect(ranks(RankMetric.books), {'b': 1, 'd': 2, 'a': 3, 'c': 3});
      expect(ranks(RankMetric.streak), {'d': 1, 'a': 2, 'c': 2, 'b': 4});
      expect(ranks(RankMetric.days), {'d': 1, 'a': 2, 'c': 2, 'b': 4});
    });

    test('yang seri diurutkan menurut nama', () {
      expect(
        [
          for (final ranked in rankEntries(entries, RankMetric.books))
            ranked.entry.studentId,
        ],
        ['b', 'd', 'a', 'c'],
      );
    });

    test('metrik dari tautan', () {
      expect(RankMetric.fromWire('streak'), RankMetric.streak);
      expect(RankMetric.fromWire('hari'), RankMetric.days);
      expect(RankMetric.fromWire(null), RankMetric.books);
    });
  });

  group('lencana', () {
    int valueOf(List<BadgeProgress> badges, String id) =>
        badges.firstWhere((progress) => progress.badge.id == id).value;

    test('menghitung buku, jurnal, tepat waktu, dan ulasan', () {
      final badges = badgesFor(
        bestStreak: 9,
        programs: [
          _program('p1', review: 'Bagus'),
          // Finished after the target.
          _program(
            'p2',
            completedAt: DateTime.utc(2026, 11, 2, 3),
            review: ' ',
          ),
          _program('p3', extended: true),
          _program('p4', status: ProgramStatus.active, journals: 5),
        ],
      );
      expect(valueOf(badges, 'buku-1'), 3);
      expect(valueOf(badges, 'jurnal-30'), 35);
      expect(valueOf(badges, 'streak-7'), 9);
      expect(valueOf(badges, 'tepat-waktu'), 1);
      expect(valueOf(badges, 'pengulas'), 1);
      final earned = {
        for (final progress in badges)
          if (progress.earned) progress.badge.id,
      };
      expect(earned, {
        'buku-1',
        'buku-3',
        'jurnal-30',
        'streak-7',
        'tepat-waktu',
      });
    });

    test('siswa baru belum punya lencana', () {
      final badges = badgesFor(bestStreak: 0, programs: const []);
      expect(badges.where((progress) => progress.earned), isEmpty);
      expect(badges.first.fraction, 0);
    });
  });

  group('Program.mayHaveJournalsBetween', () {
    test('tepat bila journalDates ada', () {
      final program = _program('p').copyWith(journalDates: ['2026-10-05']);
      expect(
        program.mayHaveJournalsBetween(
          '2026-10-01',
          '2026-10-31',
          '2026-11-05',
        ),
        isTrue,
      );
      expect(
        program.mayHaveJournalsBetween(
          '2026-11-01',
          '2026-11-30',
          '2026-11-05',
        ),
        isFalse,
      );
    });

    test('dari tanggal buku bila belum diisi', () {
      final active = _program('p', status: ProgramStatus.active);
      expect(
        active.mayHaveJournalsBetween('2026-11-01', '2026-11-30', '2026-11-05'),
        isTrue,
      );
      final done = _program('p');
      expect(
        done.mayHaveJournalsBetween('2026-11-01', '2026-11-30', '2026-11-05'),
        isFalse,
      );
    });
  });
}
