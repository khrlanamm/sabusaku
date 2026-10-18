import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/school.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/superadmin_repository.dart';

/// The superadmin's list of schools: open another one, or add a school.
Future<void> showSchoolPicker(BuildContext context, WidgetRef ref) async {
  final picked = await showModalBottomSheet<School>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SchoolPickerSheet(),
  );
  if (picked == null || !context.mounted) return;
  await openSchool(context, ref, picked);
}

/// Opens [school] for the superadmin behind a progress indicator. Returns
/// whether it is open now.
Future<bool> openSchool(
  BuildContext context,
  WidgetRef ref,
  School school,
) async {
  // The screen may rebuild for the new school before this returns.
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(superadminRepositoryProvider);
  final done = await runWithProgress(context, () async {
    await repository.switchSchool(school.id);
    return true;
  });
  if (done != true) return false;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Sekarang di ${school.name}.')));
  return true;
}

/// Pops with the school picked; "Tambah sekolah" opens the form instead.
class SchoolPickerSheet extends ConsumerWidget {
  const SchoolPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schools = ref.watch(allSchoolsProvider);
    final current = ref.watch(
      currentSessionProvider.select((session) => session.schoolId),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Ganti sekolah', style: theme.textTheme.titleMedium),
            ),
            Flexible(
              child: switch (schools) {
                AsyncData(:final value) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final school in value)
                      ListTile(
                        key: Key('school-option-${school.id}'),
                        leading: const Icon(Icons.school_outlined),
                        title: Text(school.name),
                        subtitle: Text(
                          [
                            'Kode: ${school.id}',
                            if (!school.active) 'Nonaktif',
                          ].join(' · '),
                        ),
                        trailing: school.id == current
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () =>
                            Navigator.of(context)
                                .pop(school.id == current ? null : school),
                      ),
                  ],
                ),
                AsyncError(:final error) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ErrorState(error: error),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton.icon(
                key: const Key('school-add-school'),
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(Routes.teacherAddSchool);
                },
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Tambah sekolah'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
