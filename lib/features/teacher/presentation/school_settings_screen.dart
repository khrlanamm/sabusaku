import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/school.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/date_id.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/school_repository.dart';
import '../data/teacher_repository.dart';

const _weekdayNames = [
  'Minggu',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
];

/// School settings that drive streaks and status (PRD BR-11, BR-13).
class SchoolSettingsScreen extends ConsumerWidget {
  const SchoolSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(schoolProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan status')),
      body: AsyncView<School>(
        value: school,
        onRetry: () => ref.invalidate(schoolProvider),
        data: (data) => _SettingsForm(
          // Rebuild the form when another teacher changes the settings.
          key: ValueKey(data.settings),
          school: data,
        ),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key, required this.school});

  final School school;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late SchoolSettings _draft = widget.school.settings;

  bool get _dirty => _draft != widget.school.settings;

  void _toggleWeekday(int weekday, bool neutral) {
    final days = {..._draft.neutralWeekdays};
    neutral ? days.add(weekday) : days.remove(weekday);
    // At least one effective day must remain.
    if (days.length > 6) return;
    setState(
      () => _draft = _draft.copyWith(neutralWeekdays: days.toList()..sort()),
    );
  }

  Future<void> _addHoliday() async {
    final today = DateId.parse(ref.read(wibClockProvider).today());
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime.utc(today.year - 1),
      lastDate: DateTime.utc(today.year + 2, 12, 31),
      helpText: 'Pilih hari libur',
    );
    if (picked == null) return;
    final id = DateId.format(picked);
    if (_draft.holidays.contains(id)) return;
    setState(
      () =>
          _draft = _draft.copyWith(holidays: [..._draft.holidays, id]..sort()),
    );
  }

  Future<void> _save() async {
    final ok = await runWithProgress(context, () async {
      await ref.read(teacherRepositoryProvider).updateSettings(_draft);
      return true;
    });
    if (ok == true && mounted) {
      showSnack(context, 'Pengaturan disimpan. Status siswa dihitung ulang.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hari netral', style: theme.textTheme.titleMedium),
        Text(
          'Hari netral tidak memutus streak dan tidak dihitung dalam ambang '
          'status.',
          style: muted,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var day = 0; day < 7; day++)
              FilterChip(
                label: Text(_weekdayNames[day]),
                selected: _draft.neutralWeekdays.contains(day),
                onSelected: (selected) => _toggleWeekday(day, selected),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Ambang status siswa', style: theme.textTheme.titleMedium),
        Text(
          'Dihitung dalam hari efektif sejak jurnal terakhir.',
          style: muted,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _Stepper(
                label: 'Aktif sampai',
                value: _draft.activeMaxDays,
                min: 1,
                max: 14,
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(
                    activeMaxDays: value,
                    attentionMaxDays: _draft.attentionMaxDays < value
                        ? value
                        : _draft.attentionMaxDays,
                  );
                }),
              ),
              const Divider(),
              _Stepper(
                label: 'Perlu perhatian sampai',
                value: _draft.attentionMaxDays,
                min: _draft.activeMaxDays,
                max: 30,
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(attentionMaxDays: value),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Lebih dari ${_draft.attentionMaxDays} hari: Tidak aktif.',
            style: muted,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Hari libur sekolah',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const Key('settings-add-holiday'),
              onPressed: _draft.holidays.length >= 400 ? null : _addHoliday,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        if (_draft.holidays.isEmpty)
          Text('Belum ada hari libur.', style: muted)
        else
          Card(
            child: Column(
              children: [
                for (final (index, holiday) in _draft.holidays.indexed) ...[
                  if (index > 0) const Divider(),
                  ListTile(
                    dense: true,
                    title: Text(formatDateLong(holiday)),
                    trailing: IconButton(
                      tooltip: 'Hapus hari libur',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(
                        () => _draft = _draft.copyWith(
                          holidays: [
                            for (final item in _draft.holidays)
                              if (item != holiday) item,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('settings-save'),
          onPressed: _dirty ? _save : null,
          child: const Text('Simpan pengaturan'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: 'Kurangi',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$value hari',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Tambah',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
