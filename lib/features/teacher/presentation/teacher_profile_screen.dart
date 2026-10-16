import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_section.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extracurriculars = ref.watch(
      currentSessionProvider.select((s) => s.profile.extracurriculars),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AccountSection(),
          const SizedBox(height: 20),
          Text('Ekskul yang dibina', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (extracurriculars.isEmpty)
            Text(
              'Belum ada. Ekskul binaan diatur oleh pengembang Sabu Saku.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in extracurriculars)
                  Chip(
                    avatar: const Icon(Icons.groups_2_outlined, size: 18),
                    label: Text(label),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
