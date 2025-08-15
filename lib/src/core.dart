import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mastro/src/internal/extra.dart';

import 'mutable.dart';

/// ---------------------------------------------------------------------------
/// Overview
/// ---------------------------------------------------------------------------
///
/// This file implements a minimal but expressive state model consisting of:
///
/// - [Basetro]  : an abstract base for single-value state with change notifications.
/// - [Lightro]  : a lightweight state container (value + notify).
/// - [Mastro]   : a full-featured container with:
///                - Observers (side-effects on value changes)
///                - Validation (accept/reject values)
///                - Reactive dependencies via [Mastro.dependsOn] with:
///                  * **compute mode**: recompute `this.value` when any source changes
///                  * **notify-only** : skip recompute, just `notify()` dependents
///
/// Design goals:
/// - Small surface area: you can start with [Lightro] and grow to [Mastro].
/// - Late initialization: `.late()` variants throw a precise error if accessed
///   before being assigned (see [_UninitializedLateInitializationStateException]).
/// - Predictable notifications: `value = ...` and `modify(...)` both call `notify()`.
///
///
/// Quick start
/// -----------
/// ```dart
/// // 1) Lightweight state
/// final count = Lightro<int>.of(0);
/// count.addListener(() => print('count: ${count.value}'));
/// count.value = 1;                    // -> notifies listeners
///
/// // 2) Full-featured state
/// final age = Mastro<int>.of(18);
/// age.setValidator((v) => v >= 0);    // forbid negative values
/// age.observe('log', (v) => print('age: $v'));  // side-effect
/// age.value = 20;                     // ok
/// age.value = -1;                     // rejected; observers not called
///
/// // 3) Dependencies
/// final a = Mastro<int>.of(1);
/// final b = Mastro<int>.of(2);
/// final sum = Mastro<int>.of(0);
///
/// // (a) compute mode: sum becomes a+b whenever either changes
/// sum.dependsOn<int>([a, b], compute: () => a.value + b.value);
///
/// // (b) notify-only: just notify listeners of `sum` when `a` or `b` changes
/// final ping = Lightro<int>.of(0);
/// final watcher = Mastro<void>.late();
/// watcher.dependsOn<int>([ping]); // compute omitted ⇒ notify-only
/// ```
///
///
/// Lifecycle & safety
/// ------------------
/// - Accessing `.value` on `.late()` instances before assignment throws
///   [_UninitializedLateInitializationStateException].
/// - `dispose()` (from [ChangeNotifier]) must be called if you manually manage
///   state lifecycles (e.g., in services) to avoid leaks.
/// - `Mastro.dependsOn` attaches listeners to the sources; these are removed in
///   `dispose()` and when you call `removeDependency(...)`.
///
///
/// Performance notes
/// -----------------
/// - `modify(...)` lets you mutate the internal [Mutable] in-place; this avoids
///   extra allocations and still produces a single notification.
/// - `notify()` is synchronous like in [ChangeNotifier]. Keep handlers quick.
/// - Validation runs before assignment; rejected values do not trigger observers.
///
///
/// Error handling
/// --------------
/// - Late access throws `_UninitializedLateInitializationStateException<T>`.
/// - Validators can call `onValidationError` with the rejected value.
/// - Observers should be resilient; exceptions thrown in an observer will bubble.
///
/// ---------------------------------------------------------------------------

/// Exception thrown when a state container created via `.late()`
/// is accessed before being assigned a value.
///
/// Prevents null-dereference bugs by signaling that the container was marked
/// late but never initialized.
///
/// Example:
/// ```dart
/// final m = Mastro<int>.late(); // no value yet
/// print(m.value);               // throws _UninitializedLateInitializationStateException<int>
/// ```
class _UninitializedLateInitializationStateException<T> implements Exception {
  /// The state container that triggered the exception.
  final Basetro state;

  _UninitializedLateInitializationStateException(this.state);

  @override
  String toString() => 'UninitializedLate${state._typeName}Exception: '
      'You created ${state._typeName}<$T>.late() and are trying to access/modify its value '
      'before initializing it. Consider using `safe` or '
      '`when(uninitialized: ..., initialized: ...)` when working with late states.';
}

