import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/labels.dart';
import '../data/school_repository.dart';

/// Picks one class label from the school's list (`School.classes`).
///
/// [options] overrides the school's list, e.g. in tests.
class ClassLabelField extends ConsumerWidget {
  const ClassLabelField({
    super.key,
    required this.value,
    required this.onChanged,
    this.options,
    this.required = true,
    this.label = 'Kelas',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String>? options;
  final bool required;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = options == null ? ref.watch(schoolProvider).value : null;
    final labels = {...?options ?? school?.classes, ?value}.toList()
      ..sort(compareClassLabels);
    final empty = labels.isEmpty;

    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      key: const Key('field-class'),
      initialValue: value,
      isExpanded: true,
      // Same text style as the text fields next to it, not a title.
      style: theme.textTheme.bodyLarge,
      dropdownColor: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.class_outlined),
        helperText: empty
            ? 'Belum ada daftar kelas. Hubungi penanggung jawab sekolah.'
            : null,
      ),
      items: [
        if (!required)
          const DropdownMenuItem<String>(child: Text('Belum ditentukan')),
        for (final item in labels)
          DropdownMenuItem<String>(value: item, child: Text(item)),
      ],
      onChanged: empty ? null : onChanged,
      validator: required
          ? (selected) => selected == null ? 'Pilih kelas' : null
          : null,
    );
  }
}

/// Picks zero or more extracurriculars from the school's list
/// (`School.extracurriculars`).
class ExtracurricularChips extends ConsumerWidget {
  const ExtracurricularChips({
    super.key,
    required this.value,
    required this.onChanged,
    this.options,
  });

  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final List<String>? options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = options == null ? ref.watch(schoolProvider).value : null;
    // Keeps a label that was removed from the school list visible so it can
    // be unselected.
    final labels = {...?options ?? school?.extracurriculars, ...value};
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ekstrakurikuler', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Boleh lebih dari satu, boleh juga tidak ada.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (labels.isEmpty)
          Text(
            'Belum ada daftar ekstrakurikuler.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final item in labels)
                FilterChip(
                  key: Key('ekskul-$item'),
                  label: Text(item),
                  selected: value.contains(item),
                  onSelected: (selected) => onChanged(
                    selected
                        ? [...value, item]
                        : value.where((other) => other != item).toList(),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
