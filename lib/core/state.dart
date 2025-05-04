import 'dart:developer';

import 'package:flutter/material.dart';

import 'mutable.dart';

/// Provides extension methods for easily creating state containers from any value.
///
/// This extension adds convenience methods to any type [T] to create instances of [Lightro]
/// or [Mastro] state containers.
extension StateTools<T> on T {
  /// Creates a lightweight state container initialized with this value.
  ///
  /// Returns a [Lightro] instance that wraps this value, allowing basic state management
  /// with change notifications.
  Lightro<T> get lightro {
    return Lightro<T>.of(this);
  }

  /// Creates a full-featured state container initialized with this value.
  ///
  /// Returns a [Mastro] instance that wraps this value, providing advanced state management
  /// features like computed values, dependencies, and observers.
  Mastro<T> get mastro {
    return Mastro<T>.of(this);
  }
}

/// Provides extension methods for boolean state containers.
///
/// This extension adds utility methods specific to [Basetro<bool>], enhancing its usability
/// for managing boolean states.
extension MastroBoolTools on Basetro<bool> {
  /// Toggles the current boolean value and notifies listeners.
  ///
  /// Switches the value from `true` to `false` or vice versa. If the container was
  /// uninitialized, it becomes initialized with the toggled value (starting from `false`).
  void toggle() {
    value = !value;
  }

  /// Sets the value to `true` and notifies listeners.
  ///
  /// Updates the state to `true`, initializing the container if it was previously
  /// uninitialized. Listeners are notified of the change via [notify].
  void setTrue() {
    value = true;
  }

  /// Sets the value to `false` and notifies listeners.
  ///
  /// Updates the state to `false`, initializing the container if it was previously
  /// uninitialized. Listeners are notified of the change via [notify].
  void setFalse() {
    value = false;
  }
}

/// Represents the state of a [Basetro] instance, which can be either initialized or uninitialized.
///
/// This is a sealed class, meaning all possible states are defined as its subclasses.
/// It serves as the foundation for state management in [Basetro], [Lightro], and [Mastro].
sealed class BasetroState<T> {
  /// Creates a new state instance.
  const BasetroState();
}

/// A state indicating that a [Basetro] has been initialized with data.
///
/// This class holds the initialized value within a [Mutable] container.
class Initialized<T> extends BasetroState<T> {
  /// The mutable data container holding the initialized value.
  final Mutable<T> data;

  /// Creates an initialized state with the given [data].
  const Initialized(this.data);
}

/// A state indicating that a [Basetro] has not been initialized.
///
/// This class represents an empty or unset state.
class Uninitialized<T> extends BasetroState<T> {
  /// Creates an uninitialized state.
  const Uninitialized();
}

/// A base state container that manages a value of type [T] and notifies listeners of changes.
///
/// This abstract class provides the core functionality for state management, supporting
/// both initialized and uninitialized states via [BasetroState]. It mixes in [ChangeNotifier]
/// to enable change notifications for Flutter widgets or other listeners.
///
/// Type parameter [T] represents the type of the value being managed.
abstract class Basetro<T> with ChangeNotifier {
  /// The internal state of the container, either [Initialized] or [Uninitialized].
  BasetroState<T> _state;

  /// Creates a new state container with an initial value.
  ///
  /// [data] is the initial value to store in the container. The state is set to [Initialized].
  Basetro(T data) : _state = Initialized(Mutable(data));

  /// Creates a new state container in an uninitialized state.
  ///
  /// The state is set to [Uninitialized]. Accessing [value] or calling [modify] before
  /// setting a value will throw an exception.
  Basetro.initial() : _state = const Uninitialized();

  /// Gets the current value of the container.
  ///
  /// Returns the stored value if the container is initialized.
  ///
  /// Throws an [Exception] if the container is uninitialized (created with [Basetro.initial]
  /// and not yet set).
  T get value {
    if (_state is Uninitialized<T>) {
      throw Exception('Basetro<${T.runtimeType}> has not been initialized');
    }
    return (_state as Initialized<T>).data.value;
  }

  /// Sets the value and notifies listeners of the change.
  ///
  /// [value] is the new value to store. If the container was uninitialized, it becomes
  /// initialized. Listeners are notified via [notify] unless overridden by subclasses.
  set value(T value) {
    _state = Initialized(Mutable(value));
    notify();
  }

