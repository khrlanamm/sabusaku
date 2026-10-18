import 'package:flutter/foundation.dart';

import '../../../core/time/periods.dart';

/// What a leaderboard is sorted by. The tie-breakers match
/// functions/src/domain/ranking.ts (`RANK_ORDER`).
enum RankMetric {
  books('Buku', 'buku', 'Buku selesai'),
  streak('Streak', 'streak', 'Streak terpanjang'),
  days('Hari membaca', 'hari', 'Hari berjurnal');

  const RankMetric(this.label, this.wire, this.description);

  final String label;

  /// Its name in links (`?metrik=`).
  final String wire;
  final String description;

  static RankMetric fromWire(String? value) =>
      values.firstWhere((metric) => metric.wire == value, orElse: () => books);

  List<RankMetric> get order => switch (this) {
    books => const [books, days, streak],
    streak => const [streak, days, books],
    days => const [days, streak, books],
  };
}

/// One row of `leaderboards/{periodId}.entries` (docs/02 §3.17).
@immutable
class RankEntry {
  const RankEntry({
    required this.studentId,
    required this.name,
    this.classId,
    this.extracurriculars = const [],
    this.books = 0,
    this.streak = 0,
    this.days = 0,
  });

  factory RankEntry.fromMap(String studentId, Map<String, dynamic> data) =>
      RankEntry(
        studentId: studentId,
        name: data['name'] as String? ?? '',
        classId: data['classId'] as String?,
        extracurriculars: List<String>.from(
          data['extracurriculars'] as List? ?? const [],
        ),
        books: data['books'] as int? ?? 0,
        streak: data['streak'] as int? ?? 0,
        days: data['days'] as int? ?? 0,
      );

  final String studentId;
  final String name;
  final String? classId;
  final List<String> extracurriculars;
  final int books;
  final int streak;
  final int days;

  int valueOf(RankMetric metric) => switch (metric) {
    RankMetric.books => books,
    RankMetric.streak => streak,
    RankMetric.days => days,
  };
}

/// `schools/{schoolId}/leaderboards/{periodId}`; empty when the period has
/// no board yet.
@immutable
class Leaderboard {
  const Leaderboard({
    required this.period,
    this.entries = const [],
    this.updatedAt,
  });

  final RankPeriod period;
  final List<RankEntry> entries;
  final DateTime? updatedAt;
}

typedef RankedEntry = ({int rank, RankEntry entry});

/// [entries] sorted by [metric] and its tie-breakers, then by name, with
/// standard competition ranks (1, 2, 2, 4): equal on every number, equal rank.
List<RankedEntry> rankEntries(Iterable<RankEntry> entries, RankMetric metric) {
  int compareNumbers(RankEntry a, RankEntry b) {
    for (final key in metric.order) {
      final difference = b.valueOf(key) - a.valueOf(key);
      if (difference != 0) return difference;
    }
    return 0;
  }

  final sorted = [...entries]
    ..sort((a, b) {
      final byNumbers = compareNumbers(a, b);
      return byNumbers != 0
          ? byNumbers
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final ranked = <RankedEntry>[];
  for (final (index, entry) in sorted.indexed) {
    final tied = index > 0 && compareNumbers(sorted[index - 1], entry) == 0;
    ranked.add((rank: tied ? ranked.last.rank : index + 1, entry: entry));
  }
  return ranked;
}