/// Callback invoked when a new value fails validation in [Mastro].
typedef ValidationErrorCallback<T> = void Function(T invalidValue);

/// Convenience extensions to create state containers directly from values.
///
/// Example:
/// ```dart
/// final counter = 0.lightro;    // Lightro<int>
/// final toggle  = true.mastro;  // Mastro<bool>
/// ```
extension StateTools<T> on T {
  /// Creates a lightweight [Lightro] initialized with this value.
  Lightro<T> get lightro => Lightro<T>.of(this);

  /// Creates a full-featured [Mastro] initialized with this value.
  Mastro<T> get mastro => Mastro<T>.of(this);
}

/// Utilities for boolean [Basetro] states (toggle / setTrue / setFalse).
extension MastroBoolTools on Basetro<bool> {
  /// Flips the current boolean value and notifies listeners.
  void toggle() => value = !value;

  /// Sets the value to `true` and notifies listeners (if changed).
  void setTrue() => value = true;

  /// Sets the value to `false` and notifies listeners (if changed).
  void setFalse() => value = false;
}

/// Internal marker for [Basetro] initialization status.
sealed class _BasetroState<T> {
  const _BasetroState();
}

/// Initialized state holds a [Mutable] wrapper for the current value.
class _Initialized<T> extends _BasetroState<T> {
  final Mutable<T> data;
  const _Initialized(this.data);
}

/// Uninitialized state — accessing/modifying value throws.
///
/// Any attempt to read `.value` or call `.modify()` will throw
/// [_UninitializedLateInitializationStateException].
class _Uninitialized<T> extends _BasetroState<T> {
  const _Uninitialized();
}

/// Base class for single-value state containers with change notification.
///
/// Implemented by:
/// - [Lightro] — lightweight container: value + notify
/// - [Mastro]  — advanced container: validation, observers, dependencies, etc.
abstract class Basetro<T extends Object?> with ChangeNotifier {
  _BasetroState<T> _state;

  /// Whether to show debug logs for state changes via [mastroLog] (default: `true`).
  final bool _showLogs;

  /// Creates an initialized container with [data].
  Basetro(T data, {bool showLogs = true})
      : _showLogs = showLogs,
        _state = _Initialized(Mutable(data));

  /// Creates an uninitialized container (late init).
  ///
  /// Reading `.value` or calling `.modify()` before initialization
  /// throws [_UninitializedLateInitializationStateException].
  Basetro.late({bool showLogs = true})
      : _showLogs = showLogs,
        _state = const _Uninitialized();

  /// Current value (throws if uninitialized).
  T get value {
    ensureInitialized();
    return (_state as _Initialized<T>).data.value;
  }

  /// Safe accessor: returns `null` if uninitialized, otherwise the value.
  T? get safe => when(uninitialized: () => null, initialized: (v) => v);

  /// Sets the value and notifies listeners (no-op if equal).
  set value(T value) {
    final previousState = _state;
    if (isInitialized && this.value == value) return;
    _state = _Initialized(Mutable(value));
    notify();
    _logStateChange(previousState);
  }

  /// Sets the value **without** notifying listeners.
  ///
  /// Intended for internal flows where batched notification or manual
  /// `notify()` is desired.
  set nonNotifiableSetter(T value) {
    final previousState = _state;
    if (isInitialized && this.value == value) return;
    _state = _Initialized(Mutable(value));
    _logStateChange(previousState);
  }

  /// Modifies the current value via [modifier], then notifies listeners.
  ///
  /// Throws if uninitialized.
  ///
  /// Notes:
  /// - The [modifier] receives the internal [Mutable] reference, allowing
  ///   in-place edits. After it returns (sync or async), a single `notify()`
  ///   is issued.
  /// - Prefer `modify` when you need to read-modify-write to avoid duplicate
  ///   notifications.
  FutureOr<void> modify(FutureOr<void> Function(Mutable<T> state) modifier) async {
    ensureInitialized();
    final previousValue = value;
    await modifier((_state as _Initialized<T>).data);
    notify();
    if (_typeName.startsWith('Persistro')) return;
    if (_showLogs) mastroLog('State($_typeName) modified: $previousValue -> $value');
  }

  /// Whether this container has been initialized.
  bool get isInitialized => _state is _Initialized<T>;

