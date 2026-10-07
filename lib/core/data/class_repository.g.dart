// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every class of the school, archived ones included, sorted by name.
/// Readable by all members of the school.

@ProviderFor(classes)
final classesProvider = ClassesProvider._();

/// Every class of the school, archived ones included, sorted by name.
/// Readable by all members of the school.

final class ClassesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SchoolClass>>,
          List<SchoolClass>,
          Stream<List<SchoolClass>>
        >
    with
        $FutureModifier<List<SchoolClass>>,
        $StreamProvider<List<SchoolClass>> {
  /// Every class of the school, archived ones included, sorted by name.
  /// Readable by all members of the school.
  ClassesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classesHash();

  @$internal
  @override
  $StreamProviderElement<List<SchoolClass>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SchoolClass>> create(Ref ref) {
    return classes(ref);
  }
}

String _$classesHash() => r'0899dc7eb91f2f7c1d499a63df52446aa4c30862';

/// Class names by ID, for labels.

@ProviderFor(classNames)
final classNamesProvider = ClassNamesProvider._();

/// Class names by ID, for labels.

final class ClassNamesProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Class names by ID, for labels.
  ClassNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classNamesHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return classNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$classNamesHash() => r'047319f480d626908e89a795781c037264019213';
