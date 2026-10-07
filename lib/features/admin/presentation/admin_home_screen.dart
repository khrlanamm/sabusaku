import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/models/student_status.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/school_repository.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

/// Numbers only: an admin never reads journal text (PRD §2).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final school = ref.watch(schoolProvider).value;
    final counts = ref.watch(adminCountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminCountsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Halo, ${session.profile.name}',
              style: theme.textTheme.titleLarge,
            ),
            if (school != null)
              Text(
                school.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            const SizedBox(height: 16),
            AsyncView<AdminCounts>(
              value: counts,
              onRetry: () => ref.invalidate(adminCountsProvider),
              loading: const SkeletonList(items: 2, itemHeight: 120),
              data: (data) => _Counts(counts: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.counts});

  final AdminCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Siswa',
                value: '${counts.students}',
                icon: Icons.school,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Guru',
                value: '${counts.teachers}',
                icon: Icons.person,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Kelas',
                value: '${counts.classes}',
                icon: Icons.class_,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Aktivitas membaca siswa', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Dihitung dari hari efektif sejak jurnal terakhir.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (final (index, status) in StudentStatus.values.indexed) ...[
                if (index > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      StatusChip(status: status),
                      const Spacer(),
                      Text(
                        '${counts.byStatus[status] ?? 0}',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
