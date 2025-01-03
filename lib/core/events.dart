/// Defines how events should be executed in relation to each other.
enum EventRunningMode {
  /// (default): Multiple instances can run simultaneously
  parallel,

  /// Events of same type are queued
  sequential,

  /// Only one instance can run at a time
  solo,
}

/// Base class for implementing events in the Mastro framework.
abstract class MastroEvent<T> {
  /// Creates a new event instance.
  const MastroEvent();

  /// Implements the event logic.
  Future<void> implement(
    T box,
    Callbacks callback,
  );

  /// Defines how this event should be executed relative to other events.
  EventRunningMode get mode => EventRunningMode.parallel;
}

/// Manages callback functions that can be invoked by events.
class Callbacks {
  final Map<String, void Function({Map<String, dynamic>? data})> _callbacks;

  /// Creates a new callbacks manager.
  Callbacks({
    Map<String, void Function({Map<String, dynamic>? data})>? callbacks,
  }) : _callbacks = callbacks ?? {};

  /// Invokes a named callback with optional data.
  void invoke(String name, {Map<String, dynamic>? data}) {
    _callbacks[name]?.call(data: data);
  }
}