  /// Ensures the container is initialized; throws otherwise.
  void ensureInitialized() {
    if (_state is _Uninitialized<T>) {
      throw _UninitializedLateInitializationStateException<T>(this);
    }
  }

  /// Pattern-match on initialization status and return [W].
  ///
  /// Example:
  /// ```dart
  /// final text = state.when(
  ///   uninitialized: () => 'Loading...',
  ///   initialized: (v) => 'Value: $v',
  /// );
  /// ```
  W when<W>({
    required W Function() uninitialized,
    required W Function(T value) initialized,
  }) {
    return isInitialized ? initialized(value) : uninitialized();
  }

  /// Notifies listeners of a state change.
  void notify() => notifyListeners();

  /// Transitions to the uninitialized state and notifies listeners.
  ///
  /// Useful for tests to simulate late init.
  @visibleForTesting
  void resetToUninitialized() {
    if (_state is _Uninitialized<T>) return;
    if (_showLogs) mastroLog('State($_typeName) changed: $value -> uninitialized');
    _state = const _Uninitialized();
    notify();
  }

  void _logStateChange(_BasetroState<T> previousState) {
    if (_state == previousState || _typeName.startsWith('Persistro')) return;
    if (_showLogs) {
      final prev = previousState is _Initialized<T> ? previousState.data.value : 'uninitialized';
      mastroLog('State($_typeName) changed: $prev -> $value');
    }
  }

  String get _typeName => runtimeType.toString().replaceAll('<$T>', '');
}

/// Lightweight state container: value + notify.
///
/// Use this when you only need a value and change notifications.
class Lightro<T extends Object?> extends Basetro<T> {
  /// Creates an initialized [Lightro] with [data].
  Lightro.of(super.data, {super.showLogs});

  /// Creates an uninitialized (late) [Lightro].
  Lightro.late({super.showLogs}) : super.late();
}

