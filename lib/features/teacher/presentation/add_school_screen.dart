import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/labels.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/data/auth_repository.dart';
import '../data/superadmin_repository.dart';
import 'student_form.dart';

final _codePattern = RegExp(r'^[a-z0-9]{3,30}$');

/// A superadmin registers a school with its first teacher (penanggung
/// jawab), who then adds students and other teachers in the app. The school
/// starts with the default extracurriculars and no classes.
class AddSchoolScreen extends ConsumerStatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  ConsumerState<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends ConsumerState<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _teacherEmail = TextEditingController();
  final _teacherName = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _teacherEmail.dispose();
    _teacherName.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    final code = (value ?? '').trim().toLowerCase();
    if (code.isEmpty) return 'Kode sekolah wajib diisi';
    if (!_codePattern.hasMatch(code)) {
      return '3–30 huruf kecil dan angka, tanpa spasi';
    }
    return null;
  }

  String? _validateSchoolName(String? value) {
    final name = (value ?? '').trim();
    if (name.length < 3) return 'Nama sekolah minimal 3 karakter';
    if (name.length > 200) return 'Nama sekolah terlalu panjang';
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
    final code = _code.text.trim().toLowerCase();
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final teacherName = _teacherName.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final joined = await runWithProgress(
      context,
      () => ref
          .read(superadminRepositoryProvider)
          .createSchool(
            code: code,
            name: name,
            teacherEmail: normalizeEmail(_teacherEmail.text),
            teacherName: teacherName,
          ),
    );
    if (joined == null || !mounted) return;
    ref.invalidate(allSchoolsProvider);

    final open = await showConfirmDialog(
      context,
      title: '$name terdaftar',
      message: joined
          ? '$teacherName sudah bergabung sebagai penanggung jawab. Buka '
                'sekolah ini sekarang?'
          : '$teacherName menjadi penanggung jawab setelah masuk dengan '
                '${normalizeEmail(_teacherEmail.text)}. Buka sekolah ini '
                'sekarang?',
      confirmLabel: 'Buka sekolah',
      cancelLabel: 'Nanti',
    );
    if (!mounted) return;
    if (open) {
      final switched = await runWithProgress(context, () async {
        await ref.read(authRepositoryProvider).switchSchool(code);
        return true;
      });
      if (switched != true || !mounted) return;
    }
    Navigator.of(context).pop();
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
              Text('Sekolah', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('add-school-code'),
                controller: _code,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Kode sekolah (wajib)',
                  hintText: 'Contoh: sman1sukodadi',
                  helperText: 'Huruf kecil dan angka; tidak bisa diubah.',
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
                  hintText: 'Contoh: SMA Negeri 1 Sukodadi',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: _validateSchoolName,
              ),
              const SizedBox(height: 24),
              Text(
                'Penanggung jawab pertama',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Daftarkan sekolah'),
              ),
              const SizedBox(height: 8),
              Text(
                'Sekolah dimulai dengan ekskul Masis-KIR, Paskibra, Pala, dan '
                'PMR, tanpa kelas. Penanggung jawab menambah kelas, siswa, dan '
                'penanggung jawab lain di aplikasi.',
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
