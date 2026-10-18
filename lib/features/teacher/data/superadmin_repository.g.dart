// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(superadminRepository)
final superadminRepositoryProvider = SuperadminRepositoryProvider._();

final class SuperadminRepositoryProvider
    extends
        $FunctionalProvider<
          SuperadminRepository,
          SuperadminRepository,
          SuperadminRepository
        >
    with $Provider<SuperadminRepository> {
  SuperadminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'superadminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$superadminRepositoryHash();

  @$internal
  @override
  $ProviderElement<SuperadminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SuperadminRepository create(Ref ref) {
    return superadminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SuperadminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SuperadminRepository>(value),
    );
  }
}

String _$superadminRepositoryHash() =>
    r'233e51d689d5740afc9be1e8d140c4b530c56f76';

/// Every school, for the superadmin's school picker.

@ProviderFor(allSchools)
final allSchoolsProvider = AllSchoolsProvider._();

/// Every school, for the superadmin's school picker.

final class AllSchoolsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<School>>,
          List<School>,
          Stream<List<School>>
        >
    with $FutureModifier<List<School>>, $StreamProvider<List<School>> {
  /// Every school, for the superadmin's school picker.
  AllSchoolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allSchoolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allSchoolsHash();

  @$internal
  @override
  $StreamProviderElement<List<School>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<School>> create(Ref ref) {
    return allSchools(ref);
  }
}

String _$allSchoolsHash() => r'b266cb3d8c6897b476fd39701cbecfcfe7ddc73e';
