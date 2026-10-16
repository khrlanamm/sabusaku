import 'package:csv/csv.dart';

import '../models/member.dart';
import 'labels.dart';

/// Columns of the import file: `email,nama,kelas,ekskul`.
///
/// Only `email` is required. `kelas` is one class label (`XII-A1`); a valid
/// label the school does not have yet is added to it. `ekskul` lists
/// extracurriculars of the school separated by `;` or `|`.
const csvImportHeader = ['email', 'nama', 'kelas', 'ekskul'];
final _extracurricularSeparator = RegExp(r'[;|]');
const maxStudentExtracurriculars = 10;

const csvImportTemplate =
    'email,nama,kelas,ekskul\r\n'
    'raka.pratama@gmail.com,Raka Pratama,XII-A1,Masis-KIR\r\n'
    'dewi.lestari@gmail.com,Dewi Lestari,XI-B2,PMR;Paskibra\r\n'
    'bima@gmail.com,,,\r\n';

/// One data line of the import file after validation.
class CsvImportRow {
  const CsvImportRow({
    required this.line,
    required this.email,
    required this.name,
    required this.classText,
    required this.extracurricularText,
    this.student,
    this.errors = const [],
    this.newClass = false,
  });

  /// 1-based line number in the file, counting the header.
  final int line;
  final String email;
  final String name;
  final String classText;
  final String extracurricularText;

  /// Ready to send when [errors] is empty.
  final NewStudent? student;
  final List<String> errors;

  /// The class label is valid but not yet in the school's list.
  final bool newClass;

  bool get isValid => errors.isEmpty && student != null;
}

class CsvImportPreview {
  const CsvImportPreview({required this.rows, this.fileError});

  final List<CsvImportRow> rows;

  /// A problem with the file as a whole, e.g. a missing header.
  final String? fileError;

  List<CsvImportRow> get validRows => [
    for (final row in rows)
      if (row.isValid) row,
  ];
  int get invalidCount => rows.length - validRows.length;

  /// Class labels the import will add to the school.
  Set<String> get newClasses => {
    for (final row in validRows)
      if (row.newClass) row.student!.classId!,
  };
}

/// Excel in Indonesian locale saves "CSV" with semicolons.
String _detectDelimiter(String firstLine) =>
    ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
    ? ';'
    : ',';

/// Parses and validates an import file against the school's [classes] and
/// [extracurriculars].
///
/// Validation mirrors the `addStudents` callable so problems show up per line
/// in the preview, before anything is sent.
CsvImportPreview parseStudentCsv(
  String content, {
  required List<String> classes,
  required List<String> extracurriculars,
}) {
  // Strip the UTF-8 BOM that Excel adds.
  final text = content.startsWith('﻿') ? content.substring(1) : content;
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  if (firstLine.trim().isEmpty) {
    return const CsvImportPreview(rows: [], fileError: 'Berkas kosong.');
  }

  final List<List<dynamic>> table;
  try {
    table = Csv(
      fieldDelimiter: _detectDelimiter(firstLine),
      autoDetect: false,
    ).decode(text);
  } on Object {
    return const CsvImportPreview(
      rows: [],
      fileError: 'Berkas tidak bisa dibaca sebagai CSV.',
    );
  }

  String cell(List<dynamic> row, int index) =>
      index < row.length ? row[index].toString().trim() : '';

  final header = [
    for (var i = 0; i < csvImportHeader.length; i++)
      cell(table.first, i).toLowerCase(),
  ];
  if (header.join(',') != csvImportHeader.join(',')) {
    return CsvImportPreview(
      rows: const [],
      fileError:
          'Baris pertama harus berisi judul kolom: '
          '${csvImportHeader.join(',')}',
    );
  }

  final knownClasses = classes.toSet();
  final extracurricularByKey = {
    for (final item in extracurriculars) item.toLowerCase(): item,
  };
  final seenEmails = <String>{};
  final rows = <CsvImportRow>[];

  for (var index = 1; index < table.length; index++) {
    final raw = table[index];
    final email = normalizeEmail(cell(raw, 0));
    final name = cell(raw, 1).replaceAll(RegExp(r'\s+'), ' ');
    final classText = cell(raw, 2);
    final extracurricularText = cell(raw, 3);
    if ([email, name, classText, extracurricularText].every((v) => v.isEmpty)) {
      continue;
    }

    final errors = <String>[];
    if (email.isEmpty) {
      errors.add('Email wajib diisi');
    } else if (!isValidEmail(email)) {
      errors.add('Email tidak valid');
    } else if (!seenEmails.add(email)) {
      errors.add('Email kembar dalam berkas ini');
    }

    if (name.isNotEmpty && (name.length < 2 || name.length > 80)) {
      errors.add('Nama harus 2–80 karakter');
    }

    String? classId;
    if (classText.isNotEmpty) {
      classId = normalizeClassLabel(classText);
      if (classId == null) {
        errors.add('Kelas "$classText" tidak dikenali (contoh: XII-A1, X-G2)');
      }
    }

    final chosen = <String>[];
    for (final part in extracurricularText.split(_extracurricularSeparator)) {
      final label = part.trim();
      if (label.isEmpty) continue;
      final match = extracurricularByKey[label.toLowerCase()];
      if (match == null) {
        errors.add('Ekskul "$label" tidak ada di sekolah ini');
      } else if (!chosen.contains(match)) {
        chosen.add(match);
      }
    }
    if (chosen.length > maxStudentExtracurriculars) {
      errors.add('Maksimal $maxStudentExtracurriculars ekskul');
    }

    rows.add(
      CsvImportRow(
        line: index + 1,
        email: email,
        name: name,
        classText: classText,
        extracurricularText: extracurricularText,
        errors: errors,
        newClass: classId != null && !knownClasses.contains(classId),
        student: errors.isNotEmpty
            ? null
            : NewStudent(
                email: email,
                name: name,
                classId: classId,
                extracurriculars: chosen,
              ),
      ),
    );
  }

  if (rows.isEmpty) {
    return const CsvImportPreview(
      rows: [],
      fileError: 'Berkas tidak berisi data siswa.',
    );
  }
  return CsvImportPreview(rows: rows);
}
