import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/school.dart';
import '../../../core/utils/labels.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/superadmin_repository.dart';
import 'school_picker_sheet.dart';
import 'student_form.dart';

/// The superadmin registers a school with its first penanggung jawab. The
/// school starts with the default extracurriculars and no classes; its
/// teachers add the rest in the Sekolah tab.
class AddSchoolScreen extends ConsumerStatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  ConsumerState<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends ConsumerState<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _teacherName = TextEditingController();
  final _teacherEmail = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _teacherName.dispose();
    _teacherEmail.dispose();
    super.dispose();
  }

  static String _collapse(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String? _validateCode(String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) return 'Kode sekolah wajib diisi';
    if (!isValidSchoolId(code)) {
      return '3–30 huruf kecil dan angka, tanpa spasi';
    }
    return null;
  }

  String? _validateName(String? value) {
    final name = _collapse(value ?? '');
    if (name.isEmpty) return 'Nama sekolah wajib diisi';
    if (name.length < 3 || name.length > 100) return 'Nama 3–100 karakter';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Email wajib diisi';
    if (!isValidEmail(email)) return 'Email tidak valid';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final code = _code.text.trim();
    final name = _collapse(_name.text);
    final teacherName = _collapse(_teacherName.text);
    final teacherEmail = normalizeEmail(_teacherEmail.text);
    final joined = await runWithProgress(
      context,
      () => ref
          .read(superadminRepositoryProvider)
          .addSchool(
            code: code,
            name: name,
            teacherName: teacherName,
            teacherEmail: teacherEmail,
          ),
    );
    if (joined == null || !mounted) return;

    final open = await showConfirmDialog(
      context,
      title: '$name dibuat',
      message: joined
          ? '$teacherName sudah bergabung sebagai penanggung jawab. Buka '
                'sekolah ini sekarang untuk menambah kelas?'
          : 'Minta $teacherName masuk dengan $teacherEmail. Buka sekolah ini '
                'sekarang untuk menambah kelas?',
      confirmLabel: 'Buka',
      cancelLabel: 'Nanti',
    );
    if (!mounted) return;
    if (open) await openSchool(context, ref, School(id: code, name: name));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah sekolah')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: scheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.add_business_outlined,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sekolah baru mendapat ekskul bawaan dan belum punya '
                          'kelas. Penanggung jawabnya menambah kelas, siswa, '
                          'dan penanggung jawab lain di aplikasi.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('add-school-code'),
                controller: _code,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  TextInputFormatter.withFunction(
                    (_, next) => next.copyWith(text: next.text.toLowerCase()),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Kode sekolah (wajib)',
                  helperText: 'Contoh: sman1sukodadi. Tidak bisa diubah.',
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: _validateCode,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('add-school-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama sekolah (wajib)',
                  hintText: 'SMA Negeri 1 Sukodadi',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 24),
              Text(
                'Penanggung jawab pertama',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('add-school-teacher-email'),
                controller: _teacherEmail,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Email (wajib)',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('add-school-teacher-name'),
                controller: _teacherName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap dan gelar (wajib)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validateStudentName,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('add-school-submit'),
                onPressed: _submit,
                icon: const Icon(Icons.add_business),
                label: const Text('Tambah sekolah'),
              ),
              const SizedBox(height: 8),
              Text(
                'Penanggung jawab masuk dengan Google atau mendaftar memakai '
                'email ini.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
