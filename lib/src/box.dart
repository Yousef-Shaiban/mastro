import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';
import 'package:mastro/src/internal/extra.dart';

/// ## MastroBox
///
/// Orchestrates UI signaling (tags), loose callbacks, and event execution with
/// **parallel / sequential / solo** policies.
///
/// Behavior:
/// - **SEQUENTIAL (awaitable):**
///   - If a lane is busy for a given event *type*, `execute(...)` enqueues and
///     returns a `Future` that completes when **that specific item** finishes.
///   - The first (lane owner) call does **not** await the entire drain; it
///     returns right after its own item finishes. The queue is drained
///     asynchronously (per-type FIFO preserved).
///   - Each queued item preserves its own `around` wrapper (e.g., pop-block UI).
abstract class MastroBox<T extends MastroEvent> {
  /// Constructs a new [MastroBox] and calls [init].
  MastroBox() {
    init();
  }

  // ───────────────────────────── Tagging & callbacks ──────────────────────────

  /// Reactive tag used by `TagBuilder` to trigger view updates.
  final _subTagTrigger = Lightro.of('');

  /// Loose key → callback registry used by [trigger].
  final _subTagCallbacks = <String, void Function(Map<String, dynamic>? data)>{};

  /// Set a tag value and notify listeners.
  @mustCallSuper
  void tag({required String tag}) {
    _subTagTrigger.nonNotifiableSetter = tag;
    _subTagTrigger.notify();
  }

  /// Current tag as a listenable (consumed by TagBuilder).
  Lightro get taggable => _subTagTrigger;

  /// Invoke a registered loose callback by [key]. No-op if missing.
  @mustCallSuper
  void trigger({required String key, Map<String, dynamic>? data}) {
    _subTagCallbacks[key]?.call(data);
  }

  /// Register a loose callback for [key] (overwrites if exists).
  @mustCallSuper
  void registerCallback({
    required String key,
    required void Function(Map<String, dynamic>? data) callback,
  }) {
    _subTagCallbacks[key] = callback;
  }

  /// Remove a previously registered callback.
  @mustCallSuper
  void unregisterCallback({required String key}) {
    _subTagCallbacks.remove(key);
  }

  // ────────────────────────────── View lifecycle ──────────────────────────────

  /// Currently attached views; used to drive auto-cleanup.
  final _attachedViews = <MastroView>[];

  /// Controls auto-cleanup when all views detach. Defaults to `true`.
  final _autoCleanupWhenAllViewsDetached = Mutable(true);

  /// Whether this box should auto-cleanup after the last view detaches.
  bool get autoCleanupWhenAllViewsDetached => _autoCleanupWhenAllViewsDetached.value;

  /// Toggle auto-cleanup behavior.
  set autoCleanupWhenAllViewsDetached(bool value) => _autoCleanupWhenAllViewsDetached.value = value;

  /// Called when a [MastroView] attaches. Always call `super`.
  @mustCallSuper
  void onViewAttached(MastroView view) {
    _attachedViews.add(view);
    mastroLog("MastroView(${view.runtimeType}) attached to MastroBox($runtimeType)");
  }

  /// Called when a [MastroView] detaches. Always call `super`.
  ///
  /// If [autoCleanupWhenAllViewsDetached] is `true` and this was the last view,
  /// [cleanup] is called automatically.
  @mustCallSuper
  void onViewDetached(MastroView view) {
    _attachedViews.remove(view);
    mastroLog("MastroView(${view.runtimeType}) detached from MastroBox($runtimeType)");
    if (autoCleanupWhenAllViewsDetached && _attachedViews.isEmpty) {
      mastroLog(
        "MastroBox($runtimeType) auto-cleaned after last view detached "
        "(flip [autoCleanupWhenAllViewsDetached] to change).",
      );
      cleanup();
    }
  }

  // ───────────────────────────────── Lifecycle ────────────────────────────────

  /// Initialize this box. Subclasses may override; call `super.init()`.
  @mustCallSuper
  void init() {
    mastroLog("MastroBox($runtimeType) init()");
  }

