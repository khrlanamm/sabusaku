import 'package:freezed_annotation/freezed_annotation.dart';

part 'school.freezed.dart';

/// `schools/{schoolId}.settings` (docs/02 §3.1). Admin-editable.
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
  }) = _School;

  factory School.fromMap(String id, Map<String, dynamic> data) => School(
    id: id,
    name: data['name'] as String? ?? id,
    active: data['status'] != 'suspended',
    settings: SchoolSettings.fromMap(data['settings'] as Map<String, dynamic>?),
  );
}
