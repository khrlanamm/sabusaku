import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/app/theme/theme.dart';
import 'package:sabusaku/features/auth/presentation/auth_widgets.dart';

import '../../helpers/sample_password.dart';

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
    await tester.enterText(
      find.byKey(const Key('password-new')),
      samplePassword(upper: false, digit: false, symbol: false, length: 7),
    );
    await tester.pump();
    expect(met(), 0);
    await tester.enterText(
      find.byKey(const Key('password-new')),
      samplePassword(symbol: false, length: 8),
    );
    await tester.pump();
    expect(met(), 3);
    await tester.enterText(
      find.byKey(const Key('password-new')),
      samplePassword(length: 9),
    );
    await tester.pump();
    expect(met(), 4);

    // The confirmation field has no checklist of its own.
    expect(find.byKey(const Key('password-checklist')), findsOneWidget);
  });
}
