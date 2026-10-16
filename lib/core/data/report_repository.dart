import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../errors/app_exception.dart';
import '../firebase/firebase_providers.dart';
import '../models/report.dart';

part 'report_repository.g.dart';

/// Longest note a reporter or a penanggung jawab may add.
const maxReportNoteLength = 500;

/// Reports of content and users (Google Play's user-generated content
/// policy). Anyone with a school reports through `reportContent`; the
/// school's penanggung jawab read the reports and resolve them through
/// `resolveReport`. Only Cloud Functions write `reports`.
class ReportRepository {
  ReportRepository(this._firestore, this._functions, this._schoolId);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String _schoolId;

  /// The reports that concern this school, newest first. Readable by its
  /// penanggung jawab only.
  Stream<List<Report>> watchSchoolReports() => _firestore
      .collection('reports')
      .where('schools', arrayContains: _schoolId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) Report.fromMap(doc.id, doc.data()),
        ],
      );

  /// Sends a report. Returns its ID.
  Future<String> report(
    ReportTarget target, {
    required ReportReason reason,
    String? note,
  }) async {
    final data = await _call('reportContent', {
      ...target.toMap(),
      'reason': reason.wire,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return data['id'] as String? ?? '';
  }

  /// Marks a report as handled, with what was done ([resolution]).
  Future<void> resolve(String id, {String? resolution}) =>
      _call('resolveReport', {
        'id': id,
        if (resolution != null && resolution.trim().isNotEmpty)
          'resolution': resolution.trim(),
      });

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      return Map<String, dynamic>.from(result.data as Map? ?? const {});
    } catch (error) {
      throw mapError(error);
    }
  }
}

@riverpod
ReportRepository reportRepository(Ref ref) => ReportRepository(
  ref.watch(firestoreProvider),
  ref.watch(functionsProvider),
  ref.watch(currentSessionProvider.select((session) => session.schoolId)),
);

/// Every report of the school, newest first (penanggung jawab only).
@riverpod
Stream<List<Report>> schoolReports(Ref ref) =>
    ref.watch(reportRepositoryProvider).watchSchoolReports();

/// Reports still waiting for a penanggung jawab.
@riverpod
int openReportCount(Ref ref) =>
    ref
        .watch(schoolReportsProvider)
        .value
        ?.where((report) => !report.resolved)
        .length ??
    0;
