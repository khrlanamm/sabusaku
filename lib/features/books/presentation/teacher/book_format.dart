import 'package:intl/intl.dart';

import '../../domain/catalog_book.dart';

/// Indonesian labels of the catalog fields, in the order they are shown.
const bookFieldLabels = <String, String>{
  'title': 'Judul',
  'subtitle': 'Subjudul',
  'authors': 'Penulis',
  'pageCount': 'Jumlah halaman',
  'coverUrl': 'Cover',
  'publisher': 'Penerbit',
  'publishedYear': 'Tahun terbit',
  'isbn13': 'ISBN-13',
  'isbn10': 'ISBN-10',
  'categories': 'Kategori',
  'description': 'Sinopsis',
  'status': 'Status',
  'duplicateOf': 'Duplikat dari',
  'deleteReason': 'Alasan hapus',
};

String bookFieldLabel(String field) => bookFieldLabels[field] ?? field;

/// Fields in display order: known ones first, unknown ones after, sorted.
List<String> orderedFields(Iterable<String> fields) {
  final known = [
    for (final field in bookFieldLabels.keys)
      if (fields.contains(field)) field,
  ];
  final rest = fields.where((f) => !bookFieldLabels.containsKey(f)).toList()
    ..sort();
  return [...known, ...rest];
}

/// A field value as one line of text; empty values become "—".
String formatBookValue(String field, Object? value, {int maxLength = 140}) {
  final text = switch (value) {
    null => '',
    final List<Object?> list => list.whereType<Object>().join(', '),
    final String s when field == 'status' =>
      s == 'deleted' ? 'Dihapus' : 'Aktif',
    final Object other => other.toString(),
  }.trim();
  if (text.isEmpty) return '—';
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength).trimRight()}…';
}

/// The current value of [field] on [book], shaped like the stored field.
Object? bookFieldValue(CatalogBook book, String field) => switch (field) {
  'title' => book.title,
  'subtitle' => book.subtitle,
  'authors' => book.authors,
  'publisher' => book.publisher,
  'publishedYear' => book.publishedYear,
  'isbn13' => book.isbn13,
  'isbn10' => book.isbn10,
  'pageCount' => book.pageCount,
  'categories' => book.categories,
  'description' => book.description,
  'coverUrl' => book.coverUrl,
  _ => null,
};

/// "Sari Wulandari · SMA Negeri 1 Sukodadi", or "Impor awal".
String actorLine(BookActor? actor) {
  if (actor == null) return 'Tidak diketahui';
  final name = actor.name.isEmpty
      ? (actor.kind == 'import' ? 'Impor awal' : 'Penanggung jawab')
      : actor.name;
  final school = actor.schoolName ?? actor.schoolId;
  return school == null || school.isEmpty ? name : '$name · $school';
}

/// "baru saja", "5 menit lalu", "3 jam lalu", "kemarin", "4 hari lalu",
/// otherwise the date ("12 Okt 2026").
String relativeTime(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(at);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
  if (diff.inDays < 1) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return DateFormat('d MMM yyyy', 'id_ID').format(at.toLocal());
}

/// Full date and time for banners: "16 Oktober 2026, 10.42".
String fullDateTime(DateTime? at) => at == null
    ? ''
    : DateFormat("d MMMM yyyy, HH.mm", 'id_ID').format(at.toLocal());

/// "Ditulis 3 siswa · SMA Negeri 1 Sukodadi, SMA Uji".
String suggestionSourceLine(int count, Iterable<String> schools) {
  final names = schools.where((s) => s.isNotEmpty).toSet().toList();
  final who = '$count siswa';
  if (names.isEmpty) return 'Dari $who';
  final shown = names.take(2).join(', ');
  final more = names.length > 2 ? ' +${names.length - 2} sekolah' : '';
  return 'Dari $who · $shown$more';
}
