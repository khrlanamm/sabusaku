/// Client-side copies of the business rules that the security rules enforce
/// (PRD BR-3…BR-9), so a student gets a clear message before the server has
/// to refuse a write. The server remains the authority.
library;

import '../../../core/time/date_id.dart';

// ---------- Journal ----------

/// A journal may be dated today or up to this many days back (BR-3).
const maxJournalBackDays = 2;

/// A journal may be edited or deleted until the end of the day after its
/// date (BR-4).
const journalEditWindowDays = 1;

const keyInformationMinLength = 30;
const journalTextMaxLength = 1000;

/// Dates a journal can be written for, newest first: today back to two days
/// ago, never before the book was started.
List<String> journalDateChoices({
  required String today,
  required String programStartDate,
}) => [
  for (var back = 0; back <= maxJournalBackDays; back++)
    if (DateId.addDays(today, -back).compareTo(programStartDate) >= 0)
      DateId.addDays(today, -back),
];

bool canEditJournal({required String journalDate, required String today}) {
  final age = DateId.daysBetween(journalDate, today);
  return age >= 0 && age <= journalEditWindowDays;
}

/// The reader continues where they stopped; a finished book stays on the
/// last page.
int defaultPageStart({required int currentPage, required int totalPages}) =>
    (currentPage + 1).clamp(1, totalPages);

String? validatePageStart(String? input) {
  final value = int.tryParse(input?.trim() ?? '');
  if (value == null) return 'Isi dengan angka';
  if (value < 1) return 'Minimal halaman 1';
  return null;
}

String? validatePageEnd(
  String? input, {
  required String? pageStartInput,
  required int totalPages,
}) {
  final value = int.tryParse(input?.trim() ?? '');
  if (value == null) return 'Isi dengan angka';
  final start = int.tryParse(pageStartInput?.trim() ?? '');
  if (start != null && value < start) {
    return 'Tidak boleh kurang dari halaman awal';
  }
  if (value > totalPages) return 'Buku ini hanya $totalPages halaman';
  return null;
}

String? validateKeyInformation(String? input) {
  final length = input?.trim().length ?? 0;
  if (length < keyInformationMinLength) {
    return 'Minimal $keyInformationMinLength karakter '
        '(kurang ${keyInformationMinLength - length})';
  }
  if (length > journalTextMaxLength) {
    return 'Maksimal $journalTextMaxLength karakter';
  }
  return null;
}

String? validateOptionalText(String? input) =>
    (input?.trim().length ?? 0) > journalTextMaxLength
    ? 'Maksimal $journalTextMaxLength karakter'
    : null;

// ---------- Book ----------

String? validateBookTitle(String? input) {
  final length = input?.trim().length ?? 0;
  return length < 2 || length > 120 ? 'Judul 2–120 karakter' : null;
}

String? validateBookAuthor(String? input) {
  final length = input?.trim().length ?? 0;
  return length < 2 || length > 80 ? 'Penulis 2–80 karakter' : null;
}

String? validateTotalPages(String? input) {
  final value = int.tryParse(input?.trim() ?? '');
  if (value == null) return 'Isi dengan angka';
  if (value < 10 || value > 2000) return 'Jumlah halaman 10–2000';
  return null;
}

String? validateIsbn(String? input) =>
    (input?.trim().length ?? 0) > 20 ? 'ISBN maksimal 20 karakter' : null;

/// A book started today is due at the end of this month (BR-9).
String defaultTargetDate(String today) => DateId.endOfMonth(today);

/// The one allowed extension: to the end of the month after the current
/// target, and never more than 31 days (the cap the rules apply).
String extendedTargetDate(String targetDate) {
  final endOfNext = DateId.endOfNextMonth(targetDate);
  final cap = DateId.addDays(targetDate, 31);
  return endOfNext.compareTo(cap) <= 0 ? endOfNext : cap;
}
