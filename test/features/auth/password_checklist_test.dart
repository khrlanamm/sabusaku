import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/app/theme/theme.dart';
import 'package:sabusaku/features/auth/presentation/auth_widgets.dart';

void main() {
  testWidgets('each requirement turns green as the password meets it', (
    tester,
  ) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    addTearDown(password.dispose);
    addTearDown(confirm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Form(
            child: NewPasswordFields(password: password, confirm: confirm),
          ),
        ),
      ),
    );

    int met() => tester
        .widgetList<Icon>(
          find.descendant(
            of: find.byKey(const Key('password-checklist')),
            matching: find.byType(Icon),
          ),
        )
        .where((icon) => icon.icon == Icons.check_circle)
        .length;

    expect(met(), 0);
    await tester.enterText(find.byKey(const Key('password-new')), 'rahasia');
    await tester.pump();
    expect(met(), 0);
    await tester.enterText(find.byKey(const Key('password-new')), 'Rahasia1');
    await tester.pump();
    expect(met(), 3);
    await tester.enterText(find.byKey(const Key('password-new')), 'Rahasia#1');
    await tester.pump();
    expect(met(), 4);

    // The confirmation field has no checklist of its own.
    expect(find.byKey(const Key('password-checklist')), findsOneWidget);
  });
}
