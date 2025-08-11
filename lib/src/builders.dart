import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'box.dart';
import 'core.dart';

/// A utility class for force widget rebuilds programmatically using a [Key].
class RebuildBoundary {
  /// Generates a new unique key. This is used internally to force a rebuild
  /// by changing the key of the widget subtree.
  static Key get _newKey => UniqueKey();

  /// The internal state management for this boundary, leveraging `Lightro`.
  ///
  /// Changing the `value` of this `Lightro` instance will notify its listeners,
  /// causing the `MastroBuilder` in the [build] method to rebuild its child.
  final _state = Lightro.of(_newKey);

  /// Forces the associated widget subtree to rebuild.
  ///
  /// When called, this method updates the internal [Key] stored in the `Lightro`
  /// instance. If no [key] is provided, a new [UniqueKey] is generated.
  /// Providing a specific [key] allows for more controlled scenarios, though
  /// typically a new key is desired to guarantee a rebuild.
  void trigger({Key? key}) => _state.value = key ?? _newKey;

  /// Builds a `MastroBuilder` widget that listens to the internal key state
  /// managed by `Lightro`.
  ///
  /// The provided [builder] function will be invoked whenever [trigger] is called,
  /// passing the current [BuildContext] and the updated [Key]. It is crucial
  /// that the root widget returned by your [builder] function uses this
  /// provided [key] for the rebuild to take effect.
  Widget build(Widget Function(BuildContext context, Key key) builder) => MastroBuilder(
        state: _state,
        builder: (state, context) => builder(context, state.value),
      );
}

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
  bool _framePending = false;
  int _deferToken = 0;

  void _updateState() {
    if (!mounted) return;
    if (widget.tag != widget.box.taggable.value) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final canSetNow = phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks || phase == SchedulerPhase.midFrameMicrotasks;

    if (canSetNow) {
      _deferToken++;
      setState(() {});
      return;
    }

    if (_framePending) return;
    _framePending = true;
    final myToken = ++_deferToken;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _framePending = false;
      if (!mounted || myToken != _deferToken) return;
      if (widget.tag == widget.box.taggable.value) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.box.taggable.addListener(_updateState);
  }

  @override
  void didUpdateWidget(TagBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box != widget.box) {
      oldWidget.box.taggable.removeListener(_updateState);
      widget.box.taggable.addListener(_updateState);
    }
  }

  @override
  void dispose() {
    widget.box.taggable.removeListener(_updateState); // remove before super
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
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
  late T _previousValue;

  bool _framePending = false;
  int _deferToken = 0;

  final Set<Basetro<dynamic>> _attached = {};

  bool _should(T prev, T next) {
    return widget.shouldRebuild?.call(prev, next) ?? true;
  }

  void _attach(Basetro<dynamic> s) {
    if (_attached.add(s)) s.addListener(_updateState);
  }

  void _detach(Basetro<dynamic> s) {
    if (_attached.remove(s)) s.removeListener(_updateState);
  }

  void _updateState() {
    if (!mounted) return;

    final next = widget.state.value;
    if (!_should(_previousValue, next)) return;

    final phase = SchedulerBinding.instance.schedulerPhase;

    final canSetNow = phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks || phase == SchedulerPhase.midFrameMicrotasks;

    if (canSetNow) {
      _deferToken++;
      setState(() {
        _previousValue = next;
      });
      return;
    }

    if (_framePending) return;
    _framePending = true;
    final myToken = ++_deferToken;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _framePending = false;
      if (!mounted || myToken != _deferToken) return;

      final latest = widget.state.value;
      if (_should(_previousValue, latest)) {
        setState(() {
          _previousValue = latest;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _previousValue = widget.state.value;
    _attach(widget.state);
    for (final s in (widget.listeners ?? const <Basetro<dynamic>>[])) {
      _attach(s);
    }
  }

  @override
  void didUpdateWidget(MastroBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSet = <Basetro<dynamic>>{
      oldWidget.state,
      ...?oldWidget.listeners,
    };
    final newSet = <Basetro<dynamic>>{
      widget.state,
      ...?widget.listeners,
    };

    for (final s in oldSet.difference(newSet)) {
      _detach(s);
    }
    for (final s in newSet.difference(oldSet)) {
      _attach(s);
    }

    if (oldWidget.state != widget.state) {
      _previousValue = widget.state.value;
    }
  }

  @override
  void dispose() {
    for (final s in _attached.toList()) {
      _detach(s);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.state, context);
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
