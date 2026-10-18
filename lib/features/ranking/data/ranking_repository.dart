import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/time/periods.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/ranking.dart';

part 'ranking_repository.g.dart';

/// One period's board of the user's school (server-written, docs/02 §3.17).
/// A period without a board yet is an empty one.
@riverpod
Stream<Leaderboard> leaderboard(Ref ref, String periodId) {
  final period = RankPeriod.fromId(periodId) ?? RankPeriod.all;
  final schoolId = ref.watch(
    currentSessionProvider.select((session) => session.schoolId),
  );
  return ref
      .watch(firestoreProvider)
      .doc('schools/$schoolId/leaderboards/${period.id}')
      .snapshots()
      .map((doc) {
        final data = doc.data();
        final entries = data?['entries'];
        return Leaderboard(
          period: period,
          entries: [
            if (entries is Map)
              for (final MapEntry(:key, :value) in entries.entries)
                if (value is Map)
                  RankEntry.fromMap(
                    key as String,
                    Map<String, dynamic>.from(value),
                  ),
          ],
          updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
        );
      });
}
