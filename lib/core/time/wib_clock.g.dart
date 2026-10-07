// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wib_clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wibClock)
final wibClockProvider = WibClockProvider._();

final class WibClockProvider
    extends $FunctionalProvider<WibClock, WibClock, WibClock>
    with $Provider<WibClock> {
  WibClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wibClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wibClockHash();

  @$internal
  @override
  $ProviderElement<WibClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WibClock create(Ref ref) {
    return wibClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WibClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WibClock>(value),
    );
  }
}

String _$wibClockHash() => r'bd1a204653cbb5e1f335e58e18d72b66023a9fe8';
