import 'package:csv/csv.dart';

import '../../features/admin/domain/admin_models.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/credentials.dart';
import '../models/credential.dart';
import '../models/school_class.dart';

/// Columns of the import file: `peran,nama,username,kelas`.
///
/// For a student `username` is the NIS and `kelas` is one class name. A
/// teacher may list several classes separated by `|`, or none.
const csvImportHeader = ['peran', 'nama', 'username', 'kelas'];
const csvClassSeparator = '|';
const maxTeacherClasses = 20;

const csvImportTemplate =
    'peran,nama,username,kelas\r\n'
    'siswa,Raka Pratama,12345678,XII IPA 1\r\n'
    'siswa,Dewi Lestari,12345679,XII IPA 1\r\n'
    'guru,Sari Wulandari,sari.wulandari,XII IPA 1|XII IPA 2\r\n';

/// One data line of the import file after validation.
class CsvImportRow {
  const CsvImportRow({
    required this.line,
    required this.roleText,
    required this.name,
    required this.username,
    required this.classText,
    this.user,
    this.errors = const [],
  });

  /// 1-based line number in the file, counting the header.
  final int line;
  final String roleText;
  final String name;
  final String username;
  final String classText;

  /// Ready to send when [errors] is empty.
  final NewUser? user;
  final List<String> errors;

  bool get isValid => errors.isEmpty && user != null;
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
}

/// Excel in Indonesian locale saves "CSV" with semicolons.
String _detectDelimiter(String firstLine) =>
    ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
    ? ';'
    : ',';

/// Parses and validates an import file against the school's [classes].
///
/// Validation mirrors the `createUsers` callable so problems show up per line
/// in the preview, before anything is sent.
CsvImportPreview parseUserCsv(String content, List<SchoolClass> classes) {
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
    for (var i = 0; i < 4; i++) cell(table.first, i).toLowerCase(),
  ];
  if (header.join(',') != csvImportHeader.join(',')) {
    return const CsvImportPreview(
      rows: [],
      fileError:
          'Baris pertama harus berisi judul kolom: peran,nama,username,kelas',
    );
  }

  final classByName = {
    for (final item in classes) item.name.trim().toLowerCase(): item,
  };
  final seenUsernames = <String>{};
  final rows = <CsvImportRow>[];

  for (var index = 1; index < table.length; index++) {
    final raw = table[index];
    final roleText = cell(raw, 0);
    final name = cell(raw, 1);
    final username = normalizeIdentity(cell(raw, 2));
    final classText = cell(raw, 3);
    if ([roleText, name, username, classText].every((v) => v.isEmpty)) continue;

    final errors = <String>[];
    final role = switch (roleText.toLowerCase()) {
      'siswa' => UserRole.siswa,
      'guru' => UserRole.guru,
      _ => null,
    };
    if (role == null) errors.add('Peran harus "siswa" atau "guru"');
    if (name.length < 2 || name.length > 80) {
      errors.add('Nama harus 2–80 karakter');
    }
    if (!isValidUsername(username)) {
      errors.add(
        'Username harus 3–30 karakter: huruf kecil, angka, titik, garis '
        'bawah, atau tanda hubung',
      );
    } else if (!seenUsernames.add(username)) {
      errors.add('Username kembar dalam berkas ini');
    }

    final classNames = [
      for (final part in classText.split(csvClassSeparator))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    final classIds = <String>[];
    for (final className in classNames) {
      final match = classByName[className.toLowerCase()];
      if (match == null) {
        errors.add('Kelas "$className" tidak ditemukan');
      } else if (match.isArchived) {
        errors.add('Kelas "$className" sudah diarsipkan');
      } else if (!classIds.contains(match.id)) {
        classIds.add(match.id);
      }
    }
    if (role == UserRole.siswa && classNames.length != 1) {
      errors.add('Siswa harus punya tepat satu kelas');
    }
    if (role == UserRole.guru && classNames.length > maxTeacherClasses) {
      errors.add('Guru maksimal $maxTeacherClasses kelas');
    }

    rows.add(
      CsvImportRow(
        line: index + 1,
        roleText: roleText,
        name: name,
        username: username,
        classText: classText,
        errors: errors,
        user: errors.isNotEmpty || role == null
            ? null
            : NewUser(
                role: role,
                name: name,
                username: username,
                classId: role == UserRole.siswa ? classIds.single : null,
                classIds: role == UserRole.guru ? classIds : const [],
              ),
      ),
    );
  }

  if (rows.isEmpty) {
    return const CsvImportPreview(
      rows: [],
      fileError: 'Berkas tidak berisi data pengguna.',
    );
  }
  return CsvImportPreview(rows: rows);
}

/// The file admins hand out: one line per new account with its password.
String credentialsToCsv(List<Credential> credentials) => Csv().encode([
  ['nama', 'username', 'password', 'peran', 'kelas'],
  for (final item in credentials)
    [item.name, item.username, item.password, item.role.wire, item.className],
]);
