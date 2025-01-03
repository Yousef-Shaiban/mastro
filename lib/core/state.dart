import 'dart:developer';

import 'package:flutter/material.dart';

import 'mutable.dart';

/// Extension methods for creating state containers.
extension StateTools<T> on T {
  /// Creates a lightweight state container.
  Lightro<T> get lightro {
    return Lightro<T>.of(this);
  }

  /// Creates a full-featured state container.
  Mastro<T> get mastro {
    return Mastro<T>.of(this);
  }
}

/// Extension for boolean state containers.
extension MastroBoolTools on Basetro<bool> {
  /// Toggles the boolean value.
  void toggle() {
    value = !value;
  }
}

/// Base class for state containers with change notification.
abstract class Basetro<T> with ChangeNotifier {
  late final Mutable<T> _data;

  /// Creates a new state container with initial data.
  Basetro(T data) {
    _data = Mutable(data);
  }

  /// Gets or sets the current value.
  T get value => _data.value;
  set value(T value) {
    if (_data.value != value) {
      _data.value = value;
      notify();
    }
  }

  /// Sets the value without notifying listeners.
  set nonNotifiableSetter(T value) {
    _data.value = value;
  }

  /// Modifies the state with a callback.
  void modify(void Function(Mutable<T> state) modify) {
    modify(_data);
    notify();
  }

  /// Notifies listeners of state changes.
  void notify() => notifyListeners();
}

/// Lightweight state container.
class Lightro<T> extends Basetro<T> {
  /// Creates a new Lightro instance.
  Lightro.of(super.data);
}

/// Full-featured state container with computed values and dependencies.
class Mastro<T> extends Basetro<T> {
  /// Creates a new Mastro instance.
  Mastro.of(super.data);

  /// Creates a computed state that depends on this state.
  Mastro<R> compute<R>(R Function(T value) calculator) {
    final computed = calculator(value).mastro;
    void listener() => computed.value = calculator(value);
    addListener(listener);
    _computedStates[computed] = listener;
    return computed;
  }

  /// Adds a dependency on another state.
  void dependsOn(Basetro other) {
    void listener() => notify();
    other.addListener(listener);
    _dependencies[other] = listener;
  }

  /// Removes a dependency.
  void removeDependency(Mastro other) {
    final listener = _dependencies[other];
    if (listener != null) {
      other.removeListener(listener);
      _dependencies.remove(other);
    }
  }

  /// Adds an observer callback.
  void observe(String key, void Function(T value) callback) {
    _observers[key] = callback;
  }

  /// Removes an observer.
  void removeObserver(String key) {
    _observers.remove(key);
  }

  /// Sets a validation function for value changes.
  void setValidator(bool Function(T value) validator) {
    _validator = validator;
  }

  /// Notifies all observers of state changes.
  void notifyObservers() {
    for (final observer in _observers.values) {
      observer(value);
    }
  }

  final Map<Basetro, VoidCallback> _computedStates = {};
  final Map<Basetro, VoidCallback> _dependencies = {};
  final Map<String, void Function(T value)> _observers = {};
  bool Function(T value)? _validator;

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
      log('Mastro<${T.runtimeType}> validator failed for value: $value');
    }
  }

  @override
  set value(T newValue) {
    if (_validator?.call(newValue) ?? true) {
      super.value = newValue;
    } else {
      log('Mastro<${T.runtimeType}> validator failed for value: $value');
    }
  }
}

/// Mixin for state containers with unique key
mixin UniqueBasetroMixin<T> on Basetro<T> {
  /// Unique identifier for this state container.
  String get key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueBasetroMixin &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// Extension for debugging state containers.
extension BasetroDebug<T> on Basetro<T> {
  /// Logs state changes to the console.
  void debugLog([String? name]) {
    addListener(() {
      log('Mastro${name != null ? "($name)" : ""}<$T> updated: $value');
    });
  }
}
