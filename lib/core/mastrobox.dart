import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'events.dart';
import 'providers.dart';
import 'scopes.dart';
import 'state.dart';

abstract class MastroBox<T extends MastroEvent> {
  MastroBox();

  final _subTagTrigger = Mastro.of('');
  final _subTagCallbacks =
      <String, WeakReference<void Function({Map<String, dynamic>? data})>>{};
  final _activeSoloEvents = <Type>{};
  final _activeSequentialEvents = <Type>{};
  final _sequentialEventsQueue = <_QueuedEvent>[];

  void init() {}

  @mustCallSuper
  void dispose() {
    _dispose();
  }

  void _dispose() {
    _activeSoloEvents.clear();
    _sequentialEventsQueue.clear();
    _subTagTrigger.dispose();
    _cleanupCallbacks();
  }

  void tag({required String tag, Map<String, dynamic>? data}) {
    _cleanupCallbacks();
    if (_subTagCallbacks.containsKey(tag)) {
      _subTagCallbacks[tag]?.target?.call(data: data);
    }
    _subTagTrigger.nonNotifiableSetter = tag;
    _subTagTrigger.notify();
  }

  Mastro get taggable => _subTagTrigger;

  void registerTagCallback(
      {required String tag,
      required void Function({Map<String, dynamic>? data}) callback}) {
    _cleanupCallbacks();
    _subTagCallbacks[tag] = WeakReference(callback);
  }

  void unregisterTagCallback({required String tag}) {
    _cleanupCallbacks();
    _subTagCallbacks.remove(tag);
  }

  Future<void> _awaitLoading(
      {required AsyncCallback future, required BuildContext context}) async {
    final popScope = ClassProvider.ofNullable<OnPopScope>(context);
    if (popScope == null) {
      throw StateError(
        ''
        'Cannot execute BlockPop events without MastroApp!\n\n'
        'Please wrap your app with MastroApp and provide an OnPopScope:\n\n'
        'void main() {\n'
        '  runApp(MaterialApp(\n'
        '    home: MastroApp(\n'
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
    } finally {
      popScope.isLoading.value = false;
    }
  }

  Future<void> addEvent(
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
    } catch (e) {
      rethrow;
    } finally {
      if (event.mode == EventRunningMode.sequential) {
        _activeSequentialEvents.remove(event.runtimeType);
      } else if (event.mode == EventRunningMode.solo) {
        _activeSoloEvents.remove(event.runtimeType);
      }
    }
  }

  @nonVirtual
  Future<void> addEventBlockPop(
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
      await _awaitLoading(
          future: () => event.implement(this, callbacks ?? Callbacks()),
          context: context);
      await _processSequentialEvents(event.runtimeType);
    } catch (e) {
      rethrow;
    } finally {
      if (event.mode == EventRunningMode.sequential) {
        _activeSequentialEvents.remove(event.runtimeType);
      } else if (event.mode == EventRunningMode.solo) {
        _activeSoloEvents.remove(event.runtimeType);
      }
    }
  }

  Future<void> _processSequentialEvents(Type eventType) async {
    if (!_sequentialEventsQueue
        .any((element) => element.event.runtimeType == eventType)) {
      return;
    }

    while (_sequentialEventsQueue
        .where((element) => element.event.runtimeType == eventType)
        .isNotEmpty) {
      final queuedEvent = _sequentialEventsQueue
          .where((element) => element.event.runtimeType == eventType)
          .first;
      try {
        await queuedEvent.event
            .implement(this, queuedEvent.callbacks ?? Callbacks());
      } catch (e) {
        rethrow;
      } finally {
        _sequentialEventsQueue.remove(queuedEvent);
      }
    }
  }

  void _cleanupCallbacks() {
    _subTagCallbacks.removeWhere((_, ref) => ref.target == null);
  }
}

class _QueuedEvent<T extends MastroEvent> {
  final T event;
  final Callbacks? callbacks;

  _QueuedEvent(this.event, this.callbacks);
}
