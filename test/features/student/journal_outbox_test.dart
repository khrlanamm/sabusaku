import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/models/journal.dart';
import 'package:sabusaku/core/storage/prefs.dart';
import 'package:sabusaku/features/auth/data/auth_repository.dart';
import 'package:sabusaku/features/auth/domain/app_user.dart';
import 'package:sabusaku/features/auth/domain/session.dart';
import 'package:sabusaku/features/student/data/journal_outbox.dart';
import 'package:sabusaku/features/student/domain/journal_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _session = Session(
  uid: 'siswa1',
  role: UserRole.siswa,
  schoolId: 'sman1',
  profile: AppUser(
    uid: 'siswa1',
    role: UserRole.siswa,
    name: 'Raka',
    email: 'raka@example.com',
    classId: 'XII-A1',
  ),
);

const _draft = JournalDraft(
  date: '2026-10-05',
  pageStart: 1,
  pageEnd: 20,
  durationRange: DurationRange.m15to30,
  keyInformation: 'Ikal mulai menyadari pentingnya pendidikan bagi hidupnya.',
);

const _entry = OutboxEntry(
  programId: 'p1',
  bookTitle: 'Laskar Pelangi',
  date: '2026-10-05',
  kind: OutboxKind.save,
  draft: _draft,
);

void main() {
  late SharedPreferences prefs;

  ProviderContainer newContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentSessionProvider.overrideWithValue(_session),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('a write is pending until the server acknowledges it', () async {
    final container = newContainer();
    final write = Completer<void>();
    container.read(journalOutboxProvider.notifier).track(_entry, write.future);

    final pending = container.read(journalOutboxProvider).single;
    expect(pending.status, OutboxStatus.pending);
    expect(pending.draft, _draft);

    write.complete();
    await pumpEventQueue();
    expect(container.read(journalOutboxProvider), isEmpty);
  });

  test(
    'a journal the server refuses is kept with the reason and its text',
    () async {
      final container = newContainer();
      final write = Completer<void>();
      container
          .read(journalOutboxProvider.notifier)
          .track(_entry, write.future);

      // Written offline on Monday, synced on Thursday: outside the date window.
      write.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await pumpEventQueue();

      final failed = container.read(journalOutboxProvider).single;
      expect(failed.status, OutboxStatus.failed);
      expect(failed.reason, contains('batas pengisian'));
      expect(failed.draft!.keyInformation, _draft.keyInformation);
    },
  );

  test(
    'a failed entry survives an app restart until it is dismissed',
    () async {
      final first = newContainer();
      final write = Completer<void>();
      first.read(journalOutboxProvider.notifier).track(_entry, write.future);
      write.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await pumpEventQueue();

      // A fresh container reads only what was persisted.
      final second = newContainer();
      final restored = second.read(journalOutboxProvider).single;
      expect(restored.status, OutboxStatus.failed);
      expect(restored.draft, _draft);

      second.read(journalOutboxProvider.notifier).dismiss(restored);
      expect(second.read(journalOutboxProvider), isEmpty);
      expect(newContainer().read(journalOutboxProvider), isEmpty);
    },
  );

  test('saving the same date again replaces the earlier entry', () async {
    final container = newContainer();
    final notifier = container.read(journalOutboxProvider.notifier);
    notifier.track(_entry, Completer<void>().future);
    notifier.track(
      _entry.copyWith(draft: _draft.copyWith(pageEnd: 35)),
      Completer<void>().future,
    );

    final entries = container.read(journalOutboxProvider);
    expect(entries, hasLength(1));
    expect(entries.single.draft!.pageEnd, 35);
  });

  test('each account has its own outbox', () async {
    final container = newContainer();
    final write = Completer<void>();
    container.read(journalOutboxProvider.notifier).track(_entry, write.future);
    write.completeError(Exception('offline too long'));
    await pumpEventQueue();

    expect(prefs.getString('journal.outbox.siswa1'), isNotNull);
    expect(
      (jsonDecode(prefs.getString('journal.outbox.siswa1')!) as List).single,
      containsPair('status', 'failed'),
    );
    expect(prefs.getString('journal.outbox.siswa2'), isNull);
  });
}
