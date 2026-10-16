import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/labels.dart';

part 'school.freezed.dart';

/// `schools/{schoolId}.settings` (docs/02 §3.1). Teacher-editable.
@freezed
abstract class SchoolSettings with _$SchoolSettings {
  const SchoolSettings._();

  const factory SchoolSettings({
    /// 0 = Sunday … 6 = Saturday. Neutral days never break a streak.
    @Default(<int>[0]) List<int> neutralWeekdays,

    /// `yyyy-MM-dd`, sorted.
    @Default(<String>[]) List<String> holidays,
    @Default(3) int activeMaxDays,
    @Default(7) int attentionMaxDays,
  }) = _SchoolSettings;

  factory SchoolSettings.fromMap(Map<String, dynamic>? data) => SchoolSettings(
    neutralWeekdays: List<int>.from(
      data?['neutralWeekdays'] as List? ?? const [0],
    ),
    holidays: List<String>.from(data?['holidays'] as List? ?? const [])..sort(),
    activeMaxDays: data?['activeMaxDays'] as int? ?? 3,
    attentionMaxDays: data?['attentionMaxDays'] as int? ?? 7,
  );

  Map<String, dynamic> toMap() => {
    'neutralWeekdays': [...neutralWeekdays]..sort(),
    'holidays': [...holidays]..sort(),
    'activeMaxDays': activeMaxDays,
    'attentionMaxDays': attentionMaxDays,
  };
}

@freezed
abstract class School with _$School {
  const factory School({
    required String id,
    required String name,
    @Default(true) bool active,
    @Default(SchoolSettings()) SchoolSettings settings,

    /// Class labels (`XII-A1`), sorted by grade. Teachers add more.
    @Default(<String>[]) List<String> classes,

    /// Extracurricular labels (`Masis-KIR`). Teachers add more.
    @Default(<String>[]) List<String> extracurriculars,

    /// Catalog books the school's teachers recommend (`books/{bookId}`).
    @Default(<String>[]) List<String> recommendedBooks,
  }) = _School;

  factory School.fromMap(String id, Map<String, dynamic> data) => School(
    id: id,
    name: data['name'] as String? ?? id,
    active: data['status'] != 'suspended',
    settings: SchoolSettings.fromMap(data['settings'] as Map<String, dynamic>?),
    classes: List<String>.from(data['classes'] as List? ?? const [])
      ..sort(compareClassLabels),
    extracurriculars: List<String>.from(
      data['extracurriculars'] as List? ?? const [],
    ),
    recommendedBooks: List<String>.from(
      data['recommendedBooks'] as List? ?? const [],
    ),
  );
}
