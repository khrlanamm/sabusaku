import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/member.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/student_status.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';
import 'scope_filter_bar.dart';
import 'student_tile.dart';

/// Every student of the school, filtered by the teacher's own group
/// ("Binaan saya"), class, extracurricular, status and name, plus the
/// students who have not signed in yet.
class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  String _query = '';

  bool _matchesQuery(String name, String email) =>
      _query.isEmpty ||
      name.toLowerCase().contains(_query) ||
      email.contains(_query);

  Future<void> _showAddMenu() async {
    final route = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('students-add-manual'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Tambah siswa'),
              subtitle: const Text('Isi email satu per satu'),
              onTap: () => Navigator.of(context).pop(Routes.teacherAddStudents),
            ),
            ListTile(
              key: const Key('students-add-import'),
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Impor CSV'),
              subtitle: const Text('Banyak siswa sekaligus dari berkas'),
              onTap: () =>
                  Navigator.of(context).pop(Routes.teacherImportStudents),
            ),
          ],
        ),
      ),
    );
    if (route != null && mounted) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(teacherStudentsProvider);
    final pending = ref.watch(pendingStudentsProvider).value ?? const [];
    final filter = ref.watch(studentListFilterProvider);
    final filterNotifier = ref.read(studentListFilterProvider.notifier);
    final options = ref.watch(scopeOptionsProvider);
    final me = ref.watch(currentSessionProvider.select((s) => s.profile));

    return Scaffold(
      appBar: AppBar(title: const Text('Siswa')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('students-add'),
        onPressed: _showAddMenu,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau email',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (me.hasGroup) ...[
                  Center(
                    child: FilterChip(
                      key: const Key('students-mine-filter'),
                      avatar: filter.mine
                          ? null
                          : const Icon(Icons.star_outline, size: 18),
                      label: const Text('Binaan saya'),
                      selected: filter.mine,
                      onSelected: filterNotifier.setMine,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                FilterMenuChip(
                  key: const Key('students-class-filter'),
                  label: 'Semua kelas',
                  clearLabel: 'Semua kelas',
                  value: filter.classId,
                  options: options.classes,
                  onChanged: filterNotifier.setClass,
                ),
                const SizedBox(width: 8),
                FilterMenuChip(
                  key: const Key('students-ekskul-filter'),
                  label: 'Semua ekskul',
                  clearLabel: 'Semua ekskul',
                  value: filter.extracurricular,
                  options: options.extracurriculars,
                  onChanged: filterNotifier.setExtracurricular,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: StudentStatus.values.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => Center(
                child: index == 0
                    ? ChoiceChip(
                        label: const Text('Semua status'),
                        selected: filter.status == null,
                        onSelected: (_) => filterNotifier.setStatus(null),
                      )
                    : ChoiceChip(
                        key: Key(
                          'students-status-${StudentStatus.values[index - 1].wire}',
                        ),
                        label: Text(StudentStatus.values[index - 1].label),
                        selected:
                            filter.status == StudentStatus.values[index - 1],
                        onSelected: (_) => filterNotifier.setStatus(
                          StudentStatus.values[index - 1],
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncView<List<StudentStats>>(
              value: students,
              onRetry: () => ref.invalidate(teacherStudentsProvider),
              data: (all) {
                final visible = [
                  for (final stats in all)
                    if (matchesLabels(
                          filter,
                          classId: stats.classId,
                          extracurriculars: stats.extracurriculars,
                          me: me,
                        ) &&
                        (filter.status == null ||
                            stats.status == filter.status) &&
                        _matchesQuery(stats.name, stats.email))
                      stats,
                ];
                // Pending students have no status yet; a status filter
                // hides them.
                final visiblePending = filter.status != null
                    ? const <Member>[]
                    : [
                        for (final member in pending)
                          if (matchesLabels(
                                filter,
                                classId: member.classId,
                                extracurriculars: member.extracurriculars,
                                me: me,
                              ) &&
                              _matchesQuery(member.name, member.email))
                            member,
                      ];

                if (visible.isEmpty && visiblePending.isEmpty) {
                  final nobody = all.isEmpty && pending.isEmpty;
                  return EmptyState(
                    icon: Icons.groups_outlined,
                    title: nobody ? 'Belum ada siswa' : 'Tidak ada yang cocok',
                    message: nobody
                        ? 'Tambahkan siswa dengan email mereka lewat tombol '
                              'Tambah.'
                        : 'Ubah pencarian atau filter.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (visiblePending.isNotEmpty) ...[
                      _PendingSection(members: visiblePending),
                      const SizedBox(height: 12),
                    ],
                    for (final stats in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: StudentTile(
                          stats: stats,
                          onTap: () => context.push(
                            Routes.teacherStudent(stats.studentId),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Students added by email who have not signed in yet.
class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('students-pending'),
        leading: Icon(
          Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('Belum masuk (${members.length})'),
        subtitle: Text(
          'Sudah didaftarkan, tetapi belum pernah masuk aplikasi.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final member in members)
            PendingMemberTile(
              member: member,
              onTap: () =>
                  context.push(Routes.teacherPendingMember(member.email)),
            ),
        ],
      ),
    );
  }
}
