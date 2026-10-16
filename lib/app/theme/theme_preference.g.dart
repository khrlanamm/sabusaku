// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_preference.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemePreferenceController)
final themePreferenceControllerProvider = ThemePreferenceControllerProvider._();

final class ThemePreferenceControllerProvider
    extends $NotifierProvider<ThemePreferenceController, ThemePreference> {
  ThemePreferenceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themePreferenceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themePreferenceControllerHash();

  @$internal
  @override
  ThemePreferenceController create() => ThemePreferenceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemePreference value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemePreference>(value),
    );
  }
}

String _$themePreferenceControllerHash() =>
    r'a7852ba3e2cdff63def20b546435ba2a36f5b2d4';

abstract class _$ThemePreferenceController extends $Notifier<ThemePreference> {
  ThemePreference build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemePreference, ThemePreference>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemePreference, ThemePreference>,
              ThemePreference,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
