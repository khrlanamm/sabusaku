/// Class and extracurricular labels. Must stay in sync with
/// functions/src/domain/labels.ts.
library;

/// `X`, `XI` or `XII`, a hyphen, then one or two letters and up to two
/// digits: `XII-A1`, `X-G`, `X-G2`.
final classLabelPattern = RegExp(r'^(X|XI|XII)-[A-Z]{1,2}[0-9]{0,2}$');

const _gradePart = r'(XII|XLL|XIL|XLI|XI|XL|X|12|11|10)';

/// Grade and class separated by a hyphen or spaces: `12  A1`, `XI A4`.
final _separated = RegExp(
  '^$_gradePart\\s*[-\\s]\\s*([A-Z]{1,2})\\s*([0-9]{0,2})\$',
);

/// No separator (`XIIC2`, `XD`). The class letter cannot be I or L there,
/// otherwise `XII` alone would read as `XI-I`.
final _joined = RegExp('^$_gradePart([A-HJKM-Z][A-Z]?)([0-9]{0,2})\$');

const _grades = {
  'XII': 'XII', 'XLL': 'XII', 'XIL': 'XII', 'XLI': 'XII', '12': 'XII',
  'XI': 'XI', 'XL': 'XI', '11': 'XI',
  'X': 'X', '10': 'X',
};

/// Turns what people type (`12  A1`, `XIIC2`, `Xll-A1`, `XI A4`, `XD`) into
/// the canonical label (`XII-A1`, `XII-C2`, `XII-A1`, `XI-A4`, `X-D`).
/// Null when the text is not a class label.
String? normalizeClassLabel(String raw) {
  final text = raw.trim().toUpperCase();
  final match = _separated.firstMatch(text) ?? _joined.firstMatch(text);
  if (match == null) return null;
  final label = '${_grades[match[1]]}-${match[2]}${match[3]}';
  return classLabelPattern.hasMatch(label) ? label : null;
}

/// Sorts labels by grade (X, XI, XII), then by the rest.
int compareClassLabels(String a, String b) {
  int grade(String label) => switch (label.split('-').first) {
    'X' => 10,
    'XI' => 11,
    'XII' => 12,
    _ => 99,
  };
  final byGrade = grade(a).compareTo(grade(b));
  return byGrade != 0 ? byGrade : a.compareTo(b);
}

const minExtracurricularLength = 2;
const maxExtracurricularLength = 40;

/// Trims and collapses spaces; null when too short or too long.
String? normalizeExtracurricular(String raw) {
  final label = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (label.length < minExtracurricularLength ||
      label.length > maxExtracurricularLength) {
    return null;
  }
  return label;
}

/// Lower-case, trimmed address. Also the `members/{email}` document ID.
String normalizeEmail(String raw) => raw.trim().toLowerCase();

final _emailPattern = RegExp(r'^[^\s@/]+@[^\s@/]+\.[^\s@/]+$');

bool isValidEmail(String email) =>
    email.length <= 254 && _emailPattern.hasMatch(email);

const minPasswordLength = 8;

String? validateNewPassword(String? value) {
  if (value == null || value.length < minPasswordLength) {
    return 'Password minimal $minPasswordLength karakter';
  }
  if (value.length > 64) return 'Password maksimal 64 karakter';
  return null;
}
