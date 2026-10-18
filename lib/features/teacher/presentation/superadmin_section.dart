import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/superadmin_repository.dart';

/// In the Sekolah tab of a superadmin only: switch to another school, or
/// register a new one with its first teacher.
class SuperadminSection extends ConsumerWidget {
  const SuperadminSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isSuperadminProvider).value != true) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: scheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Superadmin',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Anda penanggung jawab sekolah ini. Pindah ke sekolah lain, '
                'atau daftarkan sekolah baru dengan penanggung jawab '
                'pertamanya.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('superadmin-switch'),
                    onPressed: () => showSwitchSchoolSheet(context),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Ganti sekolah'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('superadmin-add-school'),
                    onPressed: () => context.push(Routes.teacherAddSchool),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Tambah sekolah'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every school; tapping another one moves the superadmin there.
Future<void> showSwitchSchoolSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SwitchSchoolSheet(),
    );

class _SwitchSchoolSheet extends ConsumerWidget {
  const _SwitchSchoolSheet();

  Future<void> _switch(
    BuildContext context,
    WidgetRef ref,
    SchoolEntry school,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final switched = await runWithProgress(context, () async {
      await ref.read(authRepositoryProvider).switchSchool(school.id);
      return true;
    });
    if (switched != true) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Sekarang di ${school.name}.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(currentSessionProvider.select((s) => s.schoolId));
    final schools = ref.watch(allSchoolsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Ganti sekolah', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: switch (schools) {
              AsyncData(:final value) => ListView(
                controller: controller,
                children: [
                  for (final school in value)
                    ListTile(
                      key: Key('switch-school-${school.id}'),
                      leading: Icon(
                        school.id == current
                            ? Icons.check_circle
                            : Icons.school_outlined,
                        color: school.id == current
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      title: Text(school.name),
                      subtitle: Text(
                        school.suspended
                            ? '${school.id} · ditangguhkan'
                            : school.id,
                      ),
                      enabled: school.id != current,
                      onTap: () => _switch(context, ref, school),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(allSchoolsProvider),
              ),
              _ => const SkeletonList(items: 4, itemHeight: 64),
            },
          ),
        ],
      ),
    );
  }
}
