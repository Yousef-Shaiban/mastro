/// Defines how events should be executed in relation to each other within the Mastro framework.
///
/// This enum specifies the execution mode for [MastroEvent] instances.
enum EventRunningMode {
  /// Allows multiple instances of the event to run simultaneously.
  ///
  /// This is the default mode, enabling parallel execution without restrictions.
  parallel,

  /// Queues events of the same type to run one after another.
  ///
  /// Ensures that only one instance of this event type runs at a time, with others waiting in sequence.
  sequential,

  /// Restricts execution to a single instance at a time across all event types.
  ///
  /// Prevents any other solo events from running concurrently with this one.
  solo,
}

/// Base class for implementing events in the Mastro framework.
///
/// Events define actions that can be executed by a [MastroBox], with configurable execution modes.
///
/// Type parameter [T] represents the type of [MastroBox] this event operates on.
abstract class MastroEvent<T> {
  /// Creates a new event instance.
  const MastroEvent();

  /// Implements the core logic of the event.
  ///
  /// [box] is the [MastroBox] instance executing this event. [callback] provides access to
  /// callback functions that can be invoked during or after execution. Returns a [Future]
  /// that completes when the event logic is finished.
  Future<void> implement(
    T box,
    Callbacks callback,
  );

  /// Defines how this event should be executed relative to other events.
  ///
  /// Returns an [EventRunningMode] value. Defaults to [EventRunningMode.parallel].
  EventRunningMode get mode => EventRunningMode.parallel;
}

/// Manages callback functions that can be invoked by [MastroEvent] instances.
///
/// This class stores and triggers named callbacks, allowing events to communicate results
/// or trigger additional actions.
class Callbacks {
  /// Internal storage for callback functions.
  final Map<String, void Function({Map<String, dynamic>? data})> _callbacks;

  /// Creates a new callbacks manager.
  ///
  /// [callbacks] is an optional map of named callback functions. If null, an empty map is used.
  Callbacks({
    Map<String, void Function({Map<String, dynamic>? data})>? callbacks,
  }) : _callbacks = callbacks ?? {};

  /// Invokes a named callback with optional data.
  ///
  /// [name] is the identifier of the callback to trigger. [data] is an optional map of
  /// parameters to pass to the callback. Does nothing if the callback is not registered.
  void invoke(String name, {Map<String, dynamic>? data}) {
    _callbacks[name]?.call(data: data);
  }
}
