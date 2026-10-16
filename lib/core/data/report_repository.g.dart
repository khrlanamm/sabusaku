// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportRepository)
final reportRepositoryProvider = ReportRepositoryProvider._();

final class ReportRepositoryProvider
    extends
        $FunctionalProvider<
          ReportRepository,
          ReportRepository,
          ReportRepository
        >
    with $Provider<ReportRepository> {
  ReportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReportRepository create(Ref ref) {
    return reportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportRepository>(value),
    );
  }
}

String _$reportRepositoryHash() => r'2aaf0cc0d5e0cac8a3194d81d1fb83f7c53db59e';

/// Every report of the school, newest first (penanggung jawab only).

@ProviderFor(schoolReports)
final schoolReportsProvider = SchoolReportsProvider._();

/// Every report of the school, newest first (penanggung jawab only).

final class SchoolReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Report>>,
          List<Report>,
          Stream<List<Report>>
        >
    with $FutureModifier<List<Report>>, $StreamProvider<List<Report>> {
  /// Every report of the school, newest first (penanggung jawab only).
  SchoolReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schoolReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schoolReportsHash();

  @$internal
  @override
  $StreamProviderElement<List<Report>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Report>> create(Ref ref) {
    return schoolReports(ref);
  }
}

String _$schoolReportsHash() => r'90d86d22a1b288f4f8d7dd5daba96932e49d5b12';

/// Reports still waiting for a penanggung jawab.

@ProviderFor(openReportCount)
final openReportCountProvider = OpenReportCountProvider._();

/// Reports still waiting for a penanggung jawab.

final class OpenReportCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Reports still waiting for a penanggung jawab.
  OpenReportCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openReportCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openReportCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return openReportCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$openReportCountHash() => r'78abd34b2b1fa56962d835fea6fe4603fa95d0d8';
