import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/teacher/domain/student_scope.dart';

const _none = AppUser(uid: 'g1', role: UserRole.guru, name: 'Bu Sari');
const _homeroom = AppUser(
  uid: 'g1',
  role: UserRole.guru,
  name: 'Bu Sari',
  homeroomClass: 'XI-A1',
);
const _both = AppUser(
  uid: 'g1',
  role: UserRole.guru,
  name: 'Bu Sari',
  homeroomClass: 'XI-A1',
  extracurriculars: ['PMR', 'Pala'],
);
const ScopeOptions _options = (
  classes: ['XI-A1', 'XI-B1'],
  extracurriculars: ['Masis-KIR', 'PMR'],
);

void main() {
  test('every student, one class or one extracurricular', () {
    expect(const AllStudents().matches(null, const [], _none), isTrue);
    expect(const ClassScope('XI-A1').matches('XI-A1', const [], _none), isTrue);
    expect(
      const ClassScope('XI-A1').matches('XI-B1', const [], _none),
      isFalse,
    );
    expect(
      const ExtracurricularScope('PMR').matches('XI-B1', const ['PMR'], _none),
      isTrue,
    );
    expect(
      const ExtracurricularScope('PMR').matches('XI-A1', const [], _none),
      isFalse,
    );
  });

  test('"Binaan saya": the homeroom class or a supervised extracurricular', () {
    const mine = MyStudents();
    expect(mine.matches('XI-A1', const [], _homeroom), isTrue);
    expect(mine.matches('XI-B1', const ['PMR'], _homeroom), isFalse);
    expect(mine.matches('XI-B1', const ['Masis-KIR', 'Pala'], _both), isTrue);
    expect(mine.matches('XI-B1', const ['Masis-KIR'], _both), isFalse);
    expect(mine.matches(null, const [], _both), isFalse);
    expect(mine.matches('XI-A1', const ['PMR'], _none), isFalse);
  });

  test('falls back to every student when the scope no longer applies', () {
    expect(const MyStudents().resolve(_none, _options), const AllStudents());
    expect(const MyStudents().resolve(_both, _options), const MyStudents());
    expect(
      const ClassScope('XII-A1').resolve(_none, _options),
      const AllStudents(),
    );
    expect(
      const ClassScope('XI-B1').resolve(_none, _options),
      const ClassScope('XI-B1'),
    );
    expect(
      const ExtracurricularScope('Catur').resolve(_none, _options),
      const AllStudents(),
    );
  });
}
