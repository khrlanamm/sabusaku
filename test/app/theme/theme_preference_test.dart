import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/app/theme/theme_preference.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the light theme is the default', () async {
    final container = await containerWith({});
    expect(
      container.read(themePreferenceControllerProvider),
      ThemePreference.terang,
    );
    expect(ThemePreference.terang.mode, ThemeMode.light);
  });

  test('a chosen theme is kept on the device', () async {
    final container = await containerWith({});
    await container
        .read(themePreferenceControllerProvider.notifier)
        .set(ThemePreference.gelap);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui.theme'), 'gelap');
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(
      restarted.read(themePreferenceControllerProvider),
      ThemePreference.gelap,
    );
  });

  test('an unknown stored value falls back to light', () async {
    final container = await containerWith({'ui.theme': 'ungu'});
    expect(
      container.read(themePreferenceControllerProvider),
      ThemePreference.terang,
    );
  });
}