  /// Public, idempotent cleanup. Safe to call multiple times.
  ///
  /// - Completes any **queued sequential items** with an error to avoid hanging Futures.
  /// - Clears active flags, queues, views list, and loose callbacks.
  @mustCallSuper
  void cleanup() {
    mastroLog("MastroBox($runtimeType) cleanup()");
    for (final q in _seqQueues.values) {
      for (final entry in q) {
        if (!entry.completer.isCompleted) {
          entry.completer.completeError(
            StateError('MastroBox($runtimeType) cleaned up while event was queued'),
          );
        }
      }
      q.clear();
    }
    _activeSoloEvents.clear();
    _activeSequentialEvents.clear();
    _seqQueues.clear();
    _attachedViews.clear();
    _subTagCallbacks.clear();
    // Note: we cannot reliably flip any active OnPopScope off here without a BuildContext.
    // The guard map is ephemeral and will naturally drop as this instance is GC'd.
    _popGuards.clear();
  }

  // ──────────────────────────────── Execution ────────────────────────────────

  /// Per-type SOLO guard: currently running SOLO event types.
  final _activeSoloEvents = <Type>{};

  /// Runtime types currently running a SEQUENTIAL lane.
  final _activeSequentialEvents = <Type>{};

  /// Per-type FIFO queues for SEQUENTIAL events.
  final Map<Type, Queue<_QueuedEvent<MastroEvent>>> _seqQueues = {};

  /// Back-blocking guard counts per [OnPopScope] (for BlockPop events).
  ///
  /// We increment on each `_awaitLoading` begin and decrement on finally.
  /// `isLoading` flips to true when count goes 0→1, and to false when it goes 1→0.
  final Map<OnPopScope, int> _popGuards = {};

  /// Default callbacks instance when callers pass `null`.
  Callbacks get _defaultCallbacks => Callbacks.on(defaultCallbacksName, (_) {});

  /// Core runner used by both [execute] and [executeBlockPop].
  ///
  /// - Applies SOLO/SEQUENTIAL policies.
  /// - Optionally wraps execution with [around] (e.g., to block back navigation).
  /// - Ensures proper lane cleanup (flags cleared after queue drains).
  Future<void> _run(
    T event, {
    Callbacks? callbacks,
    EventRunningMode? mode,
    Future<void> Function(Future<void> Function())? around,
  }) async {
    final effectiveMode = mode ?? event.mode;
    final type = event.runtimeType;

    // SOLO: per-type exclusivity
    if (effectiveMode == EventRunningMode.solo) {
      if (_activeSoloEvents.contains(type)) {
        mastroLog('MastroBox($runtimeType): SOLO($type) already running, ignored.');
        return;
      }
      _activeSoloEvents.add(type);
    }

    // SEQUENTIAL: per-type lane (queue if lane already active)
    if (effectiveMode == EventRunningMode.sequential) {
      if (_activeSequentialEvents.contains(type)) {
        mastroLog('MastroBox($runtimeType): SEQUENTIAL($type) queued.');
        // Awaitable: enqueue and return this item's future.
        return _enqueueSequential(event, callbacks, around);
      } else {
        _activeSequentialEvents.add(type);
      }
    }

    Future<void> runImpl() => event.implement(this, callbacks ?? _defaultCallbacks);

    try {
      if (around != null) {
        await around(runImpl);
      } else {
        await runImpl();
      }
    } finally {
      if (effectiveMode == EventRunningMode.sequential) {
        // Fire-and-forget drain so the first caller doesn't await the entire lane.
        unawaited(
          _processSequentialEvents(type).catchError((e, st) {
            mastroLog(
              'MastroBox($runtimeType): error while draining SEQUENTIAL($type): $e',
            );
          }).whenComplete(() {
            _activeSequentialEvents.remove(type);
          }),
        );
      }
      if (effectiveMode == EventRunningMode.solo) {
        _activeSoloEvents.remove(type);
      }
    }
  }

  /// Enqueue a SEQUENTIAL [event] to its per-type queue and
  /// return a Future that completes when **that specific queued item** finishes.
  Future<void> _enqueueSequential(
    T event,
    Callbacks? callbacks,
    Future<void> Function(Future<void> Function())? around,
  ) async {
    final type = event.runtimeType;
    final q = _seqQueues.putIfAbsent(type, () => Queue<_QueuedEvent<MastroEvent>>());
    final qe = _QueuedEvent<MastroEvent>(event, callbacks, around);
    q.add(qe);
    return await qe.completer.future;
  }

