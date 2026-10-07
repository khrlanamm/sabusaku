import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../../core/widgets/states.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  UserRole _role = UserRole.siswa;
  String? _classId;
  String _query = '';

  void _openAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('users-add-manual'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Tambah satu pengguna'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.push(Routes.adminAddUser);
              },
            ),
            ListTile(
              key: const Key('users-add-import'),
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Impor dari CSV'),
              subtitle: const Text('Banyak guru dan siswa sekaligus'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.push(Routes.adminImport);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersByRoleProvider(_role));
    final classes = ref.watch(classesProvider).value ?? const [];
    final classNames = ref.watch(classNamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('users-add'),
        // Shell tabs stay mounted together; default hero tags would clash.
        heroTag: 'fab-users',
        onPressed: _openAddMenu,
        icon: const Icon(Icons.add),
        label: const Text('Pengguna'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.siswa,
                      label: Text('Siswa'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: UserRole.guru,
                      label: Text('Guru'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) => setState(() {
                    _role = selection.first;
                    _classId = null;
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau username',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
                if (classes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Semua kelas'),
                            selected: _classId == null,
                            onSelected: (_) => setState(() => _classId = null),
                          ),
                        ),
                        for (final item in classes)
                          if (!item.isArchived)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(item.name),
                                selected: _classId == item.id,
                                onSelected: (_) =>
                                    setState(() => _classId = item.id),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<AppUser>>(
              value: users,
              onRetry: () => ref.invalidate(usersByRoleProvider(_role)),
              data: (all) {
                final visible = [
                  for (final user in all)
                    if ((_classId == null ||
                            user.classId == _classId ||
                            user.classIds.contains(_classId)) &&
                        (_query.isEmpty ||
                            user.name.toLowerCase().contains(_query) ||
                            user.username.contains(_query)))
                      user,
                ];
                if (visible.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_outlined,
                    title: all.isEmpty
                        ? 'Belum ada ${_role.label.toLowerCase()}'
                        : 'Tidak ada yang cocok',
                    message: all.isEmpty
                        ? 'Tambahkan satu per satu atau impor dari CSV.'
                        : 'Ubah pencarian atau filter kelas.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = visible[index];
                    final classLabel = user.role == UserRole.siswa
                        ? classNames[user.classId] ?? 'Tanpa kelas'
                        : user.classIds.isEmpty
                        ? 'Belum ditugaskan'
                        : user.classIds
                              .map((id) => classNames[id] ?? '?')
                              .join(', ');
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text('${user.username} · $classLabel'),
                        trailing: user.active
                            ? const Icon(Icons.chevron_right)
                            : const _DisabledBadge(),
                        onTap: () => context.push(Routes.adminUser(user.uid)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledBadge extends StatelessWidget {
  const _DisabledBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inactiveTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Nonaktif',
        style: TextStyle(
          color: AppColors.inactiveText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
