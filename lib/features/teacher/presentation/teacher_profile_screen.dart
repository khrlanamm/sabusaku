import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/data/class_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_section.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classIds = ref.watch(currentSessionProvider).classIds;
    final classNames = ref.watch(classNamesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AccountSection(),
          const SizedBox(height: 20),
          Text('Kelas yang dipantau', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (classIds.isEmpty)
            Text(
              'Belum ada. Penugasan kelas diatur oleh admin sekolah.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final (index, id) in classIds.indexed) ...[
                    if (index > 0) const Divider(),
                    ListTile(
                      leading: const Icon(Icons.class_outlined),
                      title: Text(classNames[id] ?? 'Kelas'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
