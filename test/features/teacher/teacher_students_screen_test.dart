import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/member.dart';
import 'package:sabusaku/core/models/school.dart';
import 'package:sabusaku/core/models/student_stats.dart';
import 'package:sabusaku/core/models/student_status.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/data/school_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/teacher/data/teacher_repository.dart';
import 'package:sabusaku/features/teacher/presentation/teacher_students_screen.dart';

const _teacher = Session(
  uid: 'guru1',
  role: UserRole.guru,
  schoolId: 'sman1',
  profile: AppUser(
    uid: 'guru1',
    role: UserRole.guru,
    name: 'Bu Sari',
    email: 'sari@gmail.com',
  ),
);

const _school = School(
  id: 'sman1',
  name: 'SMA Negeri 1',
  classes: ['XI-A1', 'XI-B1'],
  extracurriculars: ['Masis-KIR', 'PMR'],
);

const _students = [
  StudentStats(
    studentId: 's1',
    name: 'Anisa',
    email: 'anisa@gmail.com',
    classId: 'XI-A1',
    extracurriculars: ['Masis-KIR'],
    status: StudentStatus.aktif,
  ),
  StudentStats(
    studentId: 's2',
    name: 'Bima',
    email: 'bima@gmail.com',
    classId: 'XI-A1',
    status: StudentStatus.perluPerhatian,
  ),
  StudentStats(
    studentId: 's3',
    name: 'Citra',
    email: 'citra@gmail.com',
    classId: 'XI-B1',
    extracurriculars: ['Masis-KIR', 'PMR'],
    status: StudentStatus.perluPerhatian,
  ),
  StudentStats(
    studentId: 's4',
    name: 'Dimas',
    email: 'dimas@gmail.com',
    classId: 'XI-B1',
    status: StudentStatus.tidakAktif,
  ),
];

const _pending = [
  Member(
    email: 'eka@gmail.com',
    schoolId: 'sman1',
    role: UserRole.siswa,
    name: 'Eka',
    classId: 'XI-B1',
  ),
];

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<StudentStats> students = _students,
    List<Member> pending = _pending,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWithValue(_teacher),
          schoolProvider.overrideWith((_) => Stream.value(_school)),
          teacherStudentsProvider.overrideWith((_) => Stream.value(students)),
          pendingStudentsProvider.overrideWith((_) => Stream.value(pending)),
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

  Future<void> pickMenu(WidgetTester tester, String key, String item) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows every student of the school and who has not signed in', (
    tester,
  ) async {
    await pump(tester);
    expect(visibleNames(tester), ['Anisa', 'Bima', 'Citra', 'Dimas']);
    expect(find.text('Belum masuk (1)'), findsOneWidget);
  });

  testWidgets('filters by class, extracurricular and status, together', (
    tester,
  ) async {
    await pump(tester);

    await pickMenu(tester, 'students-class-filter', 'XI-B1');
    expect(visibleNames(tester), ['Citra', 'Dimas']);
    expect(find.text('Belum masuk (1)'), findsOneWidget);

    await pickMenu(tester, 'students-ekskul-filter', 'Masis-KIR');
    expect(visibleNames(tester), ['Citra']);
    // Eka has no extracurricular.
    expect(find.textContaining('Belum masuk'), findsNothing);

    await pickMenu(tester, 'students-class-filter', 'Semua kelas');
    expect(visibleNames(tester), ['Anisa', 'Citra']);

    await tester.tap(find.byKey(const Key('students-status-perlu_perhatian')));
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Citra']);
  });

  testWidgets('searches by name or email and explains an empty result', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'dim');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Dimas']);

    await tester.enterText(find.byType(TextField), 'citra@');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), ['Citra']);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(visibleNames(tester), isEmpty);
    expect(find.text('Tidak ada yang cocok'), findsOneWidget);
  });

  testWidgets('an empty school says how to add students', (tester) async {
    await pump(tester, students: const [], pending: const []);
    expect(find.text('Belum ada siswa'), findsOneWidget);
    expect(find.byKey(const Key('students-add')), findsOneWidget);
  });
}
