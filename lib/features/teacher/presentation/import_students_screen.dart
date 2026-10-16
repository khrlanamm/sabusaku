import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/palette.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/school.dart';
import '../../../core/utils/csv_import.dart';
import '../../../core/utils/share_file.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/data/school_repository.dart';
import '../data/teacher_repository.dart';

/// The callable accepts at most this many students per call.
const _batchSize = 100;

typedef _Failure = ({CsvImportRow row, String reason});

/// Import flow: pick file → preview with per-line validation → send in
/// batches → results.
class ImportStudentsScreen extends ConsumerStatefulWidget {
  const ImportStudentsScreen({super.key});

  @override
  ConsumerState<ImportStudentsScreen> createState() =>
      _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends ConsumerState<ImportStudentsScreen> {
  CsvImportPreview? _preview;
  String? _fileName;

  // While sending.
  bool _sending = false;
  int _sent = 0;

  // After sending.
  int? _added;
  List<_Failure> _failures = const [];

  Future<void> _pickFile() async {
    final school = ref.read(schoolProvider).value;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final preview = parseStudentCsv(
        utf8.decode(bytes, allowMalformed: true),
        classes: school?.classes ?? const [],
        extracurriculars: school?.extracurriculars ?? const [],
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _fileName = file.name;
        _added = null;
        _failures = const [];
      });
    } catch (error) {
      if (mounted) showSnack(context, 'Berkas tidak bisa dibuka.');
    }
  }

  Future<void> _send() async {
    final rows = _preview!.validRows;
    final repository = ref.read(teacherRepositoryProvider);
    setState(() {
      _sending = true;
      _sent = 0;
    });

    var added = 0;
    final failures = <_Failure>[];
    for (var start = 0; start < rows.length; start += _batchSize) {
      final batch = rows.skip(start).take(_batchSize).toList();
      try {
        final results = await repository.addStudents([
          for (final row in batch) row.student!,
        ]);
        for (final (index, result) in results.indexed) {
          if (result.ok) {
            added++;
          } else {
            failures.add((row: batch[index], reason: result.reason ?? 'Gagal'));
          }
        }
      } catch (error) {
        // A failed call fails its whole batch; later batches still run.
        final reason = mapError(error).userMessage;
        failures.addAll([for (final row in batch) (row: row, reason: reason)]);
      }
      if (!mounted) return;
      setState(() => _sent = (start + batch.length).clamp(0, rows.length));
    }

    setState(() {
      _sending = false;
      _added = added;
      _failures = failures;
    });
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(schoolProvider).value;
    final Widget body;
    if (_sending) {
      body = _Progress(sent: _sent, total: _preview!.validRows.length);
    } else if (_added != null) {
      body = _Results(
        added: _added!,
        failures: _failures,
        onDone: () => Navigator.of(context).maybePop(),
      );
    } else if (_preview != null) {
      body = _Preview(
        fileName: _fileName ?? '',
        preview: _preview!,
        onPickAnother: _pickFile,
        onSend: _send,
      );
    } else {
      body = _Intro(school: school, onPick: _pickFile);
    }

    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Impor CSV')),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.school, required this.onPick});

  final School? school;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extracurriculars = school?.extracurriculars ?? const <String>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Format berkas', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Berkas CSV dengan baris judul dan empat kolom:\n'
          'email, nama, kelas, ekskul',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              csvImportTemplate.trim().replaceAll('\r\n', '\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Bullet('Hanya email yang wajib. Kolom lain boleh kosong.'),
        const _Bullet(
          'kelas ditulis seperti XII-A1 atau X-G2. Tulisan seperti "12 A1" '
          'dirapikan otomatis. Kelas baru ditambahkan ke daftar kelas sekolah.',
        ),
        _Bullet(
          extracurriculars.isEmpty
              ? 'ekskul dikosongkan: sekolah belum punya daftar ekskul.'
              : 'ekskul dipisah tanda ; atau |, dipilih dari: '
                    '${extracurriculars.join(', ')}.',
        ),
        const _Bullet('Pemisah kolom boleh koma atau titik koma.'),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => shareCsv(
            fileName: 'templat-impor-siswa-sabu-saku.csv',
            content: csvImportTemplate,
            subject: 'Templat impor siswa Sabu Saku',
          ),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Bagikan templat CSV'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('import-pick'),
          onPressed: onPick,
          icon: const Icon(Icons.upload_file),
          label: const Text('Pilih berkas CSV'),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.fileName,
    required this.preview,
    required this.onPickAnother,
    required this.onSend,
  });

  final String fileName;
  final CsvImportPreview preview;
  final VoidCallback onPickAnother;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = preview.validRows.length;
    final newClasses = preview.newClasses.toList()..sort();

    if (preview.fileError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              preview.fileError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPickAnother,
              child: const Text('Pilih berkas lain'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$valid siap diimpor · ${preview.invalidCount} bermasalah',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: preview.invalidCount > 0
                            ? context.palette.attentionText
                            : context.palette.activeText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (newClasses.isNotEmpty)
                      Text(
                        'Kelas baru: ${newClasses.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(onPressed: onPickAnother, child: const Text('Ganti')),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: preview.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _PreviewRow(row: preview.rows[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('import-send'),
              onPressed: valid == 0 ? null : onSend,
              child: Text(
                preview.invalidCount == 0
                    ? 'Impor $valid siswa'
                    : 'Impor $valid siswa yang valid',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.row});

  final CsvImportRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = row.student;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: row.isValid
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: row.isValid
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                row.isValid ? Icons.check_circle : Icons.error,
                size: 18,
                color: row.isValid
                    ? context.palette.success
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.email.isEmpty ? '(tanpa email)' : row.email,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Baris ${row.line}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              row.name.isEmpty ? '(nama kosong)' : row.name,
              student?.classId ?? (row.classText.isEmpty ? '-' : row.classText),
              if (student != null && student.extracurriculars.isNotEmpty)
                student.extracurriculars.join(', ')
              else if (row.extracurricularText.isNotEmpty)
                row.extracurricularText,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (row.isValid && row.newClass)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Kelas ${student!.classId} akan ditambahkan ke daftar kelas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          for (final error in row.errors)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.sent, required this.total});

  final int sent;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: total == 0 ? null : sent / total),
            const SizedBox(height: 16),
            Text('Menambahkan siswa… $sent dari $total'),
            const SizedBox(height: 4),
            const Text('Jangan tutup aplikasi.'),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.added,
    required this.failures,
    required this.onDone,
  });

  final int added;
  final List<_Failure> failures;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(
          added == 0 ? Icons.error_outline : Icons.check_circle,
          size: 56,
          color: added == 0
              ? Theme.of(context).colorScheme.error
              : context.palette.success,
        ),
        const SizedBox(height: 8),
        Text(
          '$added siswa ditambahkan',
          key: const Key('import-result-added'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        if (failures.isNotEmpty)
          Text(
            '${failures.length} gagal',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        if (added > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Minta siswa membuka Sabu Saku dan masuk dengan email yang '
              'didaftarkan, lewat "Masuk dengan Google" atau "Daftar".',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (failures.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Yang gagal', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final failure in failures)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(failure.row.email),
                subtitle: Text('Baris ${failure.row.line}: ${failure.reason}'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('import-done'),
          onPressed: onDone,
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
