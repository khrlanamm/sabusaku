import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/features/teacher/data/superadmin_repository.dart';
import 'package:sabusaku/features/teacher/presentation/superadmin_section.dart';

Future<void> _pump(WidgetTester tester, {required bool superadmin}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isSuperadminProvider.overrideWith((ref) async => superadmin),
      ],
      child: const MaterialApp(home: Scaffold(body: SuperadminSection())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('penanggung jawab biasa tidak melihat menu superadmin', (
    tester,
  ) async {
    await _pump(tester, superadmin: false);
    expect(find.text('Superadmin'), findsNothing);
    expect(find.byKey(const Key('superadmin-switch')), findsNothing);
  });

  testWidgets('superadmin bisa ganti sekolah dan menambah sekolah', (
    tester,
  ) async {
    await _pump(tester, superadmin: true);
    expect(find.text('Superadmin'), findsOneWidget);
    expect(find.byKey(const Key('superadmin-switch')), findsOneWidget);
    expect(find.byKey(const Key('superadmin-add-school')), findsOneWidget);
  });
}
