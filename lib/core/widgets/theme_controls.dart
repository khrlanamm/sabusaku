import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_preference.dart';

/// Switches between the light and dark theme in one tap.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('theme-toggle'),
      tooltip: dark ? 'Pakai tema terang' : 'Pakai tema gelap',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(themePreferenceControllerProvider.notifier)
          .set(dark ? ThemePreference.terang : ThemePreference.gelap),
    );
  }
}

/// "Tema" row of the settings: Terang, Gelap or Ikuti perangkat.
class ThemeSettingTile extends ConsumerWidget {
  const ThemeSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themePreferenceControllerProvider);
    return ListTile(
      key: const Key('setting-theme'),
      leading: Icon(current.icon),
      title: const Text('Tema'),
      subtitle: Text(current.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => const _ThemeSheet(),
      ),
    );
  }
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themePreferenceControllerProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Tema', style: theme.textTheme.titleMedium),
            ),
            RadioGroup<ThemePreference>(
              groupValue: current,
              onChanged: (value) {
                if (value == null) return;
                ref.read(themePreferenceControllerProvider.notifier).set(value);
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final option in ThemePreference.values)
                    RadioListTile<ThemePreference>(
                      key: Key('theme-${option.wire}'),
                      value: option,
                      secondary: Icon(option.icon),
                      title: Text(option.label),
                      subtitle: option == ThemePreference.sistem
                          ? const Text('Mengikuti mode gelap di perangkat')
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
