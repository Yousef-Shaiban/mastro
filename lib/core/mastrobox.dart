import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'events.dart';
import 'providers.dart';
import 'scopes.dart';
import 'state.dart';

/// Base class for managing state and events in the Mastro framework.
///
/// This abstract class provides mechanisms for tagging, event execution, and callback management.
/// Subclasses define specific behavior for a given event type.
///
/// Type parameter [T] represents the type of [MastroEvent] this box handles.
abstract class MastroBox<T extends MastroEvent> {
  /// Creates a new [MastroBox] instance.
  MastroBox();

  /// Internal state for managing tags.
  final _subTagTrigger = Mastro.of('');

  /// Weak references to registered callbacks.
  final _subTagCallbacks = <String, WeakReference<void Function({Map<String, dynamic>? data})>>{};

  /// Tracks active solo events by type.
  final _activeSoloEvents = <Type>{};

  /// Tracks active sequential events by type.
  final _activeSequentialEvents = <Type>{};

  /// Queue for sequential events awaiting execution.
  final _sequentialEventsQueue = <_QueuedEvent>[];

  /// Initializes the box.
  ///
  /// Subclasses should override this to set up initial state or resources. Calls to
  /// [super.init] are required to ensure proper framework initialization.
  @mustCallSuper
  void init() {}

  /// Disposes of resources used by this box.
  ///
  /// Subclasses should override this to clean up specific resources, calling [super.dispose]
  /// to ensure proper cleanup of framework-level resources.
  @mustCallSuper
  void dispose() {
    _dispose();
  }

  /// Internal method to clean up resources.
  void _dispose() {
    _activeSoloEvents.clear();
    _sequentialEventsQueue.clear();
    _subTagTrigger.dispose();
    _cleanupCallbacks(force: true);
  }

  /// Notifies [TagBuilder] widgets using a specific tag.
  ///
  /// [tag] is the identifier to set on [taggable], triggering rebuilds in any [TagBuilder]
  /// listening for this tag.
  void tag({required String tag}) {
    _subTagTrigger.nonNotifiableSetter = tag;
    _subTagTrigger.notify();
  }

  /// The current tag state of this box.
  ///
  /// Returns a [Mastro] instance that holds the current tag value, used by [TagBuilder] to
  /// monitor changes.
  Mastro get taggable => _subTagTrigger;

  /// Triggers a callback associated with the given key.
  ///
  /// [key] identifies the callback to invoke. [data] is an optional map of parameters to pass.
  /// Does nothing if the callback is not registered or has been garbage collected.
  void trigger({required String key, Map<String, dynamic>? data}) {
    _cleanupCallbacks();
    if (_subTagCallbacks.containsKey(key)) {
      _subTagCallbacks[key]?.target?.call(data: data);
    }
  }

  /// Registers a callback function with the given key.
  ///
  /// [key] is the unique identifier for the callback. [callback] is the function to register,
  /// which may receive optional [data] when triggered.
  void registerCallback({
    required String key,
    required void Function({Map<String, dynamic>? data}) callback,
  }) {
    _cleanupCallbacks();
    _subTagCallbacks[key] = WeakReference(callback);
  }

  /// Unregisters a callback associated with the given key.
  ///
  /// [key] identifies the callback to remove. Does nothing if the key is not registered.
  void unregisterCallback({
    required String key,
  }) {
    _cleanupCallbacks();
    _subTagCallbacks.remove(key);
  }

  /// Executes an asynchronous operation while indicating loading state.
  ///
  /// [future] is the operation to perform. [context] is used to access the [OnPopScope] for
  /// managing loading state. Throws a [StateError] if no [OnPopScope] is found in the widget tree.
  Future<void> _awaitLoading({
    required AsyncCallback future,
    required BuildContext context,
  }) async {
    final popScope = ClassProvider.ofNullable<OnPopScope>(context);
    if (popScope == null) {
      throw StateError(
        ''
        'Cannot execute BlockPop events without MastroScope!\n\n'
        'Please wrap your app with MastroScope and provide an OnPopScope:\n\n'
        'void main() {\n'
        '  runApp(MaterialApp(\n'
        '    home: MastroScope(\n'
        '      onPopScope: OnPopScope(\n'
        '        onPopWaitMessage: () {\n'
        '          // Your loading message logic\n'
        '        },\n'
        '      ),\n'
        '      child: YourHomeWidget(),\n'
        '    ),\n'
        '  ));\n'
        '}\n',
      );
    }
    popScope.isLoading.value = true;
    try {
      await future();
    } catch (_) {
      rethrow;
    } finally {
      popScope.isLoading.value = false;
    }
  }