  /// Sets the value without notifying listeners.
  ///
  /// [value] is the new value to store. If the container was uninitialized, it becomes
  /// initialized. Use this to update the state silently, bypassing notifications.
  set nonNotifiableSetter(T value) {
    _state = Initialized(Mutable(value));
  }

  /// Modifies the state using a callback and notifies listeners.
  ///
  /// [modify] is a function that takes a [Mutable<T>] and updates its [value]. The callback
  /// is executed only if the container is initialized. Listeners are notified after the
  /// modification via [notify].
  ///
  /// Throws an [Exception] if the container is uninitialized.
  void modify(void Function(Mutable<T> state) modify) {
    if (_state is Uninitialized<T>) {
      throw Exception('Basetro<${T.runtimeType}> has not been initialized');
    }
    modify((_state as Initialized<T>).data);
    notify();
  }

  /// Checks if the container is initialized.
  ///
  /// Returns `true` if the container holds a value (i.e., its state is [Initialized]),
  /// and `false` if it is uninitialized (i.e., its state is [Uninitialized]). Useful when
  /// using [Lightro.initial] or [Mastro.initial].
  bool get ensureInitialized {
    return _state is Initialized<T>;
  }

  /// Notifies all registered listeners of a state change.
  ///
  /// Calls [notifyListeners] from [ChangeNotifier], triggering updates in dependent widgets
  /// or listeners. Subclasses may extend this behavior (e.g., [Mastro] notifies observers).
  void notify() => notifyListeners();
}

/// A lightweight state container that extends [Basetro] with minimal overhead.
///
/// This class provides basic state management with change notifications, suitable for
/// simple use cases where advanced features like computed values or dependencies are not needed.
///
/// Type parameter [T] represents the type of the value being managed.
class Lightro<T> extends Basetro<T> {
  /// Creates a new lightweight state container with an initial value.
  ///
  /// [data] is the initial value to store in the container.
  Lightro.of(super.data) : super();

  /// Creates a new lightweight state container in an uninitialized state.
  ///
  /// Accessing [value] or calling [modify] before setting a value will throw an exception.
  Lightro.initial() : super.initial();
}

/// A full-featured state container with computed values, dependencies, and observers.
///
/// This class extends [Basetro] to provide advanced state management features, including
/// computed states, dependency tracking, observer callbacks, and value validation.
///
/// Type parameter [T] represents the type of the value being managed.
class Mastro<T> extends Basetro<T> {
  /// Creates a new full-featured state container with an initial value.
  ///
  /// [data] is the initial value to store in the container.
  Mastro.of(super.data) : super();

  /// Creates a new full-featured state container in an uninitialized state.
  ///
  /// Accessing [value] or calling [modify] before setting a value will throw an exception.
  Mastro.initial() : super.initial();

  /// Creates a computed state that depends on this state’s value.
  ///
  /// [calculator] is a function that computes a new value of type [R] based on this state’s
  /// [value]. Returns a new [Mastro<R>] instance that updates automatically when this state
  /// changes.
  Mastro<R> compute<R>(R Function(T value) calculator) {
    final computed = calculator(value).mastro;
    void listener() => computed.value = calculator(value);
    addListener(listener);
    _computedStates[computed] = listener;
    return computed;
  }

  /// Adds a dependency on another state container.
  ///
  /// [other] is the [Basetro] instance to depend on. When [other] changes, this state
  /// notifies its listeners, enabling reactive updates.
  void dependsOn(Basetro other) {
    void listener() => notify();
    other.addListener(listener);
    _dependencies[other] = listener;
  }

  /// Removes a dependency on another state container.
  ///
  /// [other] is the [Mastro] instance to stop depending on. Removes the associated listener
  /// if it exists.
  void removeDependency(Mastro other) {
    final listener = _dependencies[other];
    if (listener != null) {
      other.removeListener(listener);
      _dependencies.remove(other);
    }
  }

  /// Adds an observer callback that reacts to state changes.
  ///
  /// [key] is a unique identifier for the observer. [callback] is the function to call with
  /// the current [value] whenever the state changes.
  void observe(String key, void Function(T value) callback) {
    _observers[key] = callback;
  }

