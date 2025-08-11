import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mastro/src/internal/extra.dart';

import 'mutable.dart';

/// A custom exception that is thrown when a [Lightro] or [Mastro] instance
/// initialized via `.late()` is accessed before being assigned a value.
///
/// This exception helps prevent null dereference errors by clearly signaling
/// that the container was marked for late initialization but never assigned.
///
/// Typically occurs when accessing `.value` on a `Lightro<T>.late()` or
/// `Mastro<T>.late()` before Initializing its value by `.value = someValue`.
///
/// ### Example:
/// ```dart
/// final mastro = Mastro<int>.late(); // no value yet
/// print(mastro.value);  // Throws UninitializedLateMastroException
/// ```
///
/// Type parameter:
/// - [T]: The expected type of the uninitialized value.
class _UninitializedLateInitializationStateException<T> implements Exception {
  /// The state container that threw this exception.
  final Basetro state;

  /// Creates a new exception based on the given uninitialized state.
  _UninitializedLateInitializationStateException(this.state);

  @override
  String toString() => 'UninitializedLate${state._typeName}Exception: You are using ${state._typeName}<$T>.late() '
      'and trying to access or modify its value before initializing it';
}

/// Defines a callback function type used for handling validation errors.
///
/// This callback is invoked by a [Mastro] instance when a new value fails
/// its registered validation rule.
///
/// - `invalidValue`: The value that failed the validation check.
typedef ValidationErrorCallback<T> = void Function(T invalidValue);

/// Provides convenient extension methods to easily create state containers
/// ([Lightro] or [Mastro]) from any existing value.
///
/// This enhances readability and simplifies initialization.
///
/// Example:
/// ```dart
/// // Creates a Lightro<int> instance initialized with the value 0.
/// final counter = 0.lightro;
///
/// // Creates a Mastro<bool> instance initialized with the value true.
/// final toggle = true.mastro;
/// ```
extension StateTools<T> on T {
  /// Creates a lightweight state container ([Lightro]) initialized with this value.
  ///
  /// This is suitable for simple state management needs where advanced features
  /// like computed values or dependencies are not required.
  Lightro<T> get lightro => Lightro<T>.of(this);

  /// Creates a full-featured state container ([Mastro]) initialized with this value.
  ///
  /// Use [Mastro] for more complex state management scenarios involving
  /// validation, computed properties, reactive dependencies, and observers.
  Mastro<T> get mastro => Mastro<T>.of(this);
}

/// Provides specialized utility methods for [Basetro] instances holding a `bool` value.
///
/// These methods offer common boolean operations that also trigger change notifications.
///
/// Example:
/// ```dart
/// final toggle = Mastro<bool>.of(false);
///
/// // Toggles the value from false to true, then notifies listeners.
/// toggle.toggle();
///
/// // Sets the value to true, then notifies listeners (if not already true).
/// toggle.setTrue();
///
/// // Sets the value to false, then notifies listeners (if not already false).
/// toggle.setFalse();
/// ```
extension MastroBoolTools on Basetro<bool> {
  /// Toggles the current boolean value of the state container.
  ///
  /// If the value is `true`, it becomes `false`, and vice-versa.
  /// Listeners are notified after the value changes.
  void toggle() {
    value = !value;
  }

  /// Sets the state container's value to `true`.
  ///
  /// Listeners are notified if the value changes from `false` to `true`.
  void setTrue() {
    value = true;
  }

  /// Sets the state container's value to `false`.
  ///
  /// Listeners are notified if the value changes from `true` to `false`.
  void setFalse() {
    value = false;
  }
}

/// Represents the possible states of a [Basetro] instance:
/// either [_Initialized] with a value or [_Uninitialized].
///
/// This sealed class provides a type-safe way to determine the
/// current state of a [Basetro] container.
sealed class _BasetroState<T> {
  const _BasetroState();
}

/// Indicates that a [Basetro] instance has been successfully initialized
/// and holds a value.
class _Initialized<T> extends _BasetroState<T> {
  /// The mutable wrapper holding the actual value of the state container.
  final Mutable<T> data;

  /// Creates an [_Initialized] state with the given `data` wrapper.
  const _Initialized(this.data);
}

