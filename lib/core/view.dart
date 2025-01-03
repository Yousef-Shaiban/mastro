import 'package:flutter/material.dart';

import 'builders.dart';
import 'mastrobox.dart';
import 'providers.dart';
import 'scopes.dart';

/// Base class for creating views with lifecycle management and state handling.
abstract class MastroView<T extends MastroBox> extends StatefulWidget {
  final T? _box;

  /// Creates a MastroView with an optional box instance.
  const MastroView({super.key, T? box}) : _box = box;

  @override
  State<MastroView> createState() => _MastroViewState<T>();

  /// Builds the view's widget tree.
  Widget build(BuildContext context, T box);

  /// Forces a rebuild of the view.
  void rebuild(BuildContext context) {
    context.findAncestorStateOfType<_MastroViewState<T>>()?.rebuildPage();
  }

  /// Called when the view is first initialized.
  void initState(BuildContext context, T box) {}

  /// Called when the app is resumed from background.
  void onResume(BuildContext context, T box) {}

  /// Called when the app becomes inactive.
  void onInactive(BuildContext context, T box) {}

  /// Called when the app is paused.
  void onPaused(BuildContext context, T box) {}

  /// Called when the app is hidden.
  void onHide(BuildContext context, T box) {}

  /// Called when the app is detached.
  void onDetached(BuildContext context, T box) {}

  /// Called when the view is disposed.
  void dispose(BuildContext context, T box) {}
}

class _MastroViewState<T extends MastroBox> extends State<MastroView>
    with WidgetsBindingObserver {
  late final T box;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.onResume(context, box);
        break;
      case AppLifecycleState.inactive:
        widget.onInactive(context, box);
        break;
      case AppLifecycleState.paused:
        widget.onPaused(context, box);
        break;
      case AppLifecycleState.detached:
        widget.onDetached(context, box);
        break;
      case AppLifecycleState.hidden:
        widget.onHide(context, box);
        break;
    }
  }

  void rebuildPage() {
    setState(() {});
  }

  @override
  void initState() {
    if (widget._box != null) {
      box = widget._box! as T;
    } else {
      box = BoxProvider.of<T>(context);
    }
    box.init();
    widget.initState(context, box);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return StaticWidgetProvider(
      seed: widget.build(context, box),
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
    widget.dispose(context, box);
    box.dispose();
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
  /// The initial widget to be transformed.
  final Widget seed;

  /// Function that transforms the seed widget into the final widget.
  final Widget Function(Widget seed) builder;

  /// Creates a StaticWidgetProvider with a seed widget and builder function.
  const StaticWidgetProvider({
    super.key,
    required this.seed,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(seed);
}
