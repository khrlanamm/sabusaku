// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One period's board of the user's school (server-written, docs/02 §3.17).
/// A period without a board yet is an empty one.

@ProviderFor(leaderboard)
final leaderboardProvider = LeaderboardFamily._();

/// One period's board of the user's school (server-written, docs/02 §3.17).
/// A period without a board yet is an empty one.

final class LeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<Leaderboard>,
          Leaderboard,
          Stream<Leaderboard>
        >
    with $FutureModifier<Leaderboard>, $StreamProvider<Leaderboard> {
  /// One period's board of the user's school (server-written, docs/02 §3.17).
  /// A period without a board yet is an empty one.
  LeaderboardProvider._({
    required LeaderboardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leaderboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leaderboardHash();

  @override
  String toString() {
    return r'leaderboardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Leaderboard> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Leaderboard> create(Ref ref) {
    final argument = this.argument as String;
    return leaderboard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leaderboardHash() => r'f6fb078df7fe5c1f1a355d1b9adf9d61c8773100';

/// One period's board of the user's school (server-written, docs/02 §3.17).
/// A period without a board yet is an empty one.

final class LeaderboardFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Leaderboard>, String> {
  LeaderboardFamily._()
    : super(
        retry: null,
        name: r'leaderboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One period's board of the user's school (server-written, docs/02 §3.17).
  /// A period without a board yet is an empty one.

  LeaderboardProvider call(String periodId) =>
      LeaderboardProvider._(argument: periodId, from: this);

  @override
  String toString() => r'leaderboardProvider';
}
