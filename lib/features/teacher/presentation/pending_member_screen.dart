import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/member.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../data/teacher_repository.dart';
import 'student_form.dart';
import 'student_tile.dart' show labelLine;

/// A student added by email who has not signed in yet. The teacher can still
/// change the name, class and extracurriculars, or take the email off the
/// list.
class PendingMemberScreen extends ConsumerStatefulWidget {
  const PendingMemberScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<PendingMemberScreen> createState() =>
      _PendingMemberScreenState();
}

class _PendingMemberScreenState extends ConsumerState<PendingMemberScreen> {
  /// Set while removing: the document disappears and the rules then refuse
  /// to read it, which is not an error to show.
  bool _removing = false;

  Future<void> _edit(Member member) async {
    final edit = await showStudentEditor(
      context,
      title: 'Ubah data siswa',
      initial: (
        name: member.name,
        classId: member.classId,
        extracurriculars: member.extracurriculars,
      ),
      nameRequired: false,
    );
    if (edit == null || !mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(teacherRepositoryProvider)
          .updatePendingStudent(
            member.email,
            name: edit.name,
            classId: edit.classId,
            extracurriculars: edit.extracurriculars,
          );
      return true;
    });
    if (ok == true && mounted) showSnack(context, 'Data siswa disimpan.');
  }

  Future<void> _remove(Member member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus dari daftar?',
      message:
          '${member.email} tidak lagi terdaftar di sekolah ini dan tidak bisa '
          'masuk aplikasi sampai ditambahkan lagi.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _removing = true);
    final ok = await runWithProgress(context, () async {
      await ref.read(teacherRepositoryProvider).removeStudent(member.email);
      return true;
    });
    if (!mounted) return;
    if (ok == true) {
      showSnack(context, '${member.email} dihapus dari daftar.');
      context.pop();
    } else {
      setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberProvider(widget.email));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Siswa belum masuk')),
      body: _removing
          ? const Center(child: CircularProgressIndicator())
          : AsyncView<Member?>(
              value: member,
              onRetry: () => ref.invalidate(memberProvider(widget.email)),
              data: (data) {
                if (data == null) {
                  return const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Tidak terdaftar',
                    message: 'Email ini sudah tidak ada di daftar sekolah.',
                  );
                }
                if (!data.pending) {
                  return EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Sudah masuk',
                    message:
                        '${data.email} sudah masuk aplikasi. Kelola dari '
                        'halaman siswa.',
                    action: FilledButton(
                      onPressed: () => context.pushReplacement(
                        Routes.teacherStudent(data.uid!),
                      ),
                      child: const Text('Buka halaman siswa'),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name.isEmpty
                                  ? '(nama belum diisi)'
                                  : data.name,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(data.email, style: muted),
                            const SizedBox(height: 4),
                            Text(
                              labelLine(data.classId, data.extracurriculars),
                              style: muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Siswa ini belum pernah masuk. Minta siswa membuka '
                        'Sabu Saku lalu memilih "Masuk dengan Google" atau '
                        '"Daftar" memakai email ini. Data yang kosong akan '
                        'dilengkapi siswa saat pertama masuk.',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('pending-edit'),
                      onPressed: () => _edit(data),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Ubah nama, kelas, ekskul'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('pending-remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _remove(data),
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Hapus dari daftar'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
