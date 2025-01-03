import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'mastrobox.dart';
import 'state.dart';

class TagBuilder extends StatefulWidget {
  final String tag;
  final MastroBox box;
  final Widget Function(BuildContext context) builder;

  const TagBuilder({
    super.key,
    required this.tag,
    required this.builder,
    required this.box,
  });

  @override
  State<TagBuilder> createState() => _TagBuilderState();
}

class _TagBuilderState extends State<TagBuilder> {
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

class MastroBuilder<T> extends StatefulWidget {
  final Basetro<T> mastro;
  final Widget Function(Basetro<T> mastro, BuildContext context) builder;
  final List<Basetro<dynamic>>? listeners;
  final bool Function(T previous, T current)? shouldRebuild;

  const MastroBuilder({
    Key? key,
    required this.mastro,
    required this.builder,
    this.listeners,
    this.shouldRebuild,
  }) : super(key: key);

  @override
  State<MastroBuilder<T>> createState() => _MastroBuilderState<T>();
}

class _MastroBuilderState<T> extends State<MastroBuilder<T>> {
  T? _previousValue;

  void _updateState() async {
    if (!context.mounted) return;

    final currentValue = widget.mastro.value;
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

  void _setupListeners() {
    if (widget.listeners == null) {
      widget.mastro.addListener(_updateState);
    } else {
      widget.mastro.addListener(_updateState);
      for (final element in widget.listeners!) {
        element.addListener(_updateState);
      }
    }
  }

  void _cleanupListeners() {
    if (widget.listeners == null) {
      widget.mastro.removeListener(_updateState);
    } else {
      widget.mastro.removeListener(_updateState);
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
    if (oldWidget.listeners != widget.listeners ||
        oldWidget.mastro != widget.mastro) {
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
    return widget.builder(widget.mastro, context);
  }
}

extension BasetroBuilderTools<T> on Basetro<T> {
  Widget build({
    required Widget Function(
      Basetro<T> state,
      BuildContext context,
    ) builder,
  }) {
    return MastroBuilder(mastro: this, builder: builder);
  }
}
