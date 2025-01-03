enum EventRunningMode { parallel, sequential, solo }

abstract class MastroEvent<T> {
  const MastroEvent();

  Future<void> implement(
    T box,
    Callbacks callback,
  );

  EventRunningMode get mode => EventRunningMode.parallel;
}

class Callbacks {
  final Map<String, void Function({Map<String, dynamic>? data})> _callbacks;

  Callbacks({
    Map<String, void Function({Map<String, dynamic>? data})>? callbacks,
  }) : _callbacks = callbacks ?? {};

  void invoke(String name, {Map<String, dynamic>? data}) {
    _callbacks[name]?.call(data: data);
  }
}
