import 'package:flutter/material.dart';

import 'builders.dart';
import 'mastrobox.dart';
import 'providers.dart';
import 'scopes.dart';

abstract class MastroView<T extends MastroBox> extends StatefulWidget {
  final T? _mastrobox;

  const MastroView({super.key, T? box}) : _mastrobox = box;
  @override
  State<MastroView> createState() => _MastroViewState<T>();

  Widget build(BuildContext context, T box);

  void rebuild(BuildContext context) {
    context.findAncestorStateOfType<_MastroViewState<T>>()?.rebuildPage();
  }

  void initState(BuildContext context, T box) {}

  void onResume(BuildContext context, T box) {}

  void onInactive(BuildContext context, T box) {}

  void onPaused(BuildContext context, T box) {}

  void onHide(BuildContext context, T box) {}

  void onDetached(BuildContext context, T box) {}

  void dispose(BuildContext context, T box) {}
}

class _MastroViewState<T extends MastroBox> extends State<MastroView>
    with WidgetsBindingObserver {
  late final T mastrobox;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.onResume(context, mastrobox);
        break;
      case AppLifecycleState.inactive:
        widget.onInactive(context, mastrobox);
        break;
      case AppLifecycleState.paused:
        widget.onPaused(context, mastrobox);
        break;
      case AppLifecycleState.detached:
        widget.onDetached(context, mastrobox);
        break;
      case AppLifecycleState.hidden:
        widget.onHide(context, mastrobox);
        break;
    }
  }

  void rebuildPage() {
    setState(() {});
  }

  @override
  void initState() {
    if (widget._mastrobox != null) {
      mastrobox = widget._mastrobox! as T;
    } else {
      mastrobox = BoxProvider.of<T>(context);
    }
    mastrobox.init();
    widget.initState(context, mastrobox);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return StaticWidgetProvider(
      seed: widget.build(context, mastrobox),
      builder: (seed) {
        final popScope = ClassProvider.ofNullable<OnPopScope>(context);
        return popScope != null
            ? MastroBuilder(
                state: popScope.isLoading,
                builder: (state, context) => PopScope(
                  canPop: !state.value,
                  onPopInvokedWithResult: (didPop, result) {
                    if (!didPop && state.value) {
                      popScope.onPopWaitMessage(context);
                    }
                  },
                  child: seed,
                ),
              )
            : seed;
      },
    );
  }

  @override
  void dispose() {
    widget.dispose(context, mastrobox);
    mastrobox.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// A widget that provides a static child widget and allows transformation through a builder function.
///
/// Use this when you need to wrap or modify a widget that's already constructed.
///
/// Example:
/// ```dart
/// StaticWidgetProvider(
///   seed: Text('Hello'),
///   builder: (child) => Container(child: child),
/// )
/// ```
class StaticWidgetProvider extends StatelessWidget {
  final Widget seed;
  final Widget Function(Widget seed) builder;

  const StaticWidgetProvider({
    super.key,
    required this.seed,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(seed);
}