/// Indicates that a [Basetro] instance has not yet been initialized
/// and does not hold a value.
///
/// Attempts to access the [value] or modify the state of an [_Uninitialized]
/// container will throw an [_UninitializedLateInitializationStateException].
class _Uninitialized<T> extends _BasetroState<T> {
  /// Creates an [_Uninitialized] state.
  const _Uninitialized();
}

/// The abstract base class for state containers that manage a single value of type `T`.
///
/// [Basetro] provides fundamental capabilities for storing a value,
/// notifying listeners upon changes, and managing initialized/uninitialized states.
///
/// Extend this class to create specific state container types like [Lightro]
/// for simple use cases or [Mastro] for advanced reactive features.
///
/// Listeners can be registered using `addListener` and removed with `removeListener`.
///
/// Example:
/// ```dart
/// // Initializing with a value
/// final state = Lightro<int>.of(10);
/// print(state.value); // Output: 10
///
/// // Updating the value and notifying listeners
/// state.value = 20;
///
/// // Modifying the value using a callback
/// state.modify((s) => s.value++); // Increments to 21 and notifies
///
/// // Checking initialization status
/// if (state.isInitialized) {
///   print('State is initialized with value: ${state.value}');
/// }
/// ```
abstract class Basetro<T extends Object?> with ChangeNotifier {
  _BasetroState<T> _state;

  /// Whether to show internal debug logs related to state changes.
  ///
  /// When set to `true` (default), this enables diagnostic messages that are
  /// printed using [mastroLog] whenever the state is modified or reset. These logs
  /// help track value changes and state transitions in development or testing.
  ///
  /// Set this to `false` to silence logging
  final bool _showLogs;

  /// Creates a new state container with an initial, pre-defined value.
  ///
  /// The state container will be in an [_Initialized] state.
  ///
  /// - `data`: The initial value to be stored in the container.
  Basetro(T data, {bool showLogs = true})
      : _showLogs = showLogs,
        _state = _Initialized(Mutable(data));

  /// Creates a new state container in an uninitialized state.
  ///
  /// The state container starts as [_Uninitialized]. Attempting to access its
  /// [value] or call [modify] before a value is set will throw an
  /// [_UninitializedLateInitializationStateException].
  Basetro.late({bool showLogs = true})
      : _showLogs = showLogs,
        _state = const _Uninitialized();

  /// Gets the current value held by the state container.
  ///
  /// Throws an [_UninitializedLateInitializationStateException] if the state container
  /// has not yet been initialized with a value.
  T get value {
    ensureInitialized();
    return (_state as _Initialized<T>).data.value;
  }

  /// Sets the value of the state container and notifies all registered listeners.
  set value(T value) {
    final previousState = _state;
    if (isInitialized && this.value == value) return;
    _state = _Initialized(Mutable(value));
    notify();
    _logStateChange(previousState);
  }

  /// Sets the value of the state container *without* notifying listeners.
  ///
  /// This setter is primarily for internal use or specific scenarios where
  /// direct value assignment without triggering observers is desired.
  set nonNotifiableSetter(T value) {
    final previousState = _state;
    if (isInitialized && this.value == value) return;
    _state = _Initialized(Mutable(value));
    _logStateChange(previousState);
  }

  /// Modifies the current value of the state container using a provided callback.
  ///
  /// The `modifier` function receives a [Mutable] wrapper around the current value,
  /// allowing in-place modification.
  ///
  /// Throws an [_UninitializedLateInitializationStateException] if the state container
  /// is uninitialized when this method is called.
  ///
  /// - `modifier`: A callback function that takes a [Mutable] instance of the
  ///   current value, allowing its modification.
  FutureOr<void> modify(FutureOr<void> Function(Mutable<T> state) modifier) async {
    ensureInitialized();
    final previousValue = value;
    await modifier((_state as _Initialized<T>).data);
    notify();
    if (_typeName.startsWith('Persistro')) return;
    if (_showLogs) mastroLog('State($_typeName) modified: $previousValue -> $value');
  }

  /// Returns `true` if the state container has been initialized with a value,
  /// `false` otherwise.
  bool get isInitialized => _state is _Initialized<T>;

  /// Asserts that the state container is initialized.
  ///
  /// If the state container is currently [_Uninitialized], this method throws an
  /// [_UninitializedLateInitializationStateException].
  void ensureInitialized() {
    if (_state is _Uninitialized<T>) {
      throw _UninitializedLateInitializationStateException<T>(this);
    }
  }

