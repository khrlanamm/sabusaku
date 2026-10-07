import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/journal.dart';

part 'journal_draft.freezed.dart';

/// What the student typed, ready to be written.
@freezed
abstract class JournalDraft with _$JournalDraft {
  const JournalDraft._();

  const factory JournalDraft({
    required String date,
    required int pageStart,
    required int pageEnd,
    required DurationRange durationRange,
    required String keyInformation,
    @Default('') String reflection,
    @Default('') String question,
  }) = _JournalDraft;

  factory JournalDraft.fromMap(Map<String, dynamic> json) => JournalDraft(
    date: json['date'] as String,
    pageStart: json['pageStart'] as int,
    pageEnd: json['pageEnd'] as int,
    durationRange: DurationRange.fromWire(json['durationRange']),
    keyInformation: json['keyInformation'] as String,
    reflection: json['reflection'] as String? ?? '',
    question: json['question'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'date': date,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
    'durationRange': durationRange.wire,
    'keyInformation': keyInformation,
    'reflection': reflection,
    'question': question,
  };
}
