import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sabusaku/app/router/routes.dart';
import 'package:sabusaku/core/data/report_repository.dart';
import 'package:sabusaku/core/models/school.dart';
import 'package:sabusaku/core/utils/labels.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/data/school_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/teacher/data/superadmin_repository.dart';
import 'package:sabusaku/features/teacher/data/teacher_repository.dart';
import 'package:sabusaku/features/teacher/presentation/add_school_screen.dart';
import 'package:sabusaku/features/teacher/presentation/school_screen.dart';

const _profile = AppUser(
  uid: 'guru1',
  role: UserRole.guru,
  name: 'Bu Sari',
  email: 'sari@gmail.com',
);

const _teacher = Session(
  uid: 'guru1',
  role: UserRole.guru,
  schoolId: 'sman1',
  profile: _profile,
);

final _superadmin = _teacher.copyWith(superadmin: true);

const _schools = [
  School(id: 'sman1', name: 'SMA Negeri 1'),
  School(id: 'sman2', name: 'SMA Negeri 2', active: false),
];

void main() {
  Future<void> pump(WidgetTester tester, Session session) async {
    final router = GoRouter(
      initialLocation: Routes.teacherSchool,
      routes: [
        GoRoute(
          path: Routes.teacherSchool,
          builder: (_, _) => const SchoolScreen(),
        ),
        GoRoute(
          path: Routes.teacherAddSchool,
          builder: (_, _) => const AddSchoolScreen(),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWithValue(session),
        currentSessionProvider.overrideWithValue(session),
        schoolProvider.overrideWith((_) => Stream.value(_schools.first)),
        openReportCountProvider.overrideWithValue(0),
        schoolTeachersProvider.overrideWith(
          (_) => Stream.value(const [_profile]),
        ),
        pendingTeachersProvider.overrideWith((_) => Stream.value(const [])),
        allSchoolsProvider.overrideWith((_) => Stream.value(_schools)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a teacher sees no way to switch schools', (tester) async {
    await pump(tester, _teacher);
    expect(find.text('SMA Negeri 1'), findsOneWidget);
    expect(find.byKey(const Key('school-switch')), findsNothing);
    expect(find.text('Kode: sman1'), findsNothing);
  });

  testWidgets('the superadmin sees the code and "Ganti"', (tester) async {
    await pump(tester, _superadmin);
    expect(find.text('Kode: sman1'), findsOneWidget);
    expect(find.byKey(const Key('school-switch')), findsOneWidget);
  });

  testWidgets('the picker lists every school and marks the open one', (
    tester,
  ) async {
    await pump(tester, _superadmin);
    await tester.tap(find.byKey(const Key('school-switch')));
    await tester.pumpAndSettle();

    final open = find.byKey(const Key('school-option-sman1'));
    final other = find.byKey(const Key('school-option-sman2'));
    expect(
      find.descendant(of: open, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: other, matching: find.text('Kode: sman2 · Nonaktif')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: other, matching: find.byIcon(Icons.check_circle)),
      findsNothing,
    );

    // Tapping the open school only closes the sheet.
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(open, findsNothing);
    expect(find.text('SMA Negeri 1'), findsOneWidget);
  });

  testWidgets('the add-school form checks its fields', (tester) async {
    await pump(tester, _superadmin);
    await tester.tap(find.byKey(const Key('school-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('school-add-school')));
    await tester.pumpAndSettle();
    expect(find.byType(AddSchoolScreen), findsOneWidget);

    // Spaces are dropped and letters lowered as they are typed.
    await tester.enterText(find.byKey(const Key('add-school-code')), 'SMA N1');
    await tester.enterText(find.byKey(const Key('add-school-name')), 'AB');
    await tester.enterText(
      find.byKey(const Key('add-school-teacher-email')),
      'bukan-email',
    );
    await tester.ensureVisible(find.byKey(const Key('add-school-submit')));
    await tester.tap(find.byKey(const Key('add-school-submit')));
    await tester.pumpAndSettle();

    expect(find.text('sman1'), findsOneWidget);
    expect(find.text('Nama 3–100 karakter'), findsOneWidget);
    expect(find.text('Email tidak valid'), findsOneWidget);
    expect(find.text('Nama wajib diisi'), findsOneWidget);
  });

  test('school codes follow the server rule', () {
    expect(isValidSchoolId('sman1sukodadi'), isTrue);
    expect(isValidSchoolId('ab'), isFalse);
    expect(isValidSchoolId('sman-1'), isFalse);
    expect(isValidSchoolId('SMAN1'), isFalse);
    expect(isValidSchoolId('a' * 31), isFalse);
  });

  test('a superadmin profile is marked', () {
    final profile = AppUser.fromMap('u1', {
      'role': 'guru',
      'name': 'Super',
      'superadmin': true,
    });
    expect(profile.superadmin, isTrue);
    expect(
      AppUser.fromMap('u2', {'role': 'guru', 'name': 'Guru'}).superadmin,
      isFalse,
    );
  });
}
