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
