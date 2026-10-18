import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/palette.dart';
import '../../../core/models/program.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/states.dart';
import '../../student/data/student_repository.dart';
import '../domain/badges.dart';

IconData badgeIcon(BadgeKind kind) => switch (kind) {
  BadgeKind.books => Icons.menu_book,
  BadgeKind.streak => Icons.local_fire_department,
  BadgeKind.journals => Icons.edit_note,
  BadgeKind.onTime => Icons.event_available,
  BadgeKind.reviews => Icons.rate_review,
};

/// A badge's medallion: coloured once earned, grey before.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.progress, this.size = 48});

  final BadgeProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (color, tint) = progress.earned
        ? switch (progress.badge.kind) {
            BadgeKind.streak => (palette.attentionText, palette.attentionTint),
            BadgeKind.books => (palette.activeText, palette.activeTint),
            _ => (palette.info, palette.infoTint),
          }
        : (palette.neutralText, palette.neutralTint);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
      child: Icon(
        progress.earned ? badgeIcon(progress.badge.kind) : Icons.lock_outline,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.progress});

  final BadgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = progress.badge;
    return Card(
      key: ValueKey('badge-${badge.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            BadgeMedal(progress: progress),
            const SizedBox(height: 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (progress.earned)
              Text(
                'Didapat',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.palette.activeText,
                  fontWeight: FontWeight.w700,
                ),
              )
            else ...[
              AppProgressBar(percent: (progress.fraction * 100).floor()),
              const SizedBox(height: 4),
              Text(
                '${progress.value}/${badge.target}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// All badges in a grid, earned ones first.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.badges});

  final List<BadgeProgress> badges;

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...badges.where((progress) => progress.earned),
      ...badges.where((progress) => !progress.earned),
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 196,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, index) => BadgeTile(progress: sorted[index]),
    );
  }
}

/// "4 dari 12 lencana" with the earned medallions, for Profil and a
/// teacher's view of a student.
class BadgeSummary extends StatelessWidget {
  const BadgeSummary({super.key, required this.badges, this.onTap});

  final List<BadgeProgress> badges;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = badges.where((progress) => progress.earned).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('badge-summary'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${earned.length} dari ${badges.length} lencana',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              if (earned.isEmpty)
                Text(
                  'Selesaikan buku pertama atau jaga streak 7 hari untuk '
                  'lencana pertama.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final progress in earned)
                      Tooltip(
                        message: progress.badge.title,
                        child: BadgeMedal(progress: progress, size: 40),
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

/// The student's own badges (Profil → Lencana).
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(myProgramsProvider);
    final bestStreak = ref.watch(myStatsProvider).value?.streakBest ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Lencana')),
      body: AsyncView<List<Program>>(
        value: programs,
        onRetry: () => ref.invalidate(myProgramsProvider),
        data: (all) => BadgeGrid(
          badges: badgesFor(programs: all, bestStreak: bestStreak),
        ),
      ),
    );
  }
}
