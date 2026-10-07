// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_outbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks journal writes until the server answers, so a journal written
/// offline is never rejected silently (docs/03 §3, "Catatan perilaku offline").
///
/// Firestore queues offline writes and replays them after an app restart, but
/// the future of the original call is gone by then. Entries are therefore
/// persisted, and on the next start each leftover entry is settled by
/// watching its document: once it has no pending writes, either the server
/// took the write or it rolled it back.

@ProviderFor(JournalOutbox)
final journalOutboxProvider = JournalOutboxProvider._();

/// Tracks journal writes until the server answers, so a journal written
/// offline is never rejected silently (docs/03 §3, "Catatan perilaku offline").
///
/// Firestore queues offline writes and replays them after an app restart, but
/// the future of the original call is gone by then. Entries are therefore
/// persisted, and on the next start each leftover entry is settled by
/// watching its document: once it has no pending writes, either the server
/// took the write or it rolled it back.
final class JournalOutboxProvider
    extends $NotifierProvider<JournalOutbox, List<OutboxEntry>> {
  /// Tracks journal writes until the server answers, so a journal written
  /// offline is never rejected silently (docs/03 §3, "Catatan perilaku offline").
  ///
  /// Firestore queues offline writes and replays them after an app restart, but
  /// the future of the original call is gone by then. Entries are therefore
  /// persisted, and on the next start each leftover entry is settled by
  /// watching its document: once it has no pending writes, either the server
  /// took the write or it rolled it back.
  JournalOutboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalOutboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalOutboxHash();

  @$internal
  @override
  JournalOutbox create() => JournalOutbox();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OutboxEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OutboxEntry>>(value),
    );
  }
}

String _$journalOutboxHash() => r'b2cd571ba2644f05ae41cfdf0c3316e57e22ec8e';

/// Tracks journal writes until the server answers, so a journal written
/// offline is never rejected silently (docs/03 §3, "Catatan perilaku offline").
///
/// Firestore queues offline writes and replays them after an app restart, but
/// the future of the original call is gone by then. Entries are therefore
/// persisted, and on the next start each leftover entry is settled by
/// watching its document: once it has no pending writes, either the server
/// took the write or it rolled it back.

abstract class _$JournalOutbox extends $Notifier<List<OutboxEntry>> {
  List<OutboxEntry> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<OutboxEntry>, List<OutboxEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<OutboxEntry>, List<OutboxEntry>>,
              List<OutboxEntry>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Saves or deletes a journal without waiting for the server, handing the
/// write to the outbox.

@ProviderFor(journalWriter)
final journalWriterProvider = JournalWriterProvider._();

/// Saves or deletes a journal without waiting for the server, handing the
/// write to the outbox.

final class JournalWriterProvider
    extends $FunctionalProvider<JournalWriter, JournalWriter, JournalWriter>
    with $Provider<JournalWriter> {
  /// Saves or deletes a journal without waiting for the server, handing the
  /// write to the outbox.
  JournalWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalWriterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalWriterHash();

  @$internal
  @override
  $ProviderElement<JournalWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JournalWriter create(Ref ref) {
    return journalWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalWriter>(value),
    );
  }
}

String _$journalWriterHash() => r'e23ebf9d002403641bd1bcf81b28b29566a8d954';