  /// Pattern-matching style helper that returns different values based on the initialization state.
  ///
  /// Executes either [initialized] or [uninitialized] and returns its result based on whether the box is initialized.
  ///
  /// - If the box **is initialized**, it calls and returns `initialized(value)`.
  /// - If the box **is uninitialized**, it calls and returns `uninitialized()`.
  ///
  /// This is similar in spirit to `maybeMap` or `when` from sealed unions.
  ///
  /// Type parameter:
  /// - [W]: The return type of both callbacks.
  ///
  /// Parameters:
  /// - [uninitialized]: Function to run when the state is not initialized.
  /// - [initialized]: Function to run when the state is initialized, receiving the current value.
  ///
  /// Example:
  /// ```dart
  /// final result = state.when(
  ///   uninitialized: () => 'Loading',
  ///   initialized: (value) => 'Value is $value',
  /// );
  /// ```
  W when<W>({
    required W Function() uninitialized,
    required W Function(T value) initialized,
  }) {
    return isInitialized ? initialized.call(value) : uninitialized.call();
  }

  /// Notifies all registered listeners about a state change.
  ///
  /// This method is typically called internally after a value update, but can
  /// also be manually invoked if external events require listeners to react.
  void notify() => notifyListeners();

  /// Resets the state container to an uninitialized state.
  ///
  /// This method is intended for use in testing scenarios to simulate
  /// an uninitialized state for specific test cases.
  @visibleForTesting
  void resetToUninitialized() {
    if (_state is _Uninitialized<T>) return;
    _state = const _Uninitialized();
    if (_showLogs) mastroLog('State($_typeName) changed: $value -> uninitialized');
  }

  void _logStateChange(_BasetroState<T> previousState) {
    if (_state == previousState || _typeName.startsWith('Persistro')) return;
    if (_showLogs) mastroLog('State($_typeName) changed: ${previousState is _Initialized<T> ? previousState.data.value : 'uninitialized'} -> $value');
  }

  String get _typeName => runtimeType.toString().replaceAll('<$T>', '');
}

/// A lightweight state container for simple state management.
///
/// [Lightro] extends [Basetro] and provides basic value storage and change
/// notification without the advanced features of [Mastro] like computed values,
/// dependencies, or observers. It's suitable for single, independent state values.
///
/// Example:
/// ```dart
/// // Initialize a Lightro with an integer value
/// final counter = Lightro<int>.of(0);
///
/// // Update the value; this will notify any listeners
/// counter.value = 1;
///
/// // Check if the state is initialized
/// if (counter.isInitialized) {
///   print('Counter is ready: ${counter.value}');
/// }
/// ```
class Lightro<T extends Object?> extends Basetro<T> {
  /// Creates a new [Lightro] state container initialized with the given `data`.
  ///
  /// - `data`: The initial value to store in this lightweight container.
  Lightro.of(super.data, {super.showLogs});

  /// Creates a new [Lightro] state container in an uninitialized state.
  ///
  /// Accessing [value] or calling [modify] on this instance before a value
  /// is set will throw an [_UninitializedLateInitializationStateException].
  Lightro.late({super.showLogs}) : super.late();
}

/// A full-featured state container for advanced state management scenarios.
///
/// [Mastro] builds upon [Basetro] by adding powerful capabilities such as:
/// - **Computed Values**: [compute] allows creating derived states that
///   automatically update when their source changes.
/// - **Reactive Dependencies**: [dependsOn] enables a [Mastro] instance to
///   react and notify its own listeners when another [Basetro] it depends on changes.
/// - **Observers**: [observe] provides a way to register direct callbacks
///   for state changes, useful for side effects or logging.
/// - **Validation**: [setValidator] allows defining rules to restrict acceptable values.
///
/// Example:
/// ```dart
/// // Create a Mastro for a counter
/// final counter = Mastro<int>.of(0);
///
/// // Create a computed state that doubles the counter's value
/// final doubled = counter.compute((v) => v * 2);
///
/// // Add an observer to log counter changes
/// counter.observe('log', (v) => print('Counter value changed to: $v'));
///
/// // Set a validator to only allow non-negative values
/// counter.setValidator(
///   (v) => v >= 0,
///   onValidationError: (v) => print('Validation failed: $v is negative!'),
/// );
///
/// // Update the counter, triggering computed values, observers, and validation
/// counter.value = 5;    // Logs "Counter value changed to: 5", doubled updates to 10
/// counter.value = -1;   // Triggers validation error callback, value remains 5
/// ```
class Mastro<T extends Object?> extends Basetro<T> {
  /// Creates a new [Mastro] state container initialized with the given `data`.
  ///
  /// - `data`: The initial value to store in this full-featured container.
  Mastro.of(super.data, {super.showLogs});

