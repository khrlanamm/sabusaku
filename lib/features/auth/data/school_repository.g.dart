// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's school document.

@ProviderFor(school)
final schoolProvider = SchoolProvider._();

/// The signed-in user's school document.

final class SchoolProvider
    extends $FunctionalProvider<AsyncValue<School>, School, Stream<School>>
    with $FutureModifier<School>, $StreamProvider<School> {
  /// The signed-in user's school document.
  SchoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schoolProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schoolHash();

  @$internal
  @override
  $StreamProviderElement<School> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<School> create(Ref ref) {
    return school(ref);
  }
}

String _$schoolHash() => r'8f30b3da3bf6b3eefc4344e500c89f372bffc152';
