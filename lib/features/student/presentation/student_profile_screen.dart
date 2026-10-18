import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/models/program.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/school_repository.dart';
import '../../auth/presentation/account_section.dart';
import '../../auth/presentation/label_pickers.dart';
import '../../notifications/notification_prompt.dart';
import '../../ranking/domain/badges.dart';
import '../../ranking/presentation/badges.dart';
import '../data/student_repository.dart';

/// The student's account: labels, badges and settings. Statistics and the
/// reading history live on Beranda (docs/07, 18 Oct 2026).
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(myProgramsProvider).value ?? const <Program>[];
    final bestStreak = ref.watch(myStatsProvider).value?.streakBest ?? 0;
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
          Text('Lencana', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          BadgeSummary(
            badges: badgesFor(programs: programs, bestStreak: bestStreak),
            onTap: () => context.push(Routes.studentBadges),
          ),
          const SizedBox(height: 20),
          const AccountSettings(extraSettings: [NotificationSettingTile()]),
        ],
      ),
    );
  }
}

/// The student's class and extracurriculars, with their homeroom teacher and
/// supervisors. Students may change both any time (a class move also moves
/// their journals to the new class label).
class StudentLabelsCard extends ConsumerWidget {
  const StudentLabelsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentSessionProvider.select((s) => s.profile));
    final school = ref.watch(schoolProvider).value;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final homeroom = school?.homerooms[profile.classId];
    String supervised(String label) => switch (school?.supervisors[label]) {
      final names? => '$label (pembina: ${names.join(', ')})',
      null => label,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('profile-labels'),
        leading: const Icon(Icons.class_outlined),
        title: Text('Kelas ${profile.classId ?? '-'}'),
        subtitle: Text(
          [
            if (homeroom != null) 'Wali kelas: ${homeroom.join(', ')}',
            if (profile.extracurriculars.isEmpty)
              'Belum ikut ekstrakurikuler'
            else
              'Ekskul: ${profile.extracurriculars.map(supervised).join(', ')}',
          ].join('\n'),
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
