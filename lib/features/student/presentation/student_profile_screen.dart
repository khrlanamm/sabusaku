import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_section.dart';
import '../../auth/presentation/label_pickers.dart';
import '../../notifications/notification_prompt.dart';
import '../data/student_repository.dart';
import '../domain/reading_rules.dart';

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
          const AccountHeader(),
          const SizedBox(height: 12),
          const StudentLabelsCard(),
          const SizedBox(height: 20),
          Text('Statistik membaca', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          StatCardRow(
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
                  color: context.palette.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Streak terbaik',
                  value: '${stats?.streakBest ?? 0}',
                  icon: Icons.local_fire_department,
                  color: context.palette.streak,
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final program in programs)
              ProgramHistoryTile(
                program: program,
                onTap: () =>
                    context.push(Routes.studentProgramJournals(program.id)),
              ),
          const SizedBox(height: 20),
          const AccountSettings(extraSettings: [NotificationSettingTile()]),
        ],
      ),
    );
  }
}

/// The student's class and extracurriculars. Students may change both any
/// time (a class move also moves their journals to the new class label).
class StudentLabelsCard extends ConsumerWidget {
  const StudentLabelsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentSessionProvider.select((s) => s.profile));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('profile-labels'),
        leading: const Icon(Icons.class_outlined),
        title: Text('Kelas ${profile.classId ?? '-'}'),
        subtitle: Text(
          profile.extracurriculars.isEmpty
              ? 'Belum ikut ekstrakurikuler'
              : 'Ekskul: ${profile.extracurriculars.join(', ')}',
          style: muted,
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _LabelsSheet(),
        ),
      ),
    );
  }
}

class _LabelsSheet extends ConsumerStatefulWidget {
  const _LabelsSheet();

  @override
  ConsumerState<_LabelsSheet> createState() => _LabelsSheetState();
}

class _LabelsSheetState extends ConsumerState<_LabelsSheet> {
  final _formKey = GlobalKey<FormState>();
  late String? _classId;
  late List<String> _extracurriculars;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentSessionProvider).profile;
    _classId = profile.classId;
    _extracurriculars = [...profile.extracurriculars];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(currentSessionProvider);
    final profile = session.profile;
    final sameLabels =
        _extracurriculars.length == profile.extracurriculars.length &&
        _extracurriculars.every(profile.extracurriculars.contains);
    final saved = await runWithProgress(context, () async {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            session,
            classId: _classId == profile.classId ? null : _classId,
            extracurriculars: sameLabels ? null : _extracurriculars,
          );
      return true;
    });
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kelas dan ekstrakurikuler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ClassLabelField(
              value: _classId,
              onChanged: (value) => setState(() => _classId = value),
            ),
            const SizedBox(height: 18),
            ExtracurricularChips(
              value: _extracurriculars,
              onChanged: (value) => setState(() => _extracurriculars = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('labels-save'),
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
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
    final completedDate = program.completedDate;
    final (color, tint) = switch (program.status) {
      ProgramStatus.active => (
        Theme.of(context).colorScheme.primary,
        context.palette.infoTint,
      ),
      ProgramStatus.completed => (
        context.palette.activeText,
        context.palette.activeTint,
      ),
      ProgramStatus.stopped => (
        context.palette.neutralText,
        context.palette.neutralTint,
      ),
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
              BookCover(
                title: program.book.title,
                coverUrl: program.book.coverUrl,
                width: 44,
              ),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                        // Read as one phrase with the "Selesai" chip.
                        if (program.status == ProgramStatus.completed &&
                            completedDate != null)
                          Text(
                            '${formatDayMonthLong(completedDate)} · '
                            'Lama membaca: ${readingDays(startDate: program.startDate, endDate: completedDate)} hari',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
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
