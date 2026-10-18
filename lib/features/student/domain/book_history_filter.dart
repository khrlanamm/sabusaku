import 'package:flutter/foundation.dart';

import '../../../core/models/program.dart';
import '../../../core/utils/text_search.dart';
import 'reading_rules.dart';

enum BookSort {
  newest('Terbaru'),
  oldest('Terlama'),
  title('Judul A–Z'),
  mostJournals('Jurnal terbanyak'),
  fastest('Tercepat selesai'),
  progress('Progres tertinggi');

  const BookSort(this.label);

  final String label;
}

/// What the student narrowed "Riwayat buku" to.
@immutable
class BookHistoryFilter {
  const BookHistoryFilter({
    this.query = '',
    this.status,
    this.from,
    this.to,
    this.distinct = false,
    this.sort = BookSort.newest,
  });

  /// Matched against title and author.
  final String query;

  /// Null for every status.
  final ProgramStatus? status;

  /// Books read at some point between [from] and [to] (inclusive).
  final String? from;
  final String? to;

  /// One row per book, however many times it was read.
  final bool distinct;
  final BookSort sort;

  bool get hasRange => from != null && to != null;

  /// Whether anything but the order narrows the list.
  bool get narrows =>
      query.trim().isNotEmpty || status != null || hasRange || distinct;

  BookHistoryFilter copyWith({
    String? query,
    ProgramStatus? Function()? status,
    (String, String)? Function()? range,
    bool? distinct,
    BookSort? sort,
  }) {
    final newRange = range == null
        ? (from == null ? null : (from!, to!))
        : range();
    return BookHistoryFilter(
      query: query ?? this.query,
      status: status == null ? this.status : status(),
      from: newRange?.$1,
      to: newRange?.$2,
      distinct: distinct ?? this.distinct,
      sort: sort ?? this.sort,
    );
  }
}

typedef BookHistoryItem = ({Program program, int timesRead});

/// The same book read twice is one book: the catalog ID when there is one,
/// otherwise the normalised title and author.
String bookKey(Book book) =>
    book.bookId ??
    '${normalizeSearchText(book.title)}|${normalizeSearchText(book.author)}';

/// [programs] narrowed and sorted by [filter]. With `distinct`, each book
/// appears once, as its most recent reading, counting how often it was read
/// among the matching programs.
List<BookHistoryItem> applyBookHistoryFilter(
  List<Program> programs,
  BookHistoryFilter filter,
  String today,
) {
  final words = normalizeSearchText(filter.query)
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();
  final matching = programs.where((program) {
    if (filter.status != null && program.status != filter.status) return false;
    if (filter.hasRange &&
        (program.startDate.compareTo(filter.to!) > 0 ||
            program.endDate(today).compareTo(filter.from!) < 0)) {
      return false;
    }
    if (words.isNotEmpty) {
      final text = normalizeSearchText(
        '${program.book.title} ${program.book.author}',
      );
      if (!words.every(text.contains)) return false;
    }
    return true;
  }).toList();

  final List<BookHistoryItem> items;
  if (filter.distinct) {
    final byBook = <String, List<Program>>{};
    for (final program in matching) {
      byBook.putIfAbsent(bookKey(program.book), () => []).add(program);
    }
    items = [
      for (final readings in byBook.values)
        (
          program: readings.reduce(
            (a, b) => a.startDate.compareTo(b.startDate) >= 0 ? a : b,
          ),
          timesRead: readings.length,
        ),
    ];
  } else {
    items = [for (final program in matching) (program: program, timesRead: 1)];
  }

  int? daysToFinish(Program program) => program.completedDate == null
      ? null
      : readingDays(
          startDate: program.startDate,
          endDate: program.completedDate!,
        );
  int newestFirst(BookHistoryItem a, BookHistoryItem b) =>
      b.program.startDate.compareTo(a.program.startDate);
  int compare(BookHistoryItem a, BookHistoryItem b) {
    switch (filter.sort) {
      case BookSort.newest:
        return newestFirst(a, b);
      case BookSort.oldest:
        return a.program.startDate.compareTo(b.program.startDate);
      case BookSort.title:
        return a.program.book.title.toLowerCase().compareTo(
          b.program.book.title.toLowerCase(),
        );
      case BookSort.mostJournals:
        return b.program.journalCount - a.program.journalCount;
      case BookSort.fastest:
        // Unfinished books go last.
        final (da, db) = (daysToFinish(a.program), daysToFinish(b.program));
        if (da == null || db == null) {
          return (da == null ? 1 : 0) - (db == null ? 1 : 0);
        }
        return da - db;
      case BookSort.progress:
        return b.program.percent - a.program.percent;
    }
  }

  return items..sort((a, b) {
    final result = compare(a, b);
    return result != 0 ? result : newestFirst(a, b);
  });
}