/// Full-featured state container with validation, observers, and dependencies.
///
/// Key features:
/// - **Observers** via [observe]/[removeObserver] + [notifyObservers].
/// - **Validation** via [setValidator].
/// - **Reactive dependencies** via [dependsOn] in two modes:
///   - *Compute mode* (derived value): set `compute: () => ...`
///   - *Notify-only* (side-effect only): omit `compute`
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

  /// Map of `dependency -> listener` for removal and leak prevention.
  final Map<Basetro<Object?>, VoidCallback> _dependencies = {};

  /// Map of `key -> observer callback(value)`.
  final Map<String, void Function(T value)> _observers = {};

  /// Optional validator; if present, must return true to accept a value.
  bool Function(T value)? _validator;

  /// Optional hook invoked when a value fails validation.
  ValidationErrorCallback<T>? _onValidationError;

  /// Declare dependencies on [others] and wire a listener for each.
  ///
  /// ### Modes
  /// - **Compute mode (derived value)**
  ///   Provide [compute]. Whenever **any** dependency changes, `compute()` is
  ///   called and its result is assigned to `this.value` (which triggers a
  ///   notification and observers). Use this to keep a derived state in sync
  ///   with its sources.
  ///
  /// - **Notify-only mode (no value change)**
  ///   Omit [compute]. Whenever any dependency changes, `notify()` is called
  ///   on `this` without assigning a new value. Use this if your listeners
  ///   read directly from external states during builds/effects and you do not
  ///   want to store a derived copy here.
  ///
  /// ### Semantics
  /// - Self-dependency is ignored (`identical(o, this)`).
  /// - Already-wired dependencies are skipped (dedup via `_dependencies`).
  /// - An **initial** recompute/notify runs after wiring so `this` is immediately
  ///   consistent with current dependency values.
  ///
  /// ### Examples
  /// ```dart
  /// final a = Mastro<int>.of(1);
  /// final b = Mastro<int>.of(2);
  /// final sum = Mastro<int>.of(0);
  ///
  /// // compute mode — keeps sum.value == a.value + b.value
  /// sum.dependsOn<int>([a, b], compute: () => a.value + b.value);
  ///
  /// // notify-only — re-render dependents of `watcher` when `tick` changes
  /// final tick = Lightro<int>.of(0);
  /// final watcher = Mastro<void>.late();
  /// watcher.dependsOn<int>([tick]); // no compute ⇒ just notify on change
  /// ```
  void dependsOn<B extends Object?>(
    Iterable<Basetro<B>> others, {
    T Function()? compute,
  }) {
    // Deduplicate + skip self
    final toWire =
        others.where((o) => !identical(o, this) && !_dependencies.containsKey(o)).toSet();
    if (toWire.isEmpty) return;

    void recomputeOrNotify() {
      if (compute == null) {
        // notify-only mode — propagate change without altering value
        notify();
        return;
      }
      // compute mode — set derived value (triggers observers)
      value = compute.call();
    }

    // Attach listeners
    for (final o in toWire) {
      void listener() => recomputeOrNotify();
      o.addListener(listener);
      _dependencies[o] = listener;
    }

    // Immediate alignment (e.g., first paint consistent with sources)
    recomputeOrNotify();
  }

  /// Removes a previously added dependency on [other].
  ///
  /// Safe no-op if [other] was not wired.
  void removeDependency<B extends Object?>(Basetro<B> other) {
    final listener = _dependencies[other];
    if (listener != null) {
      other.removeListener(listener);
      _dependencies.remove(other);
    }
  }

  /// Removes all dependency listeners previously added via [dependsOn].
  ///
  /// This method:
  /// 1. Iterates over the internally tracked `_dependencies` map.
  /// 2. Calls `removeListener` on each dependency to detach this state from it.
  /// 3. Clears the `_dependencies` map entirely.
  ///
  /// **When to use:**
  /// - When this state object no longer needs to react to any of its
  ///   registered dependencies (e.g., during `dispose()`).
  /// - When you want to rewire dependencies dynamically without risk of
  ///   duplicate listeners.
  ///
  /// **Notes:**
  /// - Safe to call multiple times — subsequent calls will no-op if
  ///   `_dependencies` is already empty.
  /// - Does not affect other observers/listeners unrelated to [dependsOn].
  void clearDependencies() {
    for (final e in _dependencies.entries) {
      e.key.removeListener(e.value);
    }
    _dependencies.clear();
  }

  /// Adds or replaces an observer identified by [key].
  ///
  /// If an observer with the same key exists, it will be overwritten.
  void observe(String key, void Function(T value) callback) {
    if (_observers.containsKey(key)) {
      mastroLog('Observer with key "$key" already exists — it will be replaced.');
    }
    _observers[key] = callback;
  }

  /// Removes an observer by [key] (no-op if missing).
  void removeObserver(String key) {
    _observers.remove(key);
  }

  /// Sets a validation rule for values assigned to this [Mastro].
  ///
  /// If validation fails, the value is not set and [onValidationError] (if
  /// provided) is invoked with the rejected value.
  void setValidator(
    bool Function(T value) validator, {
    ValidationErrorCallback<T>? onValidationError,
  }) {
    _validator = validator;
    _onValidationError = onValidationError;
  }

  /// Notifies registered observers of the current value.
  @protected
  void notifyObservers() {
    if (!isInitialized) return;
    final observers = _observers.values.toList(growable: false);
    for (final o in observers) {
      o(value);
    }
  }

  @override
  void dispose() {
    clearDependencies();
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
      _onValidationError?.call(value);
      if (_showLogs) {
        mastroLog('Mastro(${value.runtimeType}) validator rejected: $value');
      }
    }
  }

  @override
  set value(T newValue) {
    if (_validator?.call(newValue) ?? true) {
      super.value = newValue;
    } else {
      _onValidationError?.call(newValue);
      if (_showLogs) {
        mastroLog('Mastro(${newValue.runtimeType}) validator rejected: $newValue');
      }
    }
  }

  /// Triggers a notification without changing the value (handy in tests).
  @visibleForTesting
  void simulateNotify() => notify();

  /// Returns a read-only view of current dependencies (testing/debugging).
  @visibleForTesting
  Map<Basetro, VoidCallback> get testDependencies => Map.unmodifiable(_dependencies);

  /// Returns a read-only view of current observers (testing/debugging).
  @visibleForTesting
  Map<String, void Function(T value)> get testObservers => Map.unmodifiable(_observers);
}