  /// Drain the SEQUENTIAL queue for [eventType] in FIFO order.
  ///
  /// Continues on errors; the **first** error is rethrown (with original stack)
  /// *after* the queue is emptied so later items still run. Each queued call’s
  /// Future is completed individually (success or error).
  Future<void> _processSequentialEvents(Type eventType) async {
    final q = _seqQueues[eventType];
    if (q == null || q.isEmpty) return;

    Object? firstError;
    StackTrace? firstStack;

    while (q.isNotEmpty) {
      final next = q.removeFirst();

      Future<void> runImpl() => next.event.implement(this, next.callbacks ?? _defaultCallbacks);

      try {
        if (next.around != null) {
          await next.around!(runImpl);
        } else {
          await runImpl();
        }
        if (!next.completer.isCompleted) {
          next.completer.complete();
        }
      } catch (e, st) {
        if (!next.completer.isCompleted) {
          next.completer.completeError(e, st);
        }
        firstError ??= e;
        firstStack ??= st;
      }
    }

    _seqQueues.remove(eventType);

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  }

  /// Execute an event with normal behavior (no pop blocking).
  ///
  /// - Returns a `Future` that completes when the event is done.
  /// - For **queued sequential** events, the `Future` completes when *that* queued item runs.
  Future<void> execute(
    T event, {
    Callbacks? callbacks,
    EventRunningMode? mode,
  }) =>
      _run(event, callbacks: callbacks, mode: mode);

  /// Execute an event while **blocking back navigation** via an [OnPopScope]
  /// provided by the nearest `MastroScope`.
  ///
  /// Reference-counted: if multiple BlockPop events overlap on the same
  /// [OnPopScope], back navigation is unblocked only after the last one finishes.
  ///
  /// Throws a [StateError] if `OnPopScope` is not available.
  @nonVirtual
  Future<void> executeBlockPop(
    BuildContext context,
    T event, {
    Callbacks? callbacks,
    EventRunningMode? mode,
  }) =>
      _run(
        event,
        callbacks: callbacks,
        mode: mode,
        around: (runner) => _awaitLoading(future: runner, context: context),
      );

  /// Wrap a future with an `OnPopScope`-driven loading/disable-back phase.
  ///
  /// Uses a **reference-counted** guard so overlapping BlockPop calls
  /// don't prematurely re-enable back navigation.
  Future<void> _awaitLoading({
    required AsyncCallback future,
    required BuildContext context,
  }) async {
    final popScope = ClassProvider.ofNullable<OnPopScope>(context);
    if (popScope == null) {
      throw StateError(
        'Cannot execute BlockPop events without MastroScope!\n\n'
        'Wrap your app:\n'
        'MastroScope(\n'
        '  onPopScope: OnPopScope(onPopWaitMessage: (context) { .... }),\n'
        '  child: MaterialApp(\n'
        '    home: YourHomeWidget()\n'
        '  ),\n'
        ')',
      );
    }

    _popGuardBegin(popScope);
    try {
      await future();
    } finally {
      _popGuardEnd(popScope);
    }
  }

  /// Increment the BlockPop guard for [popScope].
  void _popGuardBegin(OnPopScope popScope) {
    final current = _popGuards[popScope] ?? 0;
    _popGuards[popScope] = current + 1;
    if (current == 0) {
      if (!popScope.isLoading.value) {
        popScope.isLoading.value = true;
        mastroLog('Back navigation blocked');
      }
    }
  }

  /// Decrement the BlockPop guard for [popScope] and release if last.
  void _popGuardEnd(OnPopScope popScope) {
    final current = _popGuards[popScope] ?? 0;
    if (current <= 1) {
      _popGuards.remove(popScope);
      if (popScope.isLoading.value) {
        popScope.isLoading.value = false;
        mastroLog('Back navigation unblocked');
      }
    } else {
      _popGuards[popScope] = current - 1;
    }
  }
}

/// Internal wrapper for queued events (used by per-type SEQUENTIAL queues).
class _QueuedEvent<E extends MastroEvent> {
  final E event;
  final Callbacks? callbacks;
  final Completer<void> completer;

  /// Per-item wrapper to apply when this queued event runs.
  final Future<void> Function(Future<void> Function())? around;

  _QueuedEvent(this.event, this.callbacks, this.around) : completer = Completer<void>();
}
