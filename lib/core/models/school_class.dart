import 'package:freezed_annotation/freezed_annotation.dart';

part 'school_class.freezed.dart';

/// `schools/{schoolId}/classes/{classId}` (docs/02 §3.4).
@freezed
abstract class SchoolClass with _$SchoolClass {
  const factory SchoolClass({
    required String id,
    required String name,
    required int grade,
    required String academicYear,

    /// Mirror of the teachers' `classIds`, for display only.
    @Default(<String>[]) List<String> teacherIds,
    @Default(false) bool isArchived,
  }) = _SchoolClass;

  factory SchoolClass.fromMap(String id, Map<String, dynamic> data) =>
      SchoolClass(
        id: id,
        name: data['name'] as String? ?? '',
        grade: data['grade'] as int? ?? 10,
        academicYear: data['academicYear'] as String? ?? '',
        teacherIds: List<String>.from(data['teacherIds'] as List? ?? const []),
        isArchived: data['isArchived'] == true,
      );
}
