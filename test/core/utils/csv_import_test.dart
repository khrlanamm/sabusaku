import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/credential.dart';
import 'package:sabusaku/core/models/school_class.dart';
import 'package:sabusaku/core/utils/csv_import.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';

const _classes = [
  SchoolClass(
    id: 'k1',
    name: 'XII IPA 1',
    grade: 12,
    academicYear: '2026/2027',
  ),
  SchoolClass(
    id: 'k2',
    name: 'XII IPA 2',
    grade: 12,
    academicYear: '2026/2027',
  ),
  SchoolClass(
    id: 'k0',
    name: 'XII Lama',
    grade: 12,
    academicYear: '2025/2026',
    isArchived: true,
  ),
];

void main() {
  group('parseUserCsv', () {
    test('the bundled template is fully valid', () {
      final preview = parseUserCsv(csvImportTemplate, _classes);
      expect(preview.fileError, isNull);
      expect(preview.rows, hasLength(3));
      expect(preview.invalidCount, 0);

      final student = preview.rows[0].user!;
      expect(student.role, UserRole.siswa);
      expect(student.username, '12345678');
      expect(student.classId, 'k1');

      final teacher = preview.rows[2].user!;
      expect(teacher.role, UserRole.guru);
      expect(teacher.classIds, ['k1', 'k2']);
    });

    test('accepts semicolons, a BOM, mixed case and blank lines', () {
      const content =
          '﻿Peran;Nama;Username;Kelas\n'
          'SISWA; Raka Pratama ; 0012 ;xii ipa 1\n'
          '\n'
          'Guru;Bu Sari;Sari.W;\n';
      final preview = parseUserCsv(content, _classes);
      expect(preview.fileError, isNull);
      expect(preview.rows, hasLength(2));
      expect(preview.invalidCount, 0);
      // A NIS keeps its leading zeros.
      expect(preview.rows[0].user!.username, '0012');
      expect(preview.rows[0].user!.name, 'Raka Pratama');
      expect(preview.rows[1].user!.username, 'sari.w');
      expect(preview.rows[1].user!.classIds, isEmpty);
    });

    test('quoted names may contain the delimiter', () {
      const content =
          'peran,nama,username,kelas\n'
          'siswa,"Pratama, Raka",1001,XII IPA 1\n';
      final row = parseUserCsv(content, _classes).rows.single;
      expect(row.isValid, isTrue);
      expect(row.user!.name, 'Pratama, Raka');
    });

    test('reports every problem per line with its line number', () {
      const content =
          'peran,nama,username,kelas\n'
          'siswa,Raka,1001,XII IPA 1\n'
          'siswa,Kembar,1001,XII IPA 1\n'
          'murid,Salah Peran,1002,XII IPA 1\n'
          'siswa,X,1003,XII IPA 1\n'
          'siswa,Username Buruk,Budi Santoso,XII IPA 1\n'
          'siswa,Kelas Hilang,1004,XII IPS 9\n'
          'siswa,Kelas Arsip,1005,XII Lama\n'
          'siswa,Dua Kelas,1006,XII IPA 1|XII IPA 2\n'
          'siswa,Tanpa Kelas,1007,\n';
      final preview = parseUserCsv(content, _classes);
      final errors = {
        for (final row in preview.rows) row.line: row.errors.join('; '),
      };

      expect(preview.validRows.map((r) => r.line), [2]);
      expect(errors[3], contains('kembar'));
      expect(errors[4], contains('Peran'));
      expect(errors[5], contains('Nama'));
      expect(errors[6], contains('Username'));
      expect(errors[7], contains('"XII IPS 9" tidak ditemukan'));
      expect(errors[8], contains('diarsipkan'));
      expect(errors[9], contains('tepat satu kelas'));
      expect(errors[10], contains('tepat satu kelas'));
    });

    test('rejects files without the expected header', () {
      expect(
        parseUserCsv(
          'nama,nis,kelas\nRaka,1001,XII IPA 1\n',
          _classes,
        ).fileError,
        contains('peran,nama,username,kelas'),
      );
      expect(parseUserCsv('', _classes).fileError, 'Berkas kosong.');
      expect(
        parseUserCsv('peran,nama,username,kelas\n', _classes).fileError,
        contains('tidak berisi data'),
      );
    });
  });

  test('credentialsToCsv writes one line per account', () {
    final csv = credentialsToCsv(const [
      Credential(
        name: 'Pratama, Raka',
        username: '1001',
        password: 'abcd2345ef',
        role: UserRole.siswa,
        className: 'XII IPA 1',
      ),
    ]);
    final lines = csv.trim().split(RegExp(r'\r?\n'));
    expect(lines[0], 'nama,username,password,peran,kelas');
    expect(lines[1], '"Pratama, Raka",1001,abcd2345ef,siswa,XII IPA 1');
  });
}
