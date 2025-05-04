import 'package:flutter/material.dart';

import 'builders.dart';
import 'mastrobox.dart';
import 'providers.dart';
import 'scopes.dart';

/// Base class for creating views with lifecycle management and state handling in the Mastro framework.
///
/// Extends [StatefulWidget] to integrate with a [MastroBox] for state and event management.
///
/// Type parameter [T] represents the [MastroBox] subclass managing this view’s state.
abstract class MastroView<T extends MastroBox> extends StatefulWidget {
  /// Optional [MastroBox] instance provided directly to the view.
  final T? _box;

  /// Creates a [MastroView] with an optional box instance.
  ///
  /// [box] is an optional [MastroBox] instance; if null, it’s retrieved via [BoxProvider].
  /// [key] is optional for widget identity.
  const MastroView({super.key, T? box}) : _box = box;

  @override
  State<MastroView> createState() => _MastroViewState<T>();

  /// Builds the view’s widget tree.
  ///
  /// [context] is the current build context. [box] is the [MastroBox] managing this view’s state.
  /// Returns the constructed widget tree.
  Widget build(BuildContext context, T box);

  /// Forces a rebuild of the view.
  ///
  /// [context] is the current build context. Triggers a state update to rebuild the widget tree.
  void rebuild(BuildContext context) {
    context.findAncestorStateOfType<_MastroViewState<T>>()?.rebuildPage();
  }

  /// Called when the view is first initialized.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void initState(BuildContext context, T box) {}

  /// Called when the app is resumed from the background.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void onResume(BuildContext context, T box) {}

  /// Called when the app becomes inactive.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void onInactive(BuildContext context, T box) {}

  /// Called when the app is paused.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void onPaused(BuildContext context, T box) {}

  /// Called when the app is hidden.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void onHide(BuildContext context, T box) {}

  /// Called when the app is detached.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void onDetached(BuildContext context, T box) {}

  /// Called when the view is disposed.
  ///
  /// [context] is the current build context. [box] is the associated [MastroBox].
  void dispose(BuildContext context, T box) {}
}

/// The state class for [MastroView].
class _MastroViewState<T extends MastroBox> extends State<MastroView> with WidgetsBindingObserver {
  /// The [MastroBox] instance managing this view’s state.
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

  /// Triggers a rebuild of the view’s widget tree.
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
/// Use this to wrap or modify an existing widget without rebuilding it unnecessarily.
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

  /// Function that transforms the [seed] widget into the final widget.
  final Widget Function(Widget seed) builder;

  /// Creates a [StaticWidgetProvider] with a seed widget and builder function.
  ///
  /// [seed] is the base widget. [builder] defines how to transform it. [key] is optional
  /// for widget identity.
  const StaticWidgetProvider({
    super.key,
    required this.seed,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(seed);
}
