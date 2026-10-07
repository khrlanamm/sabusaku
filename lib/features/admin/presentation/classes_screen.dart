import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/models/school_class.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../data/admin_repository.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  bool _showArchived = false;

  Future<void> _add() async {
    final draft = await showClassFormDialog(
      context,
      defaultAcademicYear: defaultAcademicYear(
        ref.read(wibClockProvider).today(),
      ),
    );
    if (draft == null || !mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(adminRepositoryProvider)
          .createClass(
            name: draft.name,
            grade: draft.grade,
            academicYear: draft.academicYear,
          );
      return true;
    });
    if (ok == true && mounted) showSnack(context, 'Kelas ditambahkan');
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas'),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Sembunyikan arsip' : 'Tampilkan arsip',
            icon: Icon(
              _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('class-add'),
        // Shell tabs stay mounted together; default hero tags would clash.
        heroTag: 'fab-classes',
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Kelas'),
      ),
      body: AsyncView<List<SchoolClass>>(
        value: classes,
        onRetry: () => ref.invalidate(classesProvider),
        data: (all) {
          final visible = [
            for (final item in all)
              if (_showArchived || !item.isArchived) item,
          ];
          if (visible.isEmpty) {
            return const EmptyState(
              icon: Icons.class_outlined,
              title: 'Belum ada kelas',
              message:
                  'Tambahkan kelas dulu, lalu impor guru dan siswa ke '
                  'dalamnya.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = visible[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Kelas ${item.grade} · ${item.academicYear} · '
                    '${item.teacherIds.length} guru',
                  ),
                  trailing: item.isArchived
                      ? const _ArchivedBadge()
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.adminClass(item.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Arsip',
        style: TextStyle(
          color: AppColors.neutralText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// "2026/2027" for dates from July on, otherwise the year that started the
/// previous July.
String defaultAcademicYear(String today) {
  final year = int.parse(today.substring(0, 4));
  final month = int.parse(today.substring(5, 7));
  final start = month >= 7 ? year : year - 1;
  return '$start/${start + 1}';
}

typedef ClassDraft = ({String name, int grade, String academicYear});

/// Add or edit a class. Returns null when cancelled.
Future<ClassDraft?> showClassFormDialog(
  BuildContext context, {
  SchoolClass? existing,
  String defaultAcademicYear = '',
}) {
  return showDialog<ClassDraft>(
    context: context,
    builder: (_) => _ClassFormDialog(
      existing: existing,
      defaultAcademicYear: defaultAcademicYear,
    ),
  );
}

class _ClassFormDialog extends StatefulWidget {
  const _ClassFormDialog({this.existing, required this.defaultAcademicYear});

  final SchoolClass? existing;
  final String defaultAcademicYear;

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _year = TextEditingController(
    text: widget.existing?.academicYear ?? widget.defaultAcademicYear,
  );
  late int _grade = widget.existing?.grade ?? 10;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      grade: _grade,
      academicYear: _year.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah kelas' : 'Ubah kelas'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('class-name'),
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nama kelas',
                hintText: 'XII IPA 1',
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                return length < 2 || length > 40
                    ? 'Nama kelas 2–40 karakter'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Tingkat'),
              items: const [
                DropdownMenuItem(value: 10, child: Text('Kelas 10')),
                DropdownMenuItem(value: 11, child: Text('Kelas 11')),
                DropdownMenuItem(value: 12, child: Text('Kelas 12')),
              ],
              onChanged: (value) => setState(() => _grade = value ?? _grade),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _year,
              decoration: const InputDecoration(
                labelText: 'Tahun ajaran',
                hintText: '2026/2027',
              ),
              validator: (value) =>
                  RegExp(r'^\d{4}/\d{4}$').hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Format: 2026/2027',
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
          key: const Key('class-save'),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