  /// Creates a new [Mastro] state container in an uninitialized state.
  ///
  /// Accessing [value] or calling [modify] on this instance before a value
  /// is set will throw an [_UninitializedLateInitializationStateException].
  Mastro.late({super.showLogs}) : super.late();

  final Map<Mastro, VoidCallback> _computedStates = {};
  final Map<Basetro, VoidCallback> _dependencies = {};
  final Map<String, void Function(T value)> _observers = {};
  bool Function(T value)? _validator;
  ValidationErrorCallback<T>? _onValidationError;

  /// Creates a new [Mastro] instance whose value is computed dynamically
  /// based on the current value of *this* [Mastro] instance.
  ///
  /// The `calculator` function is called whenever the value of this instance changes,
  /// and its result is used to update the computed state.
  ///
  /// - `calculator`: A function that transforms the current value of this [Mastro]
  ///   into the value for the new computed [Mastro<R>].
  /// - `validator`: (Optional) A validation function for the computed state's value.
  /// - `onError`: (Optional) A callback to invoke if the computed state's value fails validation.
  ///
  /// Returns a new [Mastro<R>] instance representing the computed state.
  ///
  /// Example:
  /// ```dart
  /// final price = Mastro<double>.of(100.0);
  /// final discountedPrice = price.compute((p) => p * 0.9,
  ///   validator: (d) => d > 0,
  ///   onValidationError: (d) => print('Discounted price cannot be zero or less! ($d)'),
  /// );
  ///
  /// price.value = 120.0; // discountedPrice automatically updates to 108.0
  /// price.value = 0.0;   // discountedPrice attempts to update to 0.0, triggers validation error
  /// ```
  Mastro<R> compute<R extends Object?>(
    R Function(T value) calculator, {
    bool Function(R value)? validator,
    ValidationErrorCallback<R>? onValidationError,
  }) {
    final computed = Mastro<R>.of(calculator(value));
    if (validator != null) {
      computed.setValidator(validator, onValidationError: onValidationError);
    }
    // Create a listener that updates the computed state whenever this state changes.
    void listener() => computed.value = calculator(value);
    addListener(listener); // Register the listener with this Mastro instance.
    _computedStates[computed] = listener; // Store the computed state and its listener.
    return computed;
  }

  /// Establishes a dependency on another [Basetro] instance.
  ///
  /// When the `other` [Basetro] instance notifies its listeners, *this* [Mastro]
  /// instance will also notify its own listeners, effectively reacting to changes
  /// in the dependency. Duplicate dependencies are prevented.
  ///
  /// - `other`: The [Basetro] instance on which this [Mastro] will depend.
  ///
  /// Example:
  /// ```dart
  /// final configLoaded = Lightro<bool>.of(false);
  /// final uiReady = Mastro<bool>.of(false);
  ///
  /// uiReady.dependsOn(configLoaded); // uiReady will notify when configLoaded changes
  ///
  /// configLoaded.value = true; // This will cause uiReady to notify its listeners
  /// ```
  void dependsOn<B extends Object?>(Basetro<B> other) {
    if (_dependencies.containsKey(other)) {
      return; // Prevent adding the same dependency listener multiple times
    }
    void listener() => notify(); // Listener for the dependency: just notify this Mastro.
    other.addListener(listener);
    _dependencies[other] = listener; // Store the dependency and its listener.
  }

  /// Removes a previously added dependency on another [Basetro] instance.
  ///
  /// After removal, this [Mastro] instance will no longer notify its listeners
  /// when the `other` dependency changes.
  ///
  /// - `other`: The [Basetro] instance whose dependency relationship is to be removed.
  void removeDependency<B extends Object?>(Basetro<B> other) {
    final listener = _dependencies[other];
    if (listener != null) {
      other.removeListener(listener);
      _dependencies.remove(other);
    }
  }

