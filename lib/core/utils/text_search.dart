/// Text normalisation for book search. Must stay in sync with
/// functions/src/domain/search.ts.
library;

const _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
};

final _nonWord = RegExp(r'[^a-z0-9]+');

/// Lower case, accents removed, anything but letters and digits turned into
/// single spaces: `"Bumi Manusia: Edisi Revisi"` → `"bumi manusia edisi revisi"`.
String normalizeSearchText(String raw) {
  final lower = raw.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(_nonWord, ' ').trim();
}

/// Words of [text] after normalisation.
List<String> searchWords(String text) {
  final normal = normalizeSearchText(text);
  return normal.isEmpty ? const [] : normal.split(' ');
}

/// True when every word of [query] is the start of some word of [text].
bool matchesQuery(String text, String query) {
  final words = searchWords(text);
  final wanted = searchWords(query);
  if (wanted.isEmpty) return true;
  return wanted.every((q) => words.any((w) => w.startsWith(q)));
}

/// Title and first author, normalised: the key that tells whether two
/// entries are the same book (catalog `searchKey`, suggestion dedupe).
String bookKey(String title, String firstAuthor) =>
    '${normalizeSearchText(title)}|${normalizeSearchText(firstAuthor)}';
