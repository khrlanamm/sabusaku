import 'dart:async';

extension SwitchMap<T> on Stream<T> {
  /// Maps each event to a stream and follows only the latest one, cancelling
  /// the previous inner stream when a new event arrives.
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    late final StreamController<R> controller;
    StreamSubscription<T>? outer;
    StreamSubscription<R>? inner;

    controller = StreamController<R>(
      onListen: () {
        outer = listen((value) {
          inner?.cancel();
          inner = mapper(value)
              .listen(controller.add, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await inner?.cancel();
        await outer?.cancel();
      },
    );
    return controller.stream;
  }
}

/// Emits the latest value of every stream as one list, once each has emitted
/// at least once, and again whenever any of them emits.
Stream<List<T>> combineLatest<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) return Stream.value(const []);

  late final StreamController<List<T>> controller;
  final subscriptions = <StreamSubscription<T>>[];
  final latest = List<T?>.filled(streams.length, null);
  final seen = List<bool>.filled(streams.length, false);

  controller = StreamController<List<T>>(
    onListen: () {
      for (final (index, stream) in streams.indexed) {
        subscriptions.add(
          stream.listen((value) {
            latest[index] = value;
            seen[index] = true;
            if (seen.every((done) => done)) {
              controller.add([for (final item in latest) item as T]);
            }
          }, onError: controller.addError),
        );
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}
