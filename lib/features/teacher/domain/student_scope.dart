import '../../auth/domain/app_user.dart';

/// The class and extracurricular labels a teacher can narrow a view to.
typedef ScopeOptions = ({List<String> classes, List<String> extracurriculars});

/// Which students a teacher's dashboard and its detail pages cover: every
/// student, the teacher's own ("Binaan saya"), one class or one
/// extracurricular. One at a time.
sealed class StudentScope {
  const StudentScope();

  /// Whether a student with these labels is in scope for the teacher [me].
  bool matches(String? classId, List<String> extracurriculars, AppUser me);

  /// This scope, or every student when it no longer applies: the teacher
  /// has no group any more, or the label left the school's list.
  StudentScope resolve(AppUser me, ScopeOptions options) => switch (this) {
    MyStudents() when !me.hasGroup => const AllStudents(),
    ClassScope(:final label) when !options.classes.contains(label) =>
      const AllStudents(),
    ExtracurricularScope(:final label)
        when !options.extracurriculars.contains(label) =>
      const AllStudents(),
    _ => this,
  };
}

final class AllStudents extends StudentScope {
  const AllStudents();

  @override
  bool matches(String? classId, List<String> extracurriculars, AppUser me) =>
      true;

  @override
  bool operator ==(Object other) => other is AllStudents;

  @override
  int get hashCode => (AllStudents).hashCode;
}

/// Students in the teacher's homeroom class or in an extracurricular they
/// supervise.
final class MyStudents extends StudentScope {
  const MyStudents();

  @override
  bool matches(String? classId, List<String> extracurriculars, AppUser me) =>
      me.inGroup(classId, extracurriculars);

  @override
  bool operator ==(Object other) => other is MyStudents;

  @override
  int get hashCode => (MyStudents).hashCode;
}

final class ClassScope extends StudentScope {
  const ClassScope(this.label);

  final String label;

  @override
  bool matches(String? classId, List<String> extracurriculars, AppUser me) =>
      classId == label;

  @override
  bool operator ==(Object other) => other is ClassScope && other.label == label;

  @override
  int get hashCode => Object.hash(ClassScope, label);
}

final class ExtracurricularScope extends StudentScope {
  const ExtracurricularScope(this.label);

  final String label;

  @override
  bool matches(String? classId, List<String> extracurriculars, AppUser me) =>
      extracurriculars.contains(label);

  @override
  bool operator ==(Object other) =>
      other is ExtracurricularScope && other.label == label;

  @override
  int get hashCode => Object.hash(ExtracurricularScope, label);
}
