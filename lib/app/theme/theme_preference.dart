import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/prefs.dart';

part 'theme_preference.g.dart';

/// The user's theme choice, kept per device. Light unless they pick another.
enum ThemePreference {
  terang('terang', 'Terang', ThemeMode.light, Icons.light_mode_outlined),
  gelap('gelap', 'Gelap', ThemeMode.dark, Icons.dark_mode_outlined),
  sistem(
    'sistem',
    'Ikuti perangkat',
    ThemeMode.system,
    Icons.brightness_auto_outlined,
  );

  const ThemePreference(this.wire, this.label, this.mode, this.icon);

  final String wire;
  final String label;
  final ThemeMode mode;
  final IconData icon;

  static ThemePreference fromWire(String? value) => values.firstWhere(
    (preference) => preference.wire == value,
    orElse: () => terang,
  );
}

@Riverpod(keepAlive: true)
class ThemePreferenceController extends _$ThemePreferenceController {
  static const _key = 'ui.theme';

  @override
  ThemePreference build() {
    try {
      return ThemePreference.fromWire(
        ref.watch(sharedPreferencesProvider).getString(_key),
      );
    } catch (_) {
      return ThemePreference.terang;
    }
  }

  Future<void> set(ThemePreference preference) async {
    state = preference;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_key, preference.wire);
    } catch (_) {
      // Not persisted; the choice still applies until the app restarts.
    }
  }
}
