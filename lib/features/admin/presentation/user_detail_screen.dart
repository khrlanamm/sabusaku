import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/models/credential.dart';
import '../../../core/models/school_class.dart';
import '../../../core/widgets/credentials_dialog.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userByIdProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail pengguna')),
      body: AsyncView<AppUser?>(
        value: user,
        data: (data) => data == null
            ? const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Pengguna tidak ditemukan',
              )
            : _Body(user: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.user});

  final AppUser user;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: user.name),
    );
    if (name == null || name == user.name || !context.mounted) return;
    await runWithProgress(context, () async {
      await ref.read(adminRepositoryProvider).renameUser(user.uid, name);
      return true;
    });
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset password?',
      message:
          '${user.name} akan keluar dari semua perangkat dan harus masuk '
          'dengan password sementara.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;
    final password = await runWithProgress(
      context,
      () => ref.read(adminRepositoryProvider).resetPassword(user.uid),
    );
    if (password == null || !context.mounted) return;
    await showCredentialDialog(
      context,
      Credential(
        name: user.name,
        username: user.username,
        password: password,
        role: user.role,
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final activate = !user.active;
    final confirmed = await showConfirmDialog(
      context,
      title: activate ? 'Aktifkan akun?' : 'Nonaktifkan akun?',
      message: activate
          ? '${user.name} bisa masuk lagi.'
          : '${user.name} tidak bisa masuk. Datanya tetap tersimpan.',
      confirmLabel: activate ? 'Aktifkan' : 'Nonaktifkan',
      destructive: !activate,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .setUserActive(user.uid, active: activate);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, activate ? 'Akun diaktifkan' : 'Akun dinonaktifkan');
    }
  }

  Future<void> _moveClass(
    BuildContext context,
    WidgetRef ref,
    List<SchoolClass> classes,
  ) async {
    final classId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pindah ke kelas'),
        children: [
          for (final item in classes)
            if (!item.isArchived)
              ListTile(
                title: Text(item.name),
                trailing: item.id == user.classId
                    ? const Icon(Icons.check, color: AppColors.green)
                    : null,
                onTap: () => Navigator.of(context).pop(item.id),
              ),
        ],
      ),
    );
    if (classId == null || classId == user.classId || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .moveStudentClass(user.uid, classId);
      return true;
    });
    if (ok == true && context.mounted) showSnack(context, 'Siswa dipindahkan');
  }

  Future<void> _assignClasses(
    BuildContext context,
    WidgetRef ref,
    List<SchoolClass> classes,
  ) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          _ClassPicker(classes: classes, initial: user.classIds.toSet()),
    );
    if (selected == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .setTeacherClasses(user.uid, selected);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Kelas guru diperbarui');
    }
  }

  /// Two confirmations: this cannot be undone (docs/03 §5).
  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final first = await showConfirmDialog(
      context,
      title: 'Hapus semua data siswa?',
      message:
          'Akun, buku, jurnal, dan komentar milik ${user.name} akan dihapus '
          'permanen. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Lanjut',
      destructive: true,
    );
    if (!first || !context.mounted) return;
    final typed = await showDialog<bool>(
      context: context,
      builder: (_) => _TypeToConfirmDialog(expected: user.username),
    );
    if (typed != true || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(adminRepositoryProvider).eraseStudent(user.uid);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Data siswa dihapus');
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classes = ref.watch(classesProvider).value ?? const <SchoolClass>[];
    final classNames = ref.watch(classNamesProvider);
    final isSelf = ref.watch(currentSessionProvider).uid == user.uid;
    final isStudent = user.role == UserRole.siswa;
    final classLabel = isStudent
        ? classNames[user.classId] ?? 'Tanpa kelas'
        : user.classIds.isEmpty
        ? 'Belum ditugaskan'
        : user.classIds.map((id) => classNames[id] ?? '?').join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(user.name, style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      tooltip: 'Ubah nama',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _rename(context, ref),
                    ),
                  ],
                ),
                _InfoRow(label: 'Peran', value: user.role.label),
                _InfoRow(
                  label: isStudent ? 'NIS' : 'Username',
                  value: user.username,
                ),
                _InfoRow(label: 'Kelas', value: classLabel),
                _InfoRow(
                  label: 'Status',
                  value: user.active ? 'Aktif' : 'Nonaktif',
                  valueColor: user.active
                      ? AppColors.activeText
                      : AppColors.inactiveText,
                ),
                if (user.mustChangePassword)
                  const _InfoRow(
                    label: 'Password',
                    value: 'Belum diganti sejak dibuat/direset',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (user.role == UserRole.siswa)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Pindah kelas'),
                  onTap: () => _moveClass(context, ref, classes),
                ),
              if (user.role == UserRole.guru)
                ListTile(
                  key: const Key('user-assign-classes'),
                  leading: const Icon(Icons.class_outlined),
                  title: const Text('Atur kelas yang dipantau'),
                  onTap: () => _assignClasses(context, ref, classes),
                ),
              if (!isSelf) ...[
                if (user.role != UserRole.admin) const Divider(),
                ListTile(
                  key: const Key('user-reset-password'),
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Reset password'),
                  onTap: () => _resetPassword(context, ref),
                ),
                const Divider(),
                ListTile(
                  key: const Key('user-toggle-active'),
                  leading: Icon(
                    user.active ? Icons.block : Icons.check_circle_outline,
                    color: user.active ? AppColors.error : AppColors.green,
                  ),
                  title: Text(
                    user.active ? 'Nonaktifkan akun' : 'Aktifkan akun',
                  ),
                  onTap: () => _toggleActive(context, ref),
                ),
              ],
            ],
          ),
        ),
        if (isStudent) ...[
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: const Key('user-erase'),
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.error,
              ),
              title: const Text(
                'Hapus semua data siswa',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text('Untuk siswa lulus atau permintaan sekolah'),
              onTap: () => _erase(context, ref),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah nama'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
          validator: (value) {
            final length = value?.trim().length ?? 0;
            return length < 2 || length > 80 ? 'Nama 2–80 karakter' : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_name.text.trim());
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _ClassPicker extends StatefulWidget {
  const _ClassPicker({required this.classes, required this.initial});

  final List<SchoolClass> classes;
  final Set<String> initial;

  @override
  State<_ClassPicker> createState() => _ClassPickerState();
}

class _ClassPickerState extends State<_ClassPicker> {
  late final _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final classes = [
      for (final item in widget.classes)
        if (!item.isArchived || widget.initial.contains(item.id)) item,
    ];
    return AlertDialog(
      title: const Text('Kelas yang dipantau'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: double.maxFinite,
        child: classes.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada kelas.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final item in classes)
                    CheckboxListTile(
                      value: _selected.contains(item.id),
                      title: Text(item.name),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(item.id);
                        } else {
                          _selected.remove(item.id);
                        }
                      }),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('class-picker-save'),
          onPressed: () => Navigator.of(context).pop(_selected.toList()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

/// Second step of the erase confirmation: the admin types the student's NIS.
class _TypeToConfirmDialog extends StatefulWidget {
  const _TypeToConfirmDialog({required this.expected});

  final String expected;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim() == widget.expected;
    return AlertDialog(
      title: const Text('Konfirmasi penghapusan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ketik NIS siswa (${widget.expected}) untuk melanjutkan.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('erase-confirm-input'),
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'NIS'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('erase-confirm-submit'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Hapus permanen'),
        ),
      ],
    );
  }
}
