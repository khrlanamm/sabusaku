import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/labels.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/teacher_repository.dart';
import 'student_form.dart';
import 'teacher_profile_screen.dart';

/// Adds another teacher (penanggung jawab) of this school by email, with an
/// optional homeroom class and supervised extracurriculars. The new teacher
/// signs in with Google or signs up with that email.
class AddTeacherScreen extends ConsumerStatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  ConsumerState<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends ConsumerState<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  String? _homeroomClass;
  List<String> _extracurriculars = const [];

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
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
    final email = normalizeEmail(_email.text);
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final joined = await runWithProgress(
      context,
      () => ref
          .read(teacherRepositoryProvider)
          .addTeacher(
            email: email,
            name: name,
            homeroomClass: _homeroomClass,
            extracurriculars: _extracurriculars,
          ),
    );
    if (joined == null || !mounted) return;
    showSnack(
      context,
      joined
          ? '$name sudah bergabung sebagai penanggung jawab.'
          : '$name ditambahkan. Minta dia masuk dengan $email.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah penanggung jawab')),
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
                        Icons.admin_panel_settings_outlined,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Penanggung jawab baru dapat melihat dan mengelola '
                          'semua siswa sekolah ini, serta menambah siswa dan '
                          'penanggung jawab lain.',
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
                key: const Key('add-teacher-email'),
                controller: _email,
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
                key: const Key('add-teacher-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap dan gelar (wajib)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validateStudentName,
              ),
              const SizedBox(height: 18),
              TeacherRoleFields(
                homeroomClass: _homeroomClass,
                extracurriculars: _extracurriculars,
                onHomeroomChanged: (value) =>
                    setState(() => _homeroomClass = value),
                onExtracurricularsChanged: (value) =>
                    setState(() => _extracurriculars = value),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('add-teacher-submit'),
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Tambah penanggung jawab'),
              ),
              const SizedBox(height: 8),
              Text(
                'Dia masuk dengan Google atau mendaftar memakai email ini. '
                'Wali kelas dan ekskul binaan bisa diubahnya sendiri di '
                'Profil.',
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