  /// Adds an event to be processed.
  ///
  /// [event] is the [MastroEvent] to execute. [callbacks] is an optional [Callbacks] instance
  /// for post-execution actions. Returns a [Future] that completes when the event finishes,
  /// respecting the event’s [EventRunningMode].
  Future<void> execute(
    T event, {
    Callbacks? callbacks,
  }) async {
    if (_activeSoloEvents.contains(event.runtimeType)) {
      log('MASTRO: EVENT_MODE_SOLO_(${event.runtimeType}) IS ALREADY RUNNING');
      return;
    }
    if (event.mode == EventRunningMode.sequential) {
      if (_activeSequentialEvents.contains(event.runtimeType)) {
        log('MASTRO: EVENT_MODE_SEQUENTIAL_(${event.runtimeType}) GOT QUEUED');
        _sequentialEventsQueue.add(_QueuedEvent(event, callbacks));
        return;
      } else {
        _activeSequentialEvents.add(event.runtimeType);
      }
    } else if (event.mode == EventRunningMode.solo) {
      _activeSoloEvents.add(event.runtimeType);
    }
    try {
      await event.implement(this, callbacks ?? Callbacks());
      await _processSequentialEvents(event.runtimeType);
    } catch (_) {
      rethrow;
    } finally {
      if (event.mode == EventRunningMode.sequential) {
        _activeSequentialEvents.remove(event.runtimeType);
      } else if (event.mode == EventRunningMode.solo) {
        _activeSoloEvents.remove(event.runtimeType);
      }
    }
  }

  /// Adds an event that blocks pop navigation while processing.
  ///
  /// [context] is the [BuildContext] used to manage loading state via [OnPopScope].
  /// [event] is the [MastroEvent] to execute. [callbacks] is an optional [Callbacks] instance
  /// for post-execution actions. Returns a [Future] that completes when the event finishes.
  @nonVirtual
  Future<void> executeBlockPop(
    BuildContext context,
    T event, {
    Callbacks? callbacks,
  }) async {
    if (_activeSoloEvents.contains(event.runtimeType)) {
      log('MASTRO: EVENT_MODE_SOLO_(${event.runtimeType}) IS ALREADY RUNNING');
      return;
    }
    if (event.mode == EventRunningMode.sequential) {
      if (_activeSequentialEvents.contains(event.runtimeType)) {
        log('MASTRO: EVENT_MODE_SEQUENTIAL_(${event.runtimeType}) GOT QUEUED');
        _sequentialEventsQueue.add(_QueuedEvent(event, callbacks));
        return;
      } else {
        _activeSequentialEvents.add(event.runtimeType);
      }
    } else if (event.mode == EventRunningMode.solo) {
      _activeSoloEvents.add(event.runtimeType);
    }
    try {
      await _awaitLoading(future: () => event.implement(this, callbacks ?? Callbacks()), context: context);
      await _processSequentialEvents(event.runtimeType);
    } catch (_) {
      rethrow;
    } finally {
      if (event.mode == EventRunningMode.sequential) {
        _activeSequentialEvents.remove(event.runtimeType);
      } else if (event.mode == EventRunningMode.solo) {
        _activeSoloEvents.remove(event.runtimeType);
      }
    }
  }

  /// Processes queued sequential events of a specific type.
  ///
  /// [eventType] is the type of events to process from the queue. Executes events in order
  /// until the queue is empty for that type.
  Future<void> _processSequentialEvents(Type eventType) async {
    if (!_sequentialEventsQueue.any((element) => element.event.runtimeType == eventType)) {
      return;
    }

    while (_sequentialEventsQueue.where((element) => element.event.runtimeType == eventType).isNotEmpty) {
      final queuedEvent = _sequentialEventsQueue.where((element) => element.event.runtimeType == eventType).first;
      try {
        await queuedEvent.event.implement(this, queuedEvent.callbacks ?? Callbacks());
      } catch (_) {
        rethrow;
      } finally {
        _sequentialEventsQueue.remove(queuedEvent);
      }
    }
  }

  /// Removes callbacks that have been garbage collected.
  ///
  /// [force] triggers cleanup regardless of size threshold. Cleanup is skipped unless
  /// the callback count exceeds 100, improving performance for small sets.
  void _cleanupCallbacks({bool force = false}) {
    if (force || _subTagCallbacks.length > 100) {
      _subTagCallbacks.removeWhere((_, ref) => ref.target == null);
    }
  }
}

/// Represents a queued event with its associated callbacks.
///
/// Type parameter [T] is the type of [MastroEvent] being queued.
class _QueuedEvent<T extends MastroEvent> {
  /// The event to be executed.
  final T event;

  /// Optional callbacks to trigger after execution.
  final Callbacks? callbacks;

  /// Creates a queued event instance.
  _QueuedEvent(this.event, this.callbacks);
}
