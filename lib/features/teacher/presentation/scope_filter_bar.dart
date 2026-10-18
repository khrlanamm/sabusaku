import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/teacher_repository.dart';
import '../domain/student_scope.dart';

/// Chips that pick the [DashboardScope]: every student, the teacher's own
/// ("Binaan saya", only when they have a group), one class or one
/// extracurricular. Shared by the dashboard and the pages its cards open, so
/// the scope follows the teacher between them.
class ScopeFilterBar extends ConsumerWidget {
  const ScopeFilterBar({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(effectiveDashboardScopeProvider);
    final options = ref.watch(scopeOptionsProvider);
    final hasGroup = ref.watch(
      currentSessionProvider.select((session) => session.profile.hasGroup),
    );
    final notifier = ref.read(dashboardScopeProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          _ScopeChip(
            key: const Key('scope-all'),
            label: 'Semua siswa',
            selected: scope is AllStudents,
            onSelected: () => notifier.set(const AllStudents()),
          ),
          if (hasGroup)
            _ScopeChip(
              key: const Key('scope-mine'),
              label: 'Binaan saya',
              icon: Icons.star_outline,
              selected: scope is MyStudents,
              onSelected: () => notifier.set(const MyStudents()),
            ),
          if (options.classes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterMenuChip(
                key: const Key('scope-class'),
                label: 'Kelas',
                value: scope is ClassScope ? scope.label : null,
                display: (label) => 'Kelas $label',
                options: options.classes,
                onChanged: (label) => notifier.set(
                  label == null ? const AllStudents() : ClassScope(label),
                ),
              ),
            ),
          if (options.extracurriculars.isNotEmpty)
            FilterMenuChip(
              key: const Key('scope-ekskul'),
              label: 'Ekskul',
              value: scope is ExtracurricularScope ? scope.label : null,
              options: options.extracurriculars,
              onChanged: (label) => notifier.set(
                label == null
                    ? const AllStudents()
                    : ExtracurricularScope(label),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: ChoiceChip(
          avatar: icon == null ? null : Icon(icon, size: 18),
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
        ),
      ),
    );
  }
}

/// A chip that opens a menu of [options]. Shows [label] until a value is
/// picked, then the value (through [display]). With [clearLabel], the menu
/// starts with an item that clears the value.
class FilterMenuChip extends StatelessWidget {
  const FilterMenuChip({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.clearLabel,
    this.display,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? clearLabel;
  final String Function(String value)? display;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = this.value;
    return Center(
      child: PopupMenuButton<String>(
        tooltip: label,
        initialValue: value ?? '',
        onSelected: (selected) => onChanged(selected.isEmpty ? null : selected),
        itemBuilder: (_) => [
          if (clearLabel != null)
            PopupMenuItem(value: '', child: Text(clearLabel!)),
          for (final option in options)
            PopupMenuItem(value: option, child: Text(option)),
        ],
        child: Chip(
          avatar: Icon(
            Icons.filter_list,
            size: 18,
            color: value == null ? scheme.onSurfaceVariant : scheme.primary,
          ),
          label: Text(value == null ? label : (display?.call(value) ?? value)),
          backgroundColor: value == null ? null : scheme.secondaryContainer,
        ),
      ),
    );
  }
}
