import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/data/report_repository.dart';
import 'package:sabusaku/core/models/report.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/teacher/presentation/reports_screen.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

final _now = DateTime.now();

final _reports = [
  Report(
    id: 'r1',
    kind: ReportKind.journal,
    reason: ReportReason.harassment,
    target: const ReportTarget.journal(programId: 'p1', date: '2026-10-15'),
    note: 'Menghina teman sekelas.',
    reporterName: 'Sari Wulandari',
    reporterRole: UserRole.guru,
    subjectId: 's1',
    snapshot: const {
      'studentName': 'Raka Pratama',
      'date': '2026-10-15',
      'keyInformation': 'Ikal belajar di sekolah yang hampir roboh.',
    },
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),
  Report(
    id: 'r2',
    kind: ReportKind.book,
    reason: ReportReason.wrongData,
    target: const ReportTarget.book('b1'),
    reporterName: 'Dewi Anggraini',
    reporterRole: UserRole.siswa,
    snapshot: const {
      'title': 'Laskar Pelangi',
      'authors': ['Andrea Hirata'],
    },
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  Report(
    id: 'r3',
    kind: ReportKind.user,
    reason: ReportReason.inappropriate,
    target: const ReportTarget.user('s9'),
    resolved: true,
    reporterName: 'Sari Wulandari',
    reporterRole: UserRole.guru,
    subjectId: 's9',
    snapshot: const {'name': 'Bagas Saputra', 'role': 'siswa'},
    createdAt: _now.subtract(const Duration(days: 2)),
    resolvedAt: _now.subtract(const Duration(days: 1)),
    resolvedByName: 'Sari Wulandari',
    resolution: 'Foto profil sudah diganti.',
  ),
];

void main() {
  late _MockReportRepository repository;

  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    repository = _MockReportRepository();
    when(() => repository.resolve(any(), resolution: any(named: 'resolution')))
        .thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, List<Report> reports) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repository),
          schoolReportsProvider.overrideWith((_) => Stream.value(reports)),
        ],
        child: const MaterialApp(
          locale: Locale('id', 'ID'),
          supportedLocales: [Locale('id', 'ID')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ReportsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('open reports first, resolved ones under "Selesai"', (
    tester,
  ) async {
    await pump(tester, _reports);

    expect(find.byKey(const Key('report-card-0')), findsOneWidget);
    expect(find.byKey(const Key('report-card-1')), findsOneWidget);
    expect(find.byKey(const Key('report-card-2')), findsNothing);
    // Kind, reason, content, note and reporter.
    expect(find.text('Jurnal'), findsOneWidget);
    expect(find.text('Pelecehan atau perundungan'), findsOneWidget);
    expect(find.text('Raka Pratama · 15 Okt 2026'), findsOneWidget);
    expect(
      find.text('Ikal belajar di sekolah yang hampir roboh.'),
      findsOneWidget,
    );
    expect(find.textContaining('Menghina teman sekelas.'), findsOneWidget);
    expect(
      find.textContaining(
        'Dilaporkan oleh Sari Wulandari (Penanggung jawab) · 2 jam lalu',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-open-0')), findsOneWidget);
    expect(find.text('Data buku salah'), findsOneWidget);
    expect(find.text('Laskar Pelangi'), findsOneWidget);
    expect(find.text('Andrea Hirata'), findsOneWidget);
    expect(find.byKey(const Key('report-resolve-0')), findsOneWidget);
    expect(find.byKey(const Key('report-open-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reports-resolved')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-card-0')), findsOneWidget);
    expect(find.byKey(const Key('report-card-1')), findsNothing);
    expect(find.text('Bagas Saputra · Siswa'), findsOneWidget);
    expect(find.textContaining('Selesai oleh Sari Wulandari'), findsOneWidget);
    expect(find.text('Foto profil sudah diganti.'), findsOneWidget);
    expect(find.byKey(const Key('report-resolve-0')), findsNothing);
  });

  testWidgets('"Tandai selesai" asks what was done and resolves', (
    tester,
  ) async {
    await pump(tester, _reports);

    await tester.tap(find.byKey(const Key('report-resolve-0')));
    await tester.pumpAndSettle();
    expect(find.text('Tandai selesai?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('report-resolution')),
      ' Sudah dibicarakan dengan siswa. ',
    );
    await tester.tap(find.byKey(const Key('report-resolve-confirm')));
    await tester.pumpAndSettle();

    verify(
      () => repository.resolve(
        'r1',
        resolution: 'Sudah dibicarakan dengan siswa.',
      ),
    ).called(1);
    expect(find.text('Laporan ditandai selesai.'), findsOneWidget);
  });

  testWidgets('cancelling the dialog resolves nothing', (tester) async {
    await pump(tester, _reports);

    await tester.tap(find.byKey(const Key('report-resolve-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.resolve(any(), resolution: any(named: 'resolution')),
    );
  });

  testWidgets('erased content is not offered to open', (tester) async {
    await pump(tester, [
      _reports.first.copyWith(targetDeleted: true, snapshot: const {}),
    ]);

    expect(find.text('Konten sudah dihapus.'), findsOneWidget);
    expect(find.byKey(const Key('report-open-0')), findsNothing);
    expect(find.byKey(const Key('report-resolve-0')), findsOneWidget);
  });

  testWidgets('no open report says so', (tester) async {
    await pump(tester, [_reports.last]);

    expect(find.text('Tidak ada laporan terbuka'), findsOneWidget);
  });
}
