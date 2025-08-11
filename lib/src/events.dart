import 'internal/extra.dart';

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
class Callbacks {
  /// Internal storage for callback functions.
  ///
  /// This map stores callbacks identified by their unique string names.
  /// It can be null if the `Callbacks._()` private constructor is used
  /// without providing an initial map.
  final Map<String, void Function(Map<String, dynamic>? data)>? _callbacks;

  /// Private constructor for internal use by factories.
  ///
  /// It initializes the internal [_callbacks] map with an optional provided map.
  /// If [callbacks] is null, the [_callbacks] field will be null.
  Callbacks._({
    Map<String, void Function(Map<String, dynamic>? data)>? callbacks,
  }) : _callbacks = callbacks;

  /// Factory constructor to create a [Callbacks] instance, potentially starting a chain.
  ///
  /// it returns a [Callbacks] instance initialized with a single callback
  /// associated with the given [name] and [callback]. This can be used as the
  /// starting point for method chaining.
  factory Callbacks.on(String name, void Function(Map<String, dynamic>? data) callback) {
    if (name == defaultCallbacksName) {
      return Callbacks._();
    }
    return Callbacks._(callbacks: {name: callback});
  }

  /// Registers a callback function with the given [name].
  ///
  /// [name] is the unique identifier for the callback. [callback] is the function to register,
  /// which may receive optional [data] when triggered.
  /// Returns the [Callbacks] instance to allow for method chaining.
  Callbacks on(String name, void Function(Map<String, dynamic>? data) callback) {
    _callbacks?[name] = callback;
    return this;
  }

  /// Invokes a named callback with optional data.
  ///
  /// [name] is the identifier of the callback to trigger. [data] is an optional map of
  /// parameters to pass to the callback. Does nothing if the callback is not registered
  /// or if the internal [_callbacks] map is null.
  void invoke(String name, {Map<String, dynamic>? data}) {
    _callbacks?[name]?.call(data);
  }
}
