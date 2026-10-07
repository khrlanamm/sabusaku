import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/data/class_repository.dart';
import 'package:sabusaku/core/models/student_stats.dart';
import 'package:sabusaku/core/models/student_status.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/teacher/data/teacher_repository.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_students_screen.dart';

const _teacher = Session(
  uid: 'guru1',
  role: UserRole.guru,
  schoolId: 'sman1',
  classIds: ['k1', 'k2'],
  profile: AppUser(
    uid: 'guru1',
    role: UserRole.guru,
    name: 'Bu Sari',
    username: 'sari',
    classIds: ['k1', 'k2'],
  ),
);

const _students = [
  StudentStats(
    studentId: 's1',
    name: 'Anisa',
    classId: 'k1',
    className: 'XI IPA 1',
    status: StudentStatus.aktif,
  ),
  StudentStats(
    studentId: 's2',
    name: 'Bima',
    classId: 'k1',
    className: 'XI IPA 1',
    status: StudentStatus.perluPerhatian,
  ),
  StudentStats(
    studentId: 's3',
    name: 'Citra',
    classId: 'k2',
    className: 'XI IPS 1',
    status: StudentStatus.perluPerhatian,
  ),
  StudentStats(
    studentId: 's4',
    name: 'Dimas',
    classId: 'k2',
    className: 'XI IPS 1',
    status: StudentStatus.tidakAktif,
  ),
];

void main() {
  Future<void> pump(WidgetTester tester, {Session session = _teacher}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(session),
          classNamesProvider.overrideWithValue(const {
            'k1': 'XI IPA 1',
            'k2': 'XI IPS 1',
          }),
          teacherStudentsProvider.overrideWith((_) => Stream.value(_students)),
        ],
        child: const MaterialApp(home: TeacherStudentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> visibleNames(WidgetTester tester) => [
    for (final name in ['Anisa', 'Bima', 'Citra', 'Dimas'])
      if (find.text(name).evaluate().isNotEmpty) name,
  ];

  testWidgets('shows every student of the assigned classes', (tester) async {
    await pump(tester);
    expect(visibleNames(tester), ['Anisa', 'Bima', 'Citra', 'Dimas']);
  });

  testWidgets('filters by class and by status, together', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'XI IPS 1'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Citra', 'Dimas']);

    await tester.tap(find.byKey(const Key('students-status-perlu_perhatian')));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Citra']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Semua kelas'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Bima', 'Citra']);
  });

  testWidgets('searches by name and explains an empty result', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'dim');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Dimas']);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), isEmpty);
    expect(find.text('Tidak ada yang cocok'), findsOneWidget);
  });

  testWidgets('a teacher without classes is told so', (tester) async {
    await pump(
      tester,
      session: _teacher.copyWith(
        classIds: const [],
        profile: _teacher.profile.copyWith(classIds: const []),
      ),
    );
    expect(find.text('Belum ada kelas'), findsOneWidget);
  });
}
