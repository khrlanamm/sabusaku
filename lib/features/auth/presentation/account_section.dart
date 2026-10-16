import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../notifications/notification_service.dart';
import '../data/auth_repository.dart';
import '../data/school_repository.dart';
import '../domain/app_user.dart';
import 'photo_actions.dart';

/// Who is signed in, with photo, name, password, sign-out and account
/// deletion. Shared by every role.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final school = ref.watch(schoolProvider).value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = session.profile;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      photoUrl: profile.photoUrl,
                      name: profile.name,
                      radius: 32,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton.filledTonal(
                        key: const Key('account-photo'),
                        tooltip: 'Ganti foto',
                        iconSize: 16,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.photo_camera_outlined),
                        onPressed: () =>
                            showPhotoActions(context, ref, session),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(profile.email, style: muted),
                      Text(
                        [
                          session.role.label,
                          if (school != null) school.name,
                        ].join(' · '),
                        style: muted,
                      ),
                      if (session.role == UserRole.guru &&
                          profile.extracurriculars.isNotEmpty)
                        Text(
                          'Pembina ${profile.extracurriculars.join(', ')}',
                          style: muted,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                key: const Key('account-name'),
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Ubah nama'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editName(context, ref),
              ),
              const Divider(),
              ListTile(
                key: const Key('account-password'),
                leading: const Icon(Icons.lock_outline),
                title: Text(
                  session.hasPassword ? 'Ubah password' : 'Atur password',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.changePassword),
              ),
              const Divider(),
              ListTile(
                key: const Key('account-signout'),
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text('Keluar', style: TextStyle(color: scheme.error)),
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Keluar dari akun?',
                    message: 'Kamu perlu masuk lagi untuk memakai aplikasi.',
                    confirmLabel: 'Keluar',
                    destructive: true,
                  );
                  if (!confirmed) return;
                  // So this account's notifications stop reaching the phone.
                  await ref
                      .read(notificationServiceProvider)
                      .unregisterDevice();
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('account-delete'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Hapus akun'),
            onPressed: () => _deleteAccount(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final session = ref.read(currentSessionProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: session.profile.name),
    );
    if (name == null || name == session.profile.name || !context.mounted) {
      return;
    }
    await runWithProgress(
      context,
      () => ref.read(authRepositoryProvider).updateProfile(session, name: name),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final session = ref.read(currentSessionProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DeleteAccountDialog(isStudent: session.role == UserRole.siswa),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(notificationServiceProvider).unregisterDevice();
    if (!context.mounted) return;
    await runWithProgress(
      context,
      () => ref.read(authRepositoryProvider).deleteAccount(),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah nama'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('name-field'),
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
          textCapitalization: TextCapitalization.words,
          onFieldSubmitted: (_) => _save(),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.length < 2) return 'Nama minimal 2 huruf';
            if (name.length > 80) return 'Nama maksimal 80 huruf';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

/// Deletion is permanent, so the user types a word to confirm it.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.isStudent});

  final bool isStudent;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'HAPUS';
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = _typed.text.trim().toUpperCase() == _word;
    return AlertDialog(
      title: const Text('Hapus akun?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isStudent
                ? 'Akun beserta semua buku, jurnal, dan komentar guru akan '
                      'dihapus permanen dan tidak bisa dikembalikan.'
                : 'Akun dan keanggotaanmu di sekolah akan dihapus permanen. '
                      'Komentar yang sudah kamu tulis tetap tersimpan.',
          ),
          const SizedBox(height: 14),
          Text('Ketik $_word untuk melanjutkan.'),
          const SizedBox(height: 8),
          TextField(
            key: const Key('delete-confirm-field'),
            controller: _typed,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
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
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Hapus permanen'),
        ),
      ],
    );
  }
}
