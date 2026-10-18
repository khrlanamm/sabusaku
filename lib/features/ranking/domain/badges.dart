import '../../../core/models/program.dart';

/// What a badge counts.
enum BadgeKind { books, streak, journals, onTime, reviews }

/// An achievement a student earns by reading (docs/07, 18 Oct 2026). Worked
/// out on the device from data the viewer can already read, for the student
/// and for their teachers alike; nothing is stored.
class BadgeDef {
  const BadgeDef(this.id, this.kind, this.target, this.title, this.description);

  final String id;
  final BadgeKind kind;
  final int target;
  final String title;
  final String description;
}

const badgeDefs = <BadgeDef>[
  BadgeDef('buku-1', BadgeKind.books, 1, 'Buku pertama', 'Selesaikan 1 buku'),
  BadgeDef('buku-3', BadgeKind.books, 3, 'Rajin membaca', 'Selesaikan 3 buku'),
  BadgeDef('buku-6', BadgeKind.books, 6, 'Kutu buku', 'Selesaikan 6 buku'),
  BadgeDef(
    'buku-12',
    BadgeKind.books,
    12,
    'Sahabat pustaka',
    'Selesaikan 12 buku',
  ),
  BadgeDef('streak-7', BadgeKind.streak, 7, 'Seminggu penuh', 'Streak 7 hari'),
  BadgeDef('streak-14', BadgeKind.streak, 14, 'Dua pekan', 'Streak 14 hari'),
  BadgeDef(
    'streak-30',
    BadgeKind.streak,
    30,
    'Sebulan tanpa putus',
    'Streak 30 hari',
  ),
  BadgeDef(
    'jurnal-30',
    BadgeKind.journals,
    30,
    'Pencatat tekun',
    'Tulis 30 jurnal',
  ),
  BadgeDef(
    'jurnal-100',
    BadgeKind.journals,
    100,
    'Seratus catatan',
    'Tulis 100 jurnal',
  ),
  BadgeDef(
    'jurnal-200',
    BadgeKind.journals,
    200,
    'Penulis jurnal',
    'Tulis 200 jurnal',
  ),
  BadgeDef(
    'tepat-waktu',
    BadgeKind.onTime,
    1,
    'Tepat waktu',
    'Selesaikan buku sebelum target, tanpa perpanjangan',
  ),
  BadgeDef(
    'pengulas',
    BadgeKind.reviews,
    3,
    'Pengulas',
    'Tulis ulasan akhir untuk 3 buku',
  ),
];

typedef BadgeProgress = ({BadgeDef badge, int value});

extension BadgeProgressState on BadgeProgress {
  bool get earned => value >= badge.target;

  /// 0–1, for a progress bar.
  double get fraction => (value / badge.target).clamp(0, 1).toDouble();
}

/// Every badge with the student's progress towards it. [bestStreak] is the
/// student's longest streak across books (`studentStats.streakBest`).
List<BadgeProgress> badgesFor({
  required List<Program> programs,
  required int bestStreak,
}) {
  final completed = programs
      .where((program) => program.status == ProgramStatus.completed)
      .toList();
  int valueOf(BadgeKind kind) => switch (kind) {
    BadgeKind.books => completed.length,
    BadgeKind.streak => bestStreak,
    BadgeKind.journals => programs.fold(
      0,
      (total, program) => total + program.journalCount,
    ),
    BadgeKind.onTime =>
      completed
          .where(
            (program) =>
                !program.extended &&
                program.completedDate != null &&
                program.completedDate!.compareTo(program.targetDate) <= 0,
          )
          .length,
    BadgeKind.reviews =>
      completed
          .where((program) => (program.finalReflection ?? '').trim().isNotEmpty)
          .length,
  };
  return [
    for (final badge in badgeDefs) (badge: badge, value: valueOf(badge.kind)),
  ];
}