  /// Adds an observer callback that will be invoked whenever this [Mastro]'s value changes.
  ///
  /// Each observer is identified by a unique `key`.
  ///
  /// Throws an [ArgumentError] if an observer with the given `key` already exists.
  ///
  /// - `key`: A unique string identifier for this observer.
  /// - `callback`: A function that receives the current value of the [Mastro] when it changes.
  void observe(String key, void Function(T value) callback) {
    if (_observers.containsKey(key)) {
      throw ArgumentError('Observer with key "$key" already exists.');
    }
    _observers[key] = callback;
  }

  /// Removes an observer by its unique key.
  ///
  /// If no observer exists for the given `key`, this method does nothing.
  ///
  /// - `key`: The identifier of the observer to remove.
  void removeObserver(String key) {
    _observers.remove(key);
  }

  /// Sets a validation function for this [Mastro] instance.
  ///
  /// The `validator` function determines if a new value is acceptable. If a value
  /// fails validation, it will not be set, and the optional `onError` callback
  /// will be invoked.
  ///
  /// - `validator`: A function that returns `true` if the value is valid, `false` otherwise.
  /// - `onError`: (Optional) A callback invoked with the `invalidValue` if validation fails.
  ///
  /// Example:
  /// ```dart
  /// final age = Mastro<int>.of(18);
  /// age.setValidator(
  ///   (a) => a >= 0 && a <= 150, // Age must be between 0 and 150
  ///   onValidationError: (invalidAge) => print('Invalid age entered: $invalidAge'),
  /// );
  ///
  /// age.value = 25;  // Valid, value set
  /// age.value = -5;  // Invalid, onValidationError called, value remains 25
  /// ```
  void setValidator(bool Function(T value) validator, {ValidationErrorCallback<T>? onValidationError}) {
    _validator = validator;
    _onValidationError = onValidationError;
  }

  /// Notifies all registered observers of the current state container's value.
  ///
  /// This method is called automatically when the value changes (via `notify()`),
  /// but can also be manually invoked if needed.
  @protected
  void notifyObservers() {
    // Iterate over a copy to prevent concurrent modification if observers modify the map
    final currentObservers = _observers.values.toList();
    for (final observer in currentObservers) {
      observer(value);
    }
  }

  @override
  void dispose() {
    // Remove listeners from all dependencies to prevent memory leaks.
    for (final entry in _dependencies.entries) {
      entry.key.removeListener(entry.value);
    }
    _dependencies.clear();

    // Remove listeners for computed states and dispose the computed states themselves.
    for (final entry in _computedStates.entries) {
      removeListener(entry.value); // Remove listener from this Mastro
      entry.key.dispose(); // Recursively dispose computed Mastro instances
    }
    _computedStates.clear();

    // Clear observers.
    _observers.clear();

    // Call the dispose method of the superclass (ChangeNotifier) to clean up its listeners.
    super.dispose();
  }

  @override
  void notify() {
    super.notify();
    notifyObservers();
  }

  @override
  set nonNotifiableSetter(T value) {
    if (_validator?.call(value) ?? true) {
      super.nonNotifiableSetter = value;
    } else {
      _onValidationError?.call(value);
      if (_showLogs) mastroLog('Mastro(${value.runtimeType}) validator failed for value: $value');
    }
  }

  @override
  set value(T newValue) {
    if (_validator?.call(newValue) ?? true) {
      super.value = newValue;
    } else {
      _onValidationError?.call(newValue);
      if (_showLogs) mastroLog('Mastro(${value.runtimeType}) validator failed for value: $newValue');
    }
  }

  /// Simulates a state change notification for testing purposes.
  ///
  /// This method directly calls [notify] without changing the internal value,
  /// allowing tests to verify listener and observer reactions.
  @visibleForTesting
  void simulateNotify() => notify();

  /// Returns an unmodifiable map of the dependencies currently registered with this [Mastro] instance.
  ///
  /// This is intended for testing and debugging purposes to inspect the dependency graph.
  @visibleForTesting
  Map<Basetro, VoidCallback> get testDependencies => Map.unmodifiable(_dependencies);

  /// Returns an unmodifiable map of the observers currently registered with this [Mastro] instance.
  ///
  /// This is intended for testing and debugging purposes to inspect active observers.
  @visibleForTesting
  Map<String, void Function(T value)> get testObservers => Map.unmodifiable(_observers);
}
