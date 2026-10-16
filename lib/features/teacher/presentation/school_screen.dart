import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/school.dart';
import '../../../core/utils/labels.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/school_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/teacher_repository.dart';

/// Where penanggung jawab are added or changed (by the developer).
const developerEmail = 'benevology@gmail.com';

/// The school: class and extracurricular labels, the penanggung jawab, and
/// the way to the status settings.
class SchoolScreen extends ConsumerWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(schoolProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sekolah')),
      body: AsyncView<School>(
        value: school,
        onRetry: () => ref.invalidate(schoolProvider),
        data: (data) => _Body(school: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.school});

  final School school;

  Future<void> _addClass(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _LabelDialog(
        title: 'Tambah kelas',
        fieldLabel: 'Nama kelas',
        hint: 'Contoh: XII-A1, X-G2',
        normalize: normalizeClassLabel,
        invalidMessage:
            'Format kelas: X, XI, atau XII, tanda hubung, lalu '
            'huruf dan angka. Contoh: XII-A1, X-G2.',
        existing: school.classes,
      ),
    );
    if (label == null || !context.mounted) return;
    await runWithProgress(
      context,
      () => ref.read(teacherRepositoryProvider).addClassLabel(label),
    );
  }

  Future<void> _removeClass(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus kelas $label?',
      message:
          'Kelas ini tidak bisa dipilih lagi. Siswa yang sudah berada di kelas '
          '$label tetap memakai label ini sampai kelasnya diganti.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runWithProgress(
      context,
      () => ref.read(teacherRepositoryProvider).removeClassLabel(label),
    );
  }

  Future<void> _addExtracurricular(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _LabelDialog(
        title: 'Tambah ekstrakurikuler',
        fieldLabel: 'Nama ekskul',
        hint: 'Contoh: Pramuka',
        normalize: normalizeExtracurricular,
        invalidMessage:
            'Nama ekskul $minExtracurricularLength–$maxExtracurricularLength '
            'karakter.',
        existing: school.extracurriculars,
        caseSensitive: false,
        capitalization: TextCapitalization.words,
      ),
    );
    if (label == null || !context.mounted) return;
    await runWithProgress(
      context,
      () => ref.read(teacherRepositoryProvider).addExtracurricular(label),
    );
  }

  Future<void> _removeExtracurricular(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus ekskul $label?',
      message:
          'Ekskul ini tidak bisa dipilih lagi. Siswa yang sudah mengikuti '
          '$label tetap memakai label ini sampai ekskulnya diubah.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runWithProgress(
      context,
      () => ref.read(teacherRepositoryProvider).removeExtracurricular(label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final teachers = ref.watch(schoolTeachersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              Icons.school_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(school.name, style: theme.textTheme.titleMedium),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Kelas (${school.classes.length})',
          actionKey: const Key('school-add-class'),
          onAdd: () => _addClass(context, ref),
        ),
        Text(
          'Siswa memilih kelasnya dari daftar ini. Format: XII-A1, X-G2.',
          style: muted,
        ),
        const SizedBox(height: 8),
        _LabelWrap(
          labels: school.classes,
          emptyText: 'Belum ada kelas.',
          onRemove: (label) => _removeClass(context, ref, label),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Ekstrakurikuler (${school.extracurriculars.length})',
          actionKey: const Key('school-add-ekskul'),
          onAdd: () => _addExtracurricular(context, ref),
        ),
        Text(
          'Siswa boleh mengikuti lebih dari satu ekskul, atau tidak sama '
          'sekali.',
          style: muted,
        ),
        const SizedBox(height: 8),
        _LabelWrap(
          labels: school.extracurriculars,
          emptyText: 'Belum ada ekskul.',
          onRemove: (label) => _removeExtracurricular(context, ref, label),
        ),
        const SizedBox(height: 24),
        Text('Penanggung jawab', style: theme.textTheme.titleMedium),
        Text(
          'Penanggung jawab ditambahkan oleh pengembang Sabu Saku. Untuk '
          'menambah atau mengganti, kirim email ke $developerEmail.',
          style: muted,
        ),
        const SizedBox(height: 8),
        switch (teachers) {
          AsyncData(:final value) => Card(
            child: Column(
              children: [
                for (final (index, teacher) in value.indexed) ...[
                  if (index > 0) const Divider(),
                  _TeacherTile(teacher: teacher),
                ],
              ],
            ),
          ),
          AsyncError(:final error) => ErrorState(error: error),
          _ => const SkeletonList(items: 2, itemHeight: 64),
        },
        const SizedBox(height: 24),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: const Key('school-settings'),
            leading: const Icon(Icons.tune),
            title: const Text('Pengaturan status siswa'),
            subtitle: const Text('Hari netral, ambang status, hari libur'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.teacherSettings),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionKey,
    required this.onAdd,
  });

  final String title;
  final Key actionKey;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          key: actionKey,
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ],
    );
  }
}

class _LabelWrap extends StatelessWidget {
  const _LabelWrap({
    required this.labels,
    required this.emptyText,
    required this.onRemove,
  });

  final List<String> labels;
  final String emptyText;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Text(
        emptyText,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          InputChip(
            label: Text(label),
            deleteButtonTooltipMessage: 'Hapus $label',
            onDeleted: () => onRemove(label),
          ),
      ],
    );
  }
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({required this.teacher});

  final AppUser teacher;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(photoUrl: teacher.photoUrl, name: teacher.name),
      title: Text(teacher.name.isEmpty ? teacher.email : teacher.name),
      subtitle: Text(
        [
          if (teacher.name.isNotEmpty) teacher.email,
          if (teacher.extracurriculars.isNotEmpty)
            'Pembina ${teacher.extracurriculars.join(', ')}',
        ].join('\n'),
      ),
      isThreeLine:
          teacher.name.isNotEmpty && teacher.extracurriculars.isNotEmpty,
    );
  }
}

/// Asks for one new label, normalised and checked against [existing].
class _LabelDialog extends StatefulWidget {
  const _LabelDialog({
    required this.title,
    required this.fieldLabel,
    required this.hint,
    required this.normalize,
    required this.invalidMessage,
    required this.existing,
    this.caseSensitive = true,
    this.capitalization = TextCapitalization.characters,
  });

  final String title;
  final String fieldLabel;
  final String hint;
  final String? Function(String raw) normalize;
  final String invalidMessage;
  final List<String> existing;
  final bool caseSensitive;
  final TextCapitalization capitalization;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = widget.normalize(_controller.text);
    if (label == null) {
      setState(() => _error = widget.invalidMessage);
      return;
    }
    String key(String value) =>
        widget.caseSensitive ? value : value.toLowerCase();
    if (widget.existing.any((item) => key(item) == key(label))) {
      setState(() => _error = '$label sudah ada.');
      return;
    }
    Navigator.of(context).pop(label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('label-dialog-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: widget.capitalization,
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          hintText: widget.hint,
          errorText: _error,
          errorMaxLines: 3,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('label-dialog-save'),
          onPressed: _submit,
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
