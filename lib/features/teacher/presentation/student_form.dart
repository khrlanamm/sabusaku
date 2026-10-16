import 'package:flutter/material.dart';

import '../../auth/presentation/label_pickers.dart';

/// Name, class and extracurriculars of a student, as edited by a teacher.
typedef StudentEdit = ({
  String name,
  String? classId,
  List<String> extracurriculars,
});

/// Bottom sheet that edits a student's name, class and extracurriculars.
/// Returns null when cancelled.
Future<StudentEdit?> showStudentEditor(
  BuildContext context, {
  required String title,
  required StudentEdit initial,
  bool nameRequired = true,
}) => showModalBottomSheet<StudentEdit>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _StudentEditor(
      title: title,
      initial: initial,
      nameRequired: nameRequired,
    ),
  ),
);

class _StudentEditor extends StatefulWidget {
  const _StudentEditor({
    required this.title,
    required this.initial,
    required this.nameRequired,
  });

  final String title;
  final StudentEdit initial;
  final bool nameRequired;

  @override
  State<_StudentEditor> createState() => _StudentEditorState();
}

class _StudentEditorState extends State<_StudentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late String? _classId = widget.initial.classId;
  late List<String> _extracurriculars = widget.initial.extracurriculars;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<StudentEdit>((
      name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      classId: _classId,
      extracurriculars: _extracurriculars,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('student-edit-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (value) =>
                  validateStudentName(value, required: widget.nameRequired),
            ),
            const SizedBox(height: 14),
            ClassLabelField(
              required: widget.nameRequired,
              value: _classId,
              onChanged: (value) => setState(() => _classId = value),
            ),
            const SizedBox(height: 14),
            ExtracurricularChips(
              value: _extracurriculars,
              onChanged: (value) => setState(() => _extracurriculars = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('student-edit-save'),
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2–80 characters. Empty is allowed when the name is optional: the student
/// fills it in at first sign-in.
String? validateStudentName(String? value, {bool required = true}) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return required ? 'Nama wajib diisi' : null;
  if (name.length < 2 || name.length > 80) return 'Nama harus 2–80 karakter';
  return null;
}