  /// Removes an observer by its key.
  ///
  /// [key] is the identifier of the observer to remove. If no observer exists for [key],
  /// this method does nothing.
  void removeObserver(String key) {
    _observers.remove(key);
  }

  /// Sets a validation function for value changes.
  ///
  /// [validator] is a function that returns `true` if the new [value] is valid, or `false`
  /// to reject it. Invalid values are logged and ignored.
  void setValidator(bool Function(T value) validator) {
    _validator = validator;
  }

  /// Notifies all registered observers of the current state.
  ///
  /// Calls each observer callback with the current [value]. Called automatically by [notify].
  void notifyObservers() {
    for (final observer in _observers.values) {
      observer(value);
    }
  }

  /// Stores listeners for computed states.
  final Map<Basetro, VoidCallback> _computedStates = {};

  /// Stores listeners for dependencies.
  final Map<Basetro, VoidCallback> _dependencies = {};

  /// Stores observer callbacks.
  final Map<String, void Function(T value)> _observers = {};

  /// Optional validator for value changes.
  bool Function(T value)? _validator;

  /// Disposes of the state container, cleaning up all listeners and observers.
  ///
  /// Removes listeners from dependencies and computed states, clears all internal maps,
  /// and calls the superclass [dispose] method.
  @override
  void dispose() {
    for (final entry in _dependencies.entries) {
      entry.key.removeListener(entry.value);
    }
    _dependencies.clear();

    for (final entry in _computedStates.entries) {
      removeListener(entry.value);
    }
    _computedStates.clear();
    _observers.clear();
    super.dispose();
  }

  /// Notifies listeners and observers of a state change.
  ///
  /// Extends [Basetro.notify] by also calling [notifyObservers] to update registered callbacks.
  @override
  void notify() {
    super.notify();
    notifyObservers();
  }

  /// Sets the value without notifying listeners, applying validation if set.
  ///
  /// [value] is the new value to store. If a [validator] is set and rejects the value,
  /// the change is logged and ignored. Otherwise, the state is updated silently.
  @override
  set nonNotifiableSetter(T value) {
    if (_validator?.call(value) ?? true) {
      super.nonNotifiableSetter = value;
    } else {
      log('Mastro<${T.runtimeType}> validator failed for value: $value');
    }
  }

  /// Sets the value and notifies listeners, applying validation if set.
  ///
  /// [value] is the new value to store. If a [validator] is set and rejects the value,
  /// the change is logged and ignored. Otherwise, the state is updated and listeners are notified.
  @override
  set value(T newValue) {
    if (_validator?.call(newValue) ?? true) {
      super.value = newValue;
    } else {
      log('Mastro<${T.runtimeType}> validator failed for value: $newValue');
    }
  }
}

/// A mixin that adds a unique key to state containers for equality comparison.
///
/// This mixin can be applied to subclasses of [Basetro] to provide a unique identifier
/// and override equality and hash code behavior.
mixin UniqueBasetroMixin<T> on Basetro<T> {
  /// The unique identifier for this state container.
  ///
  /// Must be implemented by classes using this mixin to provide a unique key.
  String get key;

  /// Compares this state container to another object for equality.
  ///
  /// Returns `true` if [other] is a [UniqueBasetroMixin] with the same [key] and runtime type,
  /// or if it is the same instance.
  @override
  bool operator ==(Object other) => identical(this, other) || other is UniqueBasetroMixin && runtimeType == other.runtimeType && key == other.key;

  /// Computes the hash code for this state container.
  ///
  /// Returns the hash code of the [key], ensuring consistent equality behavior.
  @override
  int get hashCode => key.hashCode;
}

/// Provides debugging utilities for state containers.
///
/// This extension adds methods to [Basetro] for logging state changes, aiding in development
/// and troubleshooting.
extension BasetroDebug<T> on Basetro<T> {
  /// Logs state changes to the console.
  ///
  /// [name] is an optional label for the state container in logs. Adds a listener that logs
  /// the current [value] whenever the state changes.
  void debugLog([String? name]) {
    addListener(() {
      log('Mastro${name != null ? "($name)" : ""}<$T> updated: $value');
    });
  }
}
