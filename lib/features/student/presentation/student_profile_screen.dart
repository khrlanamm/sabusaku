import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/presentation/account_section.dart';
import '../../notifications/notification_prompt.dart';
import '../data/student_repository.dart';

/// Statistics, past books and account actions (PRD §4: Profil merges the
/// former Refleksi tab).
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(myStatsProvider).value;
    final programs = ref.watch(myProgramsProvider).value ?? const <Program>[];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AccountSection(),
          const SizedBox(height: 12),
          const NotificationSettingTile(),
          const SizedBox(height: 20),
          Text('Statistik membaca', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total jurnal',
                  value: '${stats?.journalCountTotal ?? 0}',
                  icon: Icons.edit_note,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Buku selesai',
                  value: '${stats?.booksCompleted ?? 0}',
                  icon: Icons.menu_book,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Streak terbaik',
                  value: '${stats?.streakBest ?? 0}',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFD98200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Riwayat buku', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (programs.isEmpty)
            Text(
              'Belum ada buku.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            )
          else
            for (final program in programs)
              ProgramHistoryTile(
                program: program,
                onTap: () =>
                    context.push(Routes.studentProgramJournals(program.id)),
              ),
        ],
      ),
    );
  }
}

/// One book in a reading history, with its month, status and progress.
class ProgramHistoryTile extends StatelessWidget {
  const ProgramHistoryTile({
    super.key,
    required this.program,
    required this.onTap,
  });

  final Program program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, tint) = switch (program.status) {
      ProgramStatus.active => (AppColors.blue, AppColors.sky),
      ProgramStatus.completed => (AppColors.activeText, AppColors.activeTint),
      ProgramStatus.stopped => (AppColors.neutralText, AppColors.neutralTint),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(title: program.book.title, width: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${formatMonth(program.startDate)} · '
                      '${program.journalCount} jurnal · ${program.percent}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        program.status.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
