import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'mastrobox.dart';
import 'state.dart';

/// A widget that rebuilds when a specific tag in a [MastroBox] changes.
///
/// This widget listens to the [MastroBox.taggable] state and triggers a rebuild when the
/// specified [tag] matches the current tag value in the box.
class TagBuilder extends StatefulWidget {
  /// The tag to listen for changes.
  final String tag;

  /// The [MastroBox] instance to monitor for tag changes.
  final MastroBox box;

  /// The builder function that constructs the widget tree.
  ///
  /// Called with the current [BuildContext] whenever the widget rebuilds due to a tag match.
  final Widget Function(BuildContext context) builder;

  /// Creates a [TagBuilder] widget.
  ///
  /// [tag] specifies the tag to monitor, [box] is the [MastroBox] to observe, and [builder]
  /// defines the widget tree to render. The [key] parameter is optional for widget identity.
  const TagBuilder({
    super.key,
    required this.tag,
    required this.builder,
    required this.box,
  });

  @override
  State<TagBuilder> createState() => _TagBuilderState();
}

/// The state class for [TagBuilder].
class _TagBuilderState extends State<TagBuilder> {
  /// Updates the widget state when the tag matches.
  ///
  /// Checks if the widget is still mounted and if the [widget.tag] matches the current
  /// [MastroBox.taggable] value. Schedules a rebuild after the current frame if needed.
  void _updateState() async {
    if (context.mounted && widget.tag == widget.box.taggable.value) {
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        await SchedulerBinding.instance.endOfFrame;
        if (!context.mounted) return;
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.box.taggable.addListener(_updateState);
  }

  @override
  void dispose() {
    super.dispose();
    widget.box.taggable.removeListener(_updateState);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// A widget that rebuilds when state changes in a [Basetro] object.
///
/// This widget monitors a primary [Basetro] state and optionally additional states, rebuilding
/// its widget tree when any monitored state changes, subject to an optional [shouldRebuild] condition.
///
/// Type parameter [T] represents the type of the primary state being monitored.
class MastroBuilder<T> extends StatefulWidget {
  /// The primary state object to monitor for changes.
  final Basetro<T> state;

  /// The builder function that constructs the widget tree.
  ///
  /// Called with the current [state] and [BuildContext] whenever the widget rebuilds.
  final Widget Function(Basetro<T> state, BuildContext context) builder;

  /// Optional list of additional state objects to monitor.
  ///
  /// If provided, changes in any of these [Basetro] instances will also trigger a rebuild.
  final List<Basetro<dynamic>>? listeners;

  /// Optional callback to determine if the widget should rebuild.
  ///
  /// Called with the previous and current values of [state]. Returns `true` to trigger a rebuild,
  /// or `false` to skip it. If null, the widget rebuilds on every state change.
  final bool Function(T previous, T current)? shouldRebuild;

  /// Creates a [MastroBuilder] widget.
  ///
  /// [state] is the primary state to monitor, [builder] defines the widget tree, [listeners]
  /// adds optional secondary states, and [shouldRebuild] controls rebuild conditions.
  /// The [key] parameter is optional for widget identity.
  const MastroBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.listeners,
    this.shouldRebuild,
  });

  @override
  State<MastroBuilder<T>> createState() => _MastroBuilderState<T>();
}

/// The state class for [MastroBuilder].
class _MastroBuilderState<T> extends State<MastroBuilder<T>> {
  /// The previous value of the state, used for [shouldRebuild] comparisons.
  T? _previousValue;

  /// Updates the widget state when the monitored state changes.
  ///
  /// Checks if the widget is mounted, evaluates [shouldRebuild] if provided, and schedules a
  /// rebuild with the current value if conditions are met.
  void _updateState() async {
    if (!context.mounted) return;

    final currentValue = widget.state.value;
    if (widget.shouldRebuild?.call(_previousValue as T, currentValue) ?? true) {
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        await SchedulerBinding.instance.endOfFrame;
        if (!context.mounted) return;
      }
      setState(() {
        _previousValue = currentValue;
      });
    }
  }

  /// Sets up listeners for the primary and optional secondary states.
  void _setupListeners() {
    if (widget.listeners == null) {
      widget.state.addListener(_updateState);
    } else {
      widget.state.addListener(_updateState);
      for (final element in widget.listeners!) {
        element.addListener(_updateState);
      }
    }
  }

  /// Removes listeners from the primary and optional secondary states.
  void _cleanupListeners() {
    if (widget.listeners == null) {
      widget.state.removeListener(_updateState);
    } else {
      widget.state.removeListener(_updateState);
      for (final element in widget.listeners!) {
        element.removeListener(_updateState);
      }
    }
  }

  @override
  void initState() {
    _setupListeners();
    super.initState();
  }

  @override
  void didUpdateWidget(MastroBuilder<T> oldWidget) {
    if (oldWidget.listeners != widget.listeners || oldWidget.state != widget.state) {
      _cleanupListeners();
      _setupListeners();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _cleanupListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(widget.state, context);
  }
}

/// Provides extension methods for [Basetro] to simplify widget building.
///
/// This extension adds a convenient method to create a [MastroBuilder] directly from a [Basetro].
extension BasetroBuilderTools<T> on Basetro<T> {
  /// Creates a [MastroBuilder] widget that rebuilds when this state changes.
  ///
  /// [builder] is the function that constructs the widget tree, receiving this [Basetro]
  /// and the current [BuildContext]. Returns a [MastroBuilder] instance configured with this state.
  Widget build({
    required Widget Function(
      Basetro<T> state,
      BuildContext context,
    ) builder,
  }) {
    return MastroBuilder(state: this, builder: builder);
  }
}
