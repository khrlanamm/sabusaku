import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/errors/app_exception.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/auth/presentation/login_screen.dart';

import '../../helpers/sample_password.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    AuthState state = const AuthSignedOut(),
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authStateProvider.overrideWithValue(AsyncData(state)),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );

  testWidgets('empty fields are rejected before calling sign-in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(2));
    verifyNever(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('a malformed email is rejected', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('login-email')), 'bukan-email');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      samplePassword(),
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Format email belum benar'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows the uniform message', (tester) async {
    const typed = 'bukan-yang-benar';
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AppException(AppErrorCode.invalidCredentials));

    await pump(tester);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'raka@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), typed);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Email atau password salah.'), findsOneWidget);
    verify(
      () => auth.signInWithEmail(email: 'raka@example.com', password: typed),
    ).called(1);
  });

  testWidgets('an email without a school sees the administrator dialog', (
    tester,
  ) async {
    await pump(tester, state: const AuthNotRegistered('tamu@example.com'));
    await tester.pumpAndSettle();

    expect(
      find.text('Harap Menghubungi Administrator Sekolah'),
      findsOneWidget,
    );
    expect(find.textContaining('tamu@example.com'), findsOneWidget);
    expect(find.text('Pelajari di sini'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dialog-not-registered-close')));
    await tester.pumpAndSettle();
    verify(() => auth.signOut()).called(1);
  });
}
