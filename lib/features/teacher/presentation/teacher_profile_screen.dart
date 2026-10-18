import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dialogs.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_section.dart';
import '../../auth/presentation/label_pickers.dart';
import '../../notifications/notification_prompt.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The morning digest only concerns a teacher with students of their own.
    final hasGroup = ref.watch(
      currentSessionProvider.select((s) => s.profile.hasGroup),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Asks once, right after the teacher first sets a role.
          if (hasGroup) const NotificationPermissionPrompt(),
          const AccountHeader(),
          const SizedBox(height: 20),
          const TeacherRolesCard(),
          const SizedBox(height: 20),
          AccountSettings(
            extraSettings: [
              if (hasGroup)
                const NotificationSettingTile(title: 'Notifikasi siswa binaan'),
            ],
          ),
        ],
      ),
    );
  }
}

/// The teacher's homeroom class and supervised extracurriculars, which they
/// set themselves. Both are optional.
class TeacherRolesCard extends ConsumerWidget {
  const TeacherRolesCard({super.key});

  void _edit(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RolesSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentSessionProvider.select((s) => s.profile));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Peran di sekolah', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Dipakai untuk filter Binaan saya, notifikasi pagi tentang siswa '
          'binaan, dan ditampilkan di profil siswa.',
          style: muted,
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                key: const Key('profile-homeroom'),
                leading: const Icon(Icons.class_outlined),
                title: const Text('Wali kelas'),
                subtitle: Text(profile.homeroomClass ?? 'Bukan wali kelas'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(context),
              ),
              const Divider(),
              ListTile(
                key: const Key('profile-supervised'),
                leading: const Icon(Icons.groups_2_outlined),
                title: const Text('Pembina ekskul'),
                subtitle: Text(
                  profile.extracurriculars.isEmpty
                      ? 'Tidak membina ekskul'
                      : profile.extracurriculars.join(', '),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolesSheet extends ConsumerStatefulWidget {
  const _RolesSheet();

  @override
  ConsumerState<_RolesSheet> createState() => _RolesSheetState();
}

class _RolesSheetState extends ConsumerState<_RolesSheet> {
  late String? _homeroomClass;
  late List<String> _extracurriculars;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentSessionProvider).profile;
    _homeroomClass = profile.homeroomClass;
    _extracurriculars = [...profile.extracurriculars];
  }

  Future<void> _save() async {
    final session = ref.read(currentSessionProvider);
    final saved = await runWithProgress(context, () async {
      await ref
          .read(authRepositoryProvider)
          .updateTeacherGroup(
            session,
            homeroomClass: _homeroomClass,
            extracurriculars: _extracurriculars,
          );
      return true;
    });
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Peran di sekolah',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TeacherRoleFields(
            homeroomClass: _homeroomClass,
            extracurriculars: _extracurriculars,
            onHomeroomChanged: (value) =>
                setState(() => _homeroomClass = value),
            onExtracurricularsChanged: (value) =>
                setState(() => _extracurriculars = value),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('roles-save'),
            onPressed: _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

/// Homeroom class and supervised extracurriculars of a teacher, both
/// optional. Shared by the profile and by adding another teacher.
class TeacherRoleFields extends StatelessWidget {
  const TeacherRoleFields({
    super.key,
    required this.homeroomClass,
    required this.extracurriculars,
    required this.onHomeroomChanged,
    required this.onExtracurricularsChanged,
  });

  final String? homeroomClass;
  final List<String> extracurriculars;
  final ValueChanged<String?> onHomeroomChanged;
  final ValueChanged<List<String>> onExtracurricularsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClassLabelField(
          value: homeroomClass,
          onChanged: onHomeroomChanged,
          required: false,
          label: 'Wali kelas (opsional)',
          noneLabel: 'Bukan wali kelas',
          emptyHelper: 'Belum ada daftar kelas. Tambahkan di tab Sekolah.',
        ),
        const SizedBox(height: 18),
        ExtracurricularChips(
          title: 'Pembina ekstrakurikuler (opsional)',
          value: extracurriculars,
          onChanged: onExtracurricularsChanged,
        ),
      ],
    );
  }
}
