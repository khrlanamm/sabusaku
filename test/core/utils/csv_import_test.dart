import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/member.dart';
import 'package:sabusaku/core/utils/csv_import.dart';

const _classes = ['XII-A1', 'XI-B2'];
const _extracurriculars = ['Masis-KIR', 'Paskibra', 'Pala', 'PMR'];

CsvImportPreview _parse(String content) => parseStudentCsv(
  content,
  classes: _classes,
  extracurriculars: _extracurriculars,
);

void main() {
  test('reads a valid file and normalises every column', () {
    final preview = _parse(
      'email,nama,kelas,ekskul\n'
      ' Raka@Gmail.com ,Raka  Pratama,12  A1,masis-kir\n'
      'dewi@gmail.com,Dewi Lestari,XI-B2,PMR;Paskibra\n'
      'bima@gmail.com,,,\n',
    );

    expect(preview.fileError, isNull);
    expect(preview.invalidCount, 0);
    expect(preview.validRows.map((row) => row.student), const [
      NewStudent(
        email: 'raka@gmail.com',
        name: 'Raka Pratama',
        classId: 'XII-A1',
        extracurriculars: ['Masis-KIR'],
      ),
      NewStudent(
        email: 'dewi@gmail.com',
        name: 'Dewi Lestari',
        classId: 'XI-B2',
        extracurriculars: ['PMR', 'Paskibra'],
      ),
      NewStudent(email: 'bima@gmail.com'),
    ]);
    expect(preview.newClasses, isEmpty);
  });

  test('accepts semicolon-separated files from Excel, with a BOM', () {
    final preview = _parse(
      '﻿email;nama;kelas;ekskul\r\n'
      'sari@gmail.com;Sari;XIIC2;"Pala|PMR"\r\n',
    );
    expect(preview.fileError, isNull);
    final student = preview.validRows.single.student!;
    expect(student.classId, 'XII-C2');
    expect(student.extracurriculars, ['Pala', 'PMR']);
  });

  test('a valid class the school lacks is new, not an error', () {
    final preview = _parse('email,nama,kelas,ekskul\na@gmail.com,,X-G2,\n');
    final row = preview.rows.single;
    expect(row.isValid, isTrue);
    expect(row.newClass, isTrue);
    expect(preview.newClasses, {'X-G2'});
  });

  test('reports every problem of a line', () {
    final preview = _parse(
      'email,nama,kelas,ekskul\n'
      'bukan-email,A,IPA satu,Futsal\n'
      ',Tanpa Email,,\n'
      'sama@gmail.com,,,\n'
      'SAMA@gmail.com,,,\n',
    );

    expect(preview.validRows.map((row) => row.email), ['sama@gmail.com']);
    expect(preview.rows[0].errors, [
      'Email tidak valid',
      'Nama harus 2–80 karakter',
      'Kelas "IPA satu" tidak dikenali (contoh: XII-A1, X-G2)',
      'Ekskul "Futsal" tidak ada di sekolah ini',
    ]);
    expect(preview.rows[1].errors, ['Email wajib diisi']);
    expect(preview.rows[3].errors, ['Email kembar dalam berkas ini']);
    expect(preview.rows[3].line, 5);
  });

  test('skips blank lines', () {
    final preview = _parse('email,nama,kelas,ekskul\n,,,\na@gmail.com,,,\n');
    expect(preview.rows.single.email, 'a@gmail.com');
  });

  test('rejects files without the expected header or data', () {
    expect(_parse('').fileError, 'Berkas kosong.');
    expect(
      _parse('peran,nama,username,kelas\nsiswa,A,b,c\n').fileError,
      startsWith('Baris pertama harus berisi judul kolom'),
    );
    expect(
      _parse('email,nama,kelas,ekskul\n').fileError,
      'Berkas tidak berisi data siswa.',
    );
  });

  test('the template parses cleanly against the default lists', () {
    final preview = _parse(csvImportTemplate);
    expect(preview.invalidCount, 0);
    expect(preview.validRows, hasLength(3));
  });
}
