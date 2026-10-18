import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/member.dart';
import '../../../core/utils/labels.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/teacher_repository.dart';
import 'student_form.dart';
import 'teacher_profile_screen.dart';

/// The school's teachers (penanggung jawab) in the Sekolah tab: who has
/// joined, who has been added but not signed in yet, and adding or removing
/// one. A teacher cannot remove themselves.
class TeachersSection extends ConsumerWidget {
  const TeachersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teachers = ref.watch(schoolTeachersProvider);
    final pending = ref.watch(pendingTeachersProvider).value ?? const [];
    final myUid = ref.watch(currentSessionProvider.select((s) => s.uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Penanggung jawab',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const Key('school-add-teacher'),
              onPressed: () => context.push(Routes.teacherAddTeacher),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        Text(
          'Setiap penanggung jawab melihat dan mengelola semua siswa sekolah '
          'ini.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        switch (teachers) {
          AsyncData(:final value) => Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, teacher) in value.indexed) ...[
                  if (index > 0) const Divider(),
                  _TeacherTile(
                    teacher: teacher,
                    isMe: teacher.uid == myUid,
                    onTap: teacher.uid == myUid
                        ? null
                        : () => _showTeacher(context, teacher),
                  ),
                ],
              ],
            ),
          ),
          AsyncError(:final error) => ErrorState(error: error),
          _ => const SkeletonList(items: 2, itemHeight: 64),
        },
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const Key('school-pending-teachers'),
              leading: Icon(
                Icons.hourglass_empty,
                color: theme.colorScheme.primary,
              ),
              title: Text('Belum masuk (${pending.length})'),
              subtitle: Text(
                'Sudah ditambahkan, tetapi belum pernah masuk aplikasi.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                for (final member in pending)
                  ListTile(
                    key: Key('pending-teacher-${member.email}'),
                    leading: UserAvatar(photoUrl: null, name: member.name),
                    title: Text(member.name),
                    subtitle: Text(
                      [
                        member.email,
                        ?teacherRoleLine(
                          member.homeroomClass,
                          member.extracurriculars,
                        ),
                      ].join('\n'),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _showPending(context, member),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTeacher(BuildContext context, AppUser teacher) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _TeacherSheet(teacher: teacher),
      );

  void _showPending(BuildContext context, Member member) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PendingTeacherSheet(member: member),
      );
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({required this.teacher, required this.isMe, this.onTap});

  final AppUser teacher;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final roles = teacherRoleLine(
      teacher.homeroomClass,
      teacher.extracurriculars,
    );
    return ListTile(
      key: Key('teacher-${teacher.email}'),
      leading: UserAvatar(photoUrl: teacher.photoUrl, name: teacher.name),
      title: Text(teacher.name.isEmpty ? teacher.email : teacher.name),
      subtitle: Text(
        [if (teacher.name.isNotEmpty) teacher.email, ?roles].join('\n'),
      ),
      isThreeLine: teacher.name.isNotEmpty && roles != null,
      trailing: isMe ? const Text('Anda') : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Another teacher who has joined: their roles, and taking them out of the
/// school.
class _TeacherSheet extends ConsumerWidget {
  const _TeacherSheet({required this.teacher});

  final AppUser teacher;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final name = teacher.name.isEmpty ? teacher.email : teacher.name;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluarkan $name?',
      message:
          '$name tidak bisa lagi membuka data sekolah ini. Akunnya tetap ada; '
          'menambahkannya lagi memulihkan aksesnya.',
      confirmLabel: 'Keluarkan',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final done = await runWithProgress(context, () async {
      await ref.read(teacherRepositoryProvider).removeTeacher(teacher.email);
      return true;
    });
    if (done == true && context.mounted) {
      showSnack(context, '$name dikeluarkan dari sekolah.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(
                photoUrl: teacher.photoUrl,
                name: teacher.name,
              ),
              title: Text(
                teacher.name.isEmpty ? teacher.email : teacher.name,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(teacher.email),
            ),
            const SizedBox(height: 8),
            Text(
              teacherRoleLine(
                    teacher.homeroomClass,
                    teacher.extracurriculars,
                  ) ??
                  'Belum mengatur wali kelas atau ekskul binaan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Peran ini diatur sendiri oleh penanggung jawab di Profil.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('teacher-remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _remove(context, ref),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Keluarkan dari sekolah'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A teacher added but not signed in yet: fix the name and roles, or
/// withdraw the invitation.
class _PendingTeacherSheet extends ConsumerStatefulWidget {
  const _PendingTeacherSheet({required this.member});

  final Member member;

  @override
  ConsumerState<_PendingTeacherSheet> createState() =>
      _PendingTeacherSheetState();
}

class _PendingTeacherSheetState extends ConsumerState<_PendingTeacherSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member.name);
  late String? _homeroomClass = widget.member.homeroomClass;
  late List<String> _extracurriculars = widget.member.extracurriculars;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .updatePendingTeacher(
            widget.member.email,
            name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
            homeroomClass: _homeroomClass,
            extracurriculars: _extracurriculars,
          );
      return true;
    });
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _withdraw() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Batalkan undangan?',
      message:
          '${widget.member.email} tidak lagi terdaftar sebagai penanggung '
          'jawab sekolah ini.',
      confirmLabel: 'Batalkan undangan',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final done = await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .removeTeacher(widget.member.email);
      return true;
    });
    if (done == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.member.email, style: theme.textTheme.titleMedium),
              Text(
                'Belum pernah masuk aplikasi.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pending-teacher-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap dan gelar',
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
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('pending-teacher-save'),
                onPressed: _save,
                child: const Text('Simpan'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('pending-teacher-withdraw'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _withdraw,
                child: const Text('Batalkan undangan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
