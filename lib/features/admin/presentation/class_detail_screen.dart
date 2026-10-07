import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/models/school_class.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';
import 'classes_screen.dart';

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail kelas')),
      body: AsyncView<List<SchoolClass>>(
        value: classes,
        data: (all) {
          final item = all.where((c) => c.id == classId).firstOrNull;
          if (item == null) {
            return const EmptyState(
              icon: Icons.class_outlined,
              title: 'Kelas tidak ditemukan',
            );
          }
          return _Body(item: item);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.item});

  final SchoolClass item;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final draft = await showClassFormDialog(context, existing: item);
    if (draft == null || !context.mounted) return;
    await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .updateClass(
            item.copyWith(
              name: draft.name,
              grade: draft.grade,
              academicYear: draft.academicYear,
            ),
          );
      return true;
    });
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final archive = !item.isArchived;
    final confirmed = await showConfirmDialog(
      context,
      title: archive ? 'Arsipkan kelas?' : 'Aktifkan kelas lagi?',
      message: archive
          ? 'Kelas tidak bisa dipilih untuk siswa baru. Data siswa dan '
                'jurnalnya tetap ada.'
          : 'Kelas kembali bisa dipilih untuk siswa.',
      confirmLabel: archive ? 'Arsipkan' : 'Aktifkan',
    );
    if (!confirmed || !context.mounted) return;
    await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .updateClass(item.copyWith(isArchived: archive));
      return true;
    });
  }

  /// Assigning is stored on each teacher (`classIds`), so a change here is
  /// one call per teacher whose assignment to this class flipped.
  Future<void> _assignTeachers(
    BuildContext context,
    WidgetRef ref,
    List<AppUser> teachers,
  ) async {
    final current = {
      for (final teacher in teachers)
        if (teacher.classIds.contains(item.id)) teacher.uid,
    };
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _TeacherPicker(teachers: teachers, initial: current),
    );
    if (selected == null || !context.mounted) return;

    final changed = [
      for (final teacher in teachers)
        if (selected.contains(teacher.uid) != current.contains(teacher.uid))
          teacher,
    ];
    if (changed.isEmpty) return;

    final ok = await runWithProgress(context, () async {
      final repository = ref.read(adminRepositoryProvider);
      for (final teacher in changed) {
        final classIds = selected.contains(teacher.uid)
            ? [...teacher.classIds, item.id]
            : teacher.classIds.where((id) => id != item.id).toList();
        await repository.setTeacherClasses(teacher.uid, classIds);
      }
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Penugasan guru diperbarui');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teachers = ref.watch(usersByRoleProvider(UserRole.guru));
    final assigned = [
      for (final teacher in teachers.value ?? const <AppUser>[])
        if (teacher.classIds.contains(item.id)) teacher,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Kelas ${item.grade} · Tahun ajaran ${item.academicYear}'
                  '${item.isArchived ? ' · Diarsipkan' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, ref),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Ubah'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _toggleArchive(context, ref),
                      icon: Icon(
                        item.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      label: Text(item.isArchived ? 'Aktifkan' : 'Arsipkan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Guru pemantau', style: theme.textTheme.titleMedium),
            ),
            TextButton.icon(
              key: const Key('class-assign-teachers'),
              onPressed: teachers.hasValue
                  ? () => _assignTeachers(context, ref, teachers.value!)
                  : null,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Atur guru'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (teachers.isLoading)
          const SkeletonList(items: 2, itemHeight: 56)
        else if (assigned.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada guru yang ditugaskan ke kelas ini.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, teacher) in assigned.indexed) ...[
                  if (index > 0) const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(teacher.name),
                    subtitle: Text(teacher.username),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TeacherPicker extends StatefulWidget {
  const _TeacherPicker({required this.teachers, required this.initial});

  final List<AppUser> teachers;
  final Set<String> initial;

  @override
  State<_TeacherPicker> createState() => _TeacherPickerState();
}

class _TeacherPickerState extends State<_TeacherPicker> {
  late final _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final teachers = widget.teachers.where((t) => t.active).toList();
    return AlertDialog(
      title: const Text('Guru pemantau'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: double.maxFinite,
        child: teachers.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada guru. Tambahkan di menu Pengguna.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final teacher in teachers)
                    CheckboxListTile(
                      value: _selected.contains(teacher.uid),
                      title: Text(teacher.name),
                      subtitle: Text(teacher.username),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(teacher.uid);
                        } else {
                          _selected.remove(teacher.uid);
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
          key: const Key('teacher-picker-save'),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
