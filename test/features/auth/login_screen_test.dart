import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sabusaku/core/errors/app_exception.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/presentation/login_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
    when(() => auth.rememberedSchoolCode).thenReturn('sman1');
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );

  testWidgets('prefills the remembered school code', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextFormField, 'sman1'), findsOneWidget);
  });

  testWidgets('empty fields are rejected before calling sign-in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(2));
    verifyNever(
      () => auth.signIn(
        schoolCode: any(named: 'schoolCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('a failed sign-in shows the uniform message', (tester) async {
    const typed = 'bukan-yang-benar';
    when(
      () => auth.signIn(
        schoolCode: any(named: 'schoolCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AppException(AppErrorCode.invalidCredentials));

    await pump(tester);
    await tester.enterText(find.byKey(const Key('login-username')), '1001');
    await tester.enterText(find.byKey(const Key('login-password')), typed);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(
      find.text('Kode sekolah, username, atau password salah.'),
      findsOneWidget,
    );
    verify(
      () => auth.signIn(schoolCode: 'sman1', username: '1001', password: typed),
    ).called(1);
  });
}
