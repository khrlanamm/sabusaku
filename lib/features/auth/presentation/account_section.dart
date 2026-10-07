import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/widgets/dialogs.dart';
import '../../notifications/notification_service.dart';
import '../data/auth_repository.dart';
import '../data/school_repository.dart';

/// Who is signed in, plus "Ubah password" and "Keluar". Shared by every role.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final school = ref.watch(schoolProvider).value;
    final theme = Theme.of(context);
    final profile = session.profile;
    final initial = profile.name.isEmpty
        ? '?'
        : profile.name.characters.first.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.sky,
                  child: Text(
                    initial,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${session.role.label} · ${profile.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      if (school != null)
                        Text(
                          school.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Ubah password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.changePassword),
              ),
              const Divider(),
              ListTile(
                key: const Key('account-signout'),
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Keluar',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Keluar dari akun?',
                    message: 'Kamu perlu masuk lagi untuk memakai aplikasi.',
                    confirmLabel: 'Keluar',
                    destructive: true,
                  );
                  if (!confirmed) return;
                  // So this account's notifications stop reaching the phone.
                  await ref
                      .read(notificationServiceProvider)
                      .unregisterDevice();
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
