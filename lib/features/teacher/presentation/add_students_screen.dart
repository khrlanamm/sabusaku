import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/palette.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/member.dart';
import '../../../core/utils/labels.dart';
import '../../auth/presentation/label_pickers.dart';
import '../data/teacher_repository.dart';
import 'student_form.dart';

/// The callable accepts at most this many students per call.
const _maxRows = 100;

/// Adds students by email. Only the email is required; a student completes
/// the name and class at first sign-in.
class AddStudentsScreen extends ConsumerStatefulWidget {
  const AddStudentsScreen({super.key});

  @override
  ConsumerState<AddStudentsScreen> createState() => _AddStudentsScreenState();
}

class _Row {
  final email = TextEditingController();
  final name = TextEditingController();
  String? classId;
  List<String> extracurriculars = const [];

  void dispose() {
    email.dispose();
    name.dispose();
  }

  NewStudent toStudent() => NewStudent(
    email: normalizeEmail(email.text),
    name: name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
    classId: classId,
    extracurriculars: extracurriculars,
  );
}

class _AddStudentsScreenState extends ConsumerState<AddStudentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_Row> _rows = [_Row()];
  bool _sending = false;
  List<AddStudentResult>? _results;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_Row()));

  void _removeRow(int index) => setState(() => _rows.removeAt(index).dispose());

  String? _validateEmail(String? value, int index) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Email wajib diisi';
    if (!isValidEmail(email)) return 'Email tidak valid';
    for (var other = 0; other < index; other++) {
      if (normalizeEmail(_rows[other].email.text) == email) {
        return 'Email ini sudah ada di baris ${other + 1}';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final results = await ref.read(teacherRepositoryProvider).addStudents([
        for (final row in _rows) row.toStudent(),
      ]);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _results = results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapError(error).userMessage)));
    }
  }

  /// Keeps only the rows that failed so they can be fixed and sent again.
  void _retryFailed() {
    final failed = {
      for (final result in _results!)
        if (!result.ok) result.email,
    };
    setState(() {
      for (final row in [..._rows]) {
        if (!failed.contains(normalizeEmail(row.email.text))) {
          _rows.remove(row);
          row.dispose();
        }
      }
      if (_rows.isEmpty) _rows.add(_Row());
      _results = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tambah siswa')),
        body: SafeArea(
          child: _results != null
              ? _Results(
                  results: _results!,
                  onRetry: _retryFailed,
                  onDone: () => Navigator.of(context).maybePop(),
                )
              : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hanya email yang wajib. Siswa melengkapi nama dan kelas saat '
            'pertama masuk, lalu bisa masuk dengan Google atau mendaftar '
            'memakai email yang sama.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final (index, row) in _rows.indexed)
            Card(
              key: ObjectKey(row),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Siswa ${index + 1}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (_rows.length > 1)
                          IconButton(
                            tooltip: 'Hapus baris',
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeRow(index),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: Key('add-email-$index'),
                            controller: row.email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Email (wajib)',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) => _validateEmail(value, index),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: Key('add-name-$index'),
                            controller: row.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap (opsional)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                validateStudentName(value, required: false),
                          ),
                          const SizedBox(height: 12),
                          ClassLabelField(
                            required: false,
                            label: 'Kelas (opsional)',
                            value: row.classId,
                            onChanged: (value) =>
                                setState(() => row.classId = value),
                          ),
                          // The chips carry their own "Ekstrakurikuler" title.
                          const SizedBox(height: 12),
                          ExtracurricularChips(
                            value: row.extracurriculars,
                            onChanged: (value) =>
                                setState(() => row.extracurriculars = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_rows.length < _maxRows)
            OutlinedButton.icon(
              key: const Key('add-row'),
              onPressed: _sending ? null : _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Tambah baris'),
            ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('add-submit'),
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(
                    _rows.length == 1
                        ? 'Tambahkan siswa'
                        : 'Tambahkan ${_rows.length} siswa',
                  ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.onRetry,
    required this.onDone,
  });

  final List<AddStudentResult> results;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final added = results.where((result) => result.ok).length;
    final failed = results.length - added;
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
          key: const Key('add-result-added'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        if (failed > 0)
          Text(
            '$failed gagal',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 16),
        for (final result in results)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                result.ok ? Icons.check_circle : Icons.error,
                color: result.ok
                    ? context.palette.success
                    : Theme.of(context).colorScheme.error,
              ),
              title: Text(result.email),
              subtitle: Text(
                result.ok
                    ? 'Ditambahkan. Siswa bisa masuk dengan email ini.'
                    : result.reason ?? 'Gagal ditambahkan.',
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (failed > 0) ...[
          FilledButton(
            key: const Key('add-retry'),
            onPressed: onRetry,
            child: const Text('Perbaiki yang gagal'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: const Key('add-done'),
          onPressed: onDone,
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
