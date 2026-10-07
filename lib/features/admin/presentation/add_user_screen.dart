import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/class_repository.dart';
import '../../../core/models/credential.dart';
import '../../../core/models/school_class.dart';
import '../../../core/widgets/credentials_dialog.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/credentials.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

/// Adds a single teacher or student by hand.
class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  UserRole _role = UserRole.siswa;
  String? _classId;
  final _classIds = <String>{};

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit(Map<String, String> classNames) async {
    if (!_formKey.currentState!.validate()) return;
    final user = NewUser(
      role: _role,
      name: _name.text.trim(),
      username: normalizeIdentity(_username.text),
      classId: _role == UserRole.siswa ? _classId : null,
      classIds: _role == UserRole.guru ? _classIds.toList() : const [],
    );
    final results = await runWithProgress(
      context,
      () => ref.read(adminRepositoryProvider).createUsers([user]),
    );
    if (results == null || !mounted) return;
    final result = results.single;
    if (!result.ok) {
      showSnack(context, result.reason ?? 'Gagal membuat akun.');
      return;
    }
    await showCredentialDialog(
      context,
      Credential(
        name: user.name,
        username: result.username,
        password: result.password!,
        role: user.role,
        className: user.role == UserRole.siswa
            ? classNames[user.classId] ?? ''
            : user.classIds.map((id) => classNames[id] ?? '').join('|'),
      ),
      title: 'Akun dibuat',
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final classes = [
      for (final item
          in ref.watch(classesProvider).value ?? const <SchoolClass>[])
        if (!item.isArchived) item,
    ];
    final classNames = ref.watch(classNamesProvider);
    final isStudent = _role == UserRole.siswa;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah pengguna')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(value: UserRole.siswa, label: Text('Siswa')),
                    ButtonSegment(value: UserRole.guru, label: Text('Guru')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) =>
                      setState(() => _role = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('add-user-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length < 2 || length > 80
                        ? 'Nama 2–80 karakter'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('add-user-username'),
                  controller: _username,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: isStudent
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: InputDecoration(
                    labelText: isStudent ? 'NIS' : 'Username',
                    helperText: isStudent ? 'NIS dipakai siswa untuk masuk' : 'Huruf kecil, angka, titik, garis bawah, tanda hubung',
                  ),
                  validator: (value) =>
                      isValidUsername(normalizeIdentity(value ?? ''))
                      ? null
                      : '3–30 karakter: huruf kecil, angka, . _ -',
                ),
                const SizedBox(height: 14),
                if (isStudent)
                  DropdownButtonFormField<String>(
                    key: const Key('add-user-class'),
                    initialValue: _classId,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: [
                      for (final item in classes)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _classId = value),
                    validator: (value) =>
                        value == null ? 'Pilih kelas siswa' : null,
                  )
                else ...[
                  Text(
                    'Kelas yang dipantau (boleh kosong)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final item in classes)
                        FilterChip(
                          label: Text(item.name),
                          selected: _classIds.contains(item.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _classIds.add(item.id);
                            } else {
                              _classIds.remove(item.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                if (classes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Belum ada kelas. Buat kelas di tab Kelas.'),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('add-user-submit'),
                  onPressed: () => _submit(classNames),
                  child: const Text('Buat akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
