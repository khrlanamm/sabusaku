// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'e0ff8db0dbbe87c1ad7078d87df9d0459229ce8f';

@ProviderFor(usersByRole)
final usersByRoleProvider = UsersByRoleFamily._();

final class UsersByRoleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          Stream<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $StreamProvider<List<AppUser>> {
  UsersByRoleProvider._({
    required UsersByRoleFamily super.from,
    required UserRole super.argument,
  }) : super(
         retry: null,
         name: r'usersByRoleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$usersByRoleHash();

  @override
  String toString() {
    return r'usersByRoleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppUser>> create(Ref ref) {
    final argument = this.argument as UserRole;
    return usersByRole(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByRoleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$usersByRoleHash() => r'13caa11b27cbeaea2c90366b073242f035473b08';

final class UsersByRoleFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<AppUser>>, UserRole> {
  UsersByRoleFamily._()
    : super(
        retry: null,
        name: r'usersByRoleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UsersByRoleProvider call(UserRole role) =>
      UsersByRoleProvider._(argument: role, from: this);

  @override
  String toString() => r'usersByRoleProvider';
}

@ProviderFor(userById)
final userByIdProvider = UserByIdFamily._();

final class UserByIdProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  UserByIdProvider._({
    required UserByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userByIdHash();

  @override
  String toString() {
    return r'userByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    final argument = this.argument as String;
    return userById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userByIdHash() => r'c43194ba7d95c1299103ce47235e53469464a770';

final class UserByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<AppUser?>, String> {
  UserByIdFamily._()
    : super(
        retry: null,
        name: r'userByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserByIdProvider call(String uid) =>
      UserByIdProvider._(argument: uid, from: this);

  @override
  String toString() => r'userByIdProvider';
}

@ProviderFor(adminCounts)
final adminCountsProvider = AdminCountsProvider._();

final class AdminCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminCounts>,
          AdminCounts,
          FutureOr<AdminCounts>
        >
    with $FutureModifier<AdminCounts>, $FutureProvider<AdminCounts> {
  AdminCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminCountsHash();

  @$internal
  @override
  $FutureProviderElement<AdminCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminCounts> create(Ref ref) {
    return adminCounts(ref);
  }
}

String _$adminCountsHash() => r'1c3c9fe713b5a80bdf9aadf560b92dec9e4e5bf7';
