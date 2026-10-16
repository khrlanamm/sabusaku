import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/errors/app_exception.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/presentation/terms_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(home: TermsScreen()),
      ),
    );
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pump();
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
  }

  testWidgets('summarises the terms and links the full page', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('terms-screen')), findsOneWidget);
    expect(find.text('Ketentuan Penggunaan'), findsOneWidget);
    expect(find.textContaining('menu Laporkan'), findsOneWidget);
    expect(find.byKey(const Key('terms-read-full')), findsOneWidget);
    expect(find.text('Saya setuju'), findsOneWidget);
  });

  testWidgets('"Saya setuju" records the acceptance once', (tester) async {
    final done = Completer<void>();
    when(() => auth.acceptTerms()).thenAnswer((_) => done.future);
    await pump(tester);

    await tapKey(tester, 'terms-accept');
    // Busy until the session moves the router on.
    expect(find.text('Saya setuju'), findsNothing);
    await tapKey(tester, 'terms-accept');
    verify(() => auth.acceptTerms()).called(1);

    done.complete();
    await tester.pump();
  });

  testWidgets('a failure is shown and the button works again', (tester) async {
    when(() => auth.acceptTerms()).thenThrow(
      const AppException(
        AppErrorCode.invalidInput,
        message: 'Ketentuan sudah diperbarui. Muat ulang aplikasi.',
      ),
    );
    await pump(tester);

    await tapKey(tester, 'terms-accept');

    expect(
      find.text('Ketentuan sudah diperbarui. Muat ulang aplikasi.'),
      findsOneWidget,
    );
    expect(find.text('Saya setuju'), findsOneWidget);
  });

  testWidgets('"Keluar" signs out', (tester) async {
    await pump(tester);

    await tapKey(tester, 'terms-sign-out');

    verify(() => auth.signOut()).called(1);
    verifyNever(() => auth.acceptTerms());
  });
}
