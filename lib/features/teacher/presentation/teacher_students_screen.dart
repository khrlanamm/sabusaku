import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';
import 'student_tile.dart';

/// Students of the assigned classes, filtered by class, status and name.
class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final classIds = ref.watch(currentSessionProvider).classIds;
    final classNames = ref.watch(classNamesProvider);
    final students = ref.watch(teacherStudentsProvider);
    final filter = ref.watch(studentListFilterProvider);
    final filterNotifier = ref.read(studentListFilterProvider.notifier);
    // A class the teacher was unassigned from can no longer be a filter.
    final classFilter = classIds.contains(filter.classId)
        ? filter.classId
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Siswa')),
      body: classIds.isEmpty
          ? const EmptyState(
              icon: Icons.class_outlined,
              title: 'Belum ada kelas',
              message: 'Kamu belum ditugaskan ke kelas mana pun.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari nama siswa',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
                _ChipRow(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua kelas'),
                      selected: classFilter == null,
                      onSelected: (_) => filterNotifier.setClass(null),
                    ),
                    for (final id in classIds)
                      ChoiceChip(
                        label: Text(classNames[id] ?? 'Kelas'),
                        selected: classFilter == id,
                        onSelected: (_) => filterNotifier.setClass(id),
                      ),
                  ],
                ),
                _ChipRow(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua status'),
                      selected: filter.status == null,
                      onSelected: (_) => filterNotifier.setStatus(null),
                    ),
                    for (final status in StudentStatus.values)
                      ChoiceChip(
                        key: Key('students-status-${status.wire}'),
                        label: Text(status.label),
                        selected: filter.status == status,
                        onSelected: (_) => filterNotifier.setStatus(status),
                      ),
                  ],
                ),
                Expanded(
                  child: AsyncView<List<StudentStats>>(
                    value: students,
                    onRetry: () => ref.invalidate(teacherStudentsProvider),
                    data: (all) {
                      final visible = [
                        for (final stats in all)
                          if ((classFilter == null ||
                                  stats.classId == classFilter) &&
                              (filter.status == null ||
                                  stats.status == filter.status) &&
                              (_query.isEmpty ||
                                  stats.name.toLowerCase().contains(_query)))
                            stats,
                      ];
                      if (visible.isEmpty) {
                        return EmptyState(
                          icon: Icons.groups_outlined,
                          title: all.isEmpty
                              ? 'Belum ada siswa'
                              : 'Tidak ada yang cocok',
                          message: all.isEmpty
                              ? 'Siswa ditambahkan oleh admin sekolah.'
                              : 'Ubah pencarian atau filter.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => StudentTile(
                          stats: visible[index],
                          onTap: () => context.push(
                            Routes.teacherStudent(visible[index].studentId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: children[index]),
      ),
    );
  }
}
