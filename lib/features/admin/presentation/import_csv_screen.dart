import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/credential.dart';
import '../../../core/models/school_class.dart';
import '../../../core/utils/csv_import.dart';
import '../../../core/utils/share_file.dart';
import '../../../core/widgets/credentials_dialog.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';

/// The callable accepts at most this many users per call.
const _batchSize = 100;

typedef _Failure = ({CsvImportRow row, String reason});

/// Import flow: pick file → preview with per-line validation → send in
/// batches → results with the initial passwords to share.
class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  CsvImportPreview? _preview;
  String? _fileName;

  // While sending.
  bool _sending = false;
  int _sent = 0;

  // After sending.
  List<Credential>? _created;
  List<_Failure> _failures = const [];

  List<SchoolClass> get _classes =>
      ref.read(classesProvider).value ?? const <SchoolClass>[];

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final preview = parseUserCsv(
        utf8.decode(bytes, allowMalformed: true),
        _classes,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _fileName = file.name;
        _created = null;
        _failures = const [];
      });
    } catch (error) {
      if (mounted) showSnack(context, 'Berkas tidak bisa dibuka.');
    }
  }

  Future<void> _send() async {
    final rows = _preview!.validRows;
    final classNames = ref.read(classNamesProvider);
    final repository = ref.read(adminRepositoryProvider);
    setState(() {
      _sending = true;
      _sent = 0;
    });

    final created = <Credential>[];
    final failures = <_Failure>[];
    for (var start = 0; start < rows.length; start += _batchSize) {
      final batch = rows.skip(start).take(_batchSize).toList();
      try {
        final results = await repository.createUsers([
          for (final row in batch) row.user!,
        ]);
        for (final (index, result) in results.indexed) {
          final row = batch[index];
          final user = row.user!;
          if (result.ok) {
            created.add(
              Credential(
                name: user.name,
                username: result.username,
                password: result.password!,
                role: user.role,
                className: user.role == UserRole.siswa
                    ? classNames[user.classId] ?? ''
                    : user.classIds
                          .map((id) => classNames[id] ?? '')
                          .join(csvClassSeparator),
              ),
            );
          } else {
            failures.add((row: row, reason: result.reason ?? 'Gagal'));
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
      _created = created;
      _failures = failures;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_sending) {
      body = _Progress(sent: _sent, total: _preview!.validRows.length);
    } else if (_created != null) {
      body = _Results(
        created: _created!,
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
      body = _Intro(onPick: _pickFile);
    }

    return PopScope(
      // Leaving mid-import or before sharing would lose the passwords.
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Impor CSV')),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Format berkas', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Berkas CSV dengan baris judul dan empat kolom:\n'
          'peran, nama, username, kelas',
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
        const _Bullet('peran: siswa atau guru.'),
        const _Bullet('username siswa adalah NIS.'),
        const _Bullet(
          'kelas harus sama dengan nama kelas yang sudah dibuat. Buat kelas '
          'lebih dulu di tab Kelas.',
        ),
        const _Bullet(
          'Guru boleh punya beberapa kelas dipisah tanda | atau dikosongkan.',
        ),
        const _Bullet('Pemisah kolom boleh koma atau titik koma.'),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => shareCsv(
            fileName: 'templat-impor-sabu-saku.csv',
            content: csvImportTemplate,
            subject: 'Templat impor Sabu Saku',
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

    if (preview.fileError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
                            ? AppColors.attentionText
                            : AppColors.activeText,
                        fontWeight: FontWeight.w600,
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
                    ? 'Impor $valid pengguna'
                    : 'Impor $valid pengguna yang valid',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: row.isValid ? AppColors.surface : AppColors.inactiveTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: row.isValid ? AppColors.outline : AppColors.inactiveText,
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
                color: row.isValid ? AppColors.green : AppColors.inactiveText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.name.isEmpty ? '(tanpa nama)' : row.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                'Baris ${row.line}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${row.roleText} · ${row.username} · ${row.classText}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          for (final error in row.errors)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inactiveText,
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
            Text('Membuat akun… $sent dari $total'),
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
    required this.created,
    required this.failures,
    required this.onDone,
  });

  final List<Credential> created;
  final List<_Failure> failures;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(
          created.isEmpty ? Icons.error_outline : Icons.check_circle,
          size: 56,
          color: created.isEmpty ? AppColors.error : AppColors.green,
        ),
        const SizedBox(height: 8),
        Text(
          '${created.length} akun dibuat',
          key: const Key('import-result-created'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        if (failures.isNotEmpty)
          Text(
            '${failures.length} gagal',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inactiveText,
            ),
          ),
        const SizedBox(height: 16),
        if (created.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.attentionTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Password awal hanya tersedia sekarang. Bagikan atau simpan '
              'berkas kredensial sebelum meninggalkan layar ini.',
              style: TextStyle(color: AppColors.attentionText),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('import-share'),
            onPressed: () => shareCredentials(created),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan kredensial (CSV)'),
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
                title: Text('${failure.row.name} (${failure.row.username})'),
                subtitle: Text('Baris ${failure.row.line}: ${failure.reason}'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('import-done'),
          onPressed: () async {
            if (created.isNotEmpty) {
              final leave = await showConfirmDialog(
                context,
                title: 'Sudah menyimpan kredensial?',
                message:
                    'Password awal tidak bisa ditampilkan lagi setelah layar '
                    'ini ditutup.',
                confirmLabel: 'Sudah, tutup',
              );
              if (!leave) return;
            }
            onDone();
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
