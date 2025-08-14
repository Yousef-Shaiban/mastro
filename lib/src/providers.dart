import 'package:flutter/material.dart';
import 'package:mastro/src/internal/extra.dart';
import 'package:provider/provider.dart';

import 'box.dart';

/// A specialized [Provider] for exposing a [MastroBox] to the widget tree.
///
/// Automatically manages lifecycle hooks like cleanups and supports advanced
/// options like view-aware auto-cleanup.
///
/// Type parameter [T] must extend [MastroBox].
class BoxProvider<T extends MastroBox> extends Provider<T> {
  /// Creates a [BoxProvider] to expose a [MastroBox] to the widget tree.
  ///
  /// - [create]: Function that creates the [MastroBox] instance.
  /// - [autoCleanupWhenUnmountedFromWidgetTree]: If `true` (default), cleans up the box
  ///   when the provider is removed from the widget tree.
  /// - [autoCleanupWhenAllViewsDetached]: Instructs the box to cleanup itself when all views detach.
  BoxProvider({
    required Create<T> create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
    bool autoCleanupWhenUnmountedFromWidgetTree = true,
    bool autoCleanupWhenAllViewsDetached = false,
  }) : super(
          create: (context) {
            final box = create(context);
            box.autoCleanupWhenAllViewsDetached = autoCleanupWhenAllViewsDetached;
            return box;
          },
          dispose: autoCleanupWhenUnmountedFromWidgetTree
              ? (context, value) {
                  mastroLog(
                      "MastroBox($T) was automatically cleaned up when its BoxProvider was removed from the widget tree.\n"
                      "To prevent this, set `autoCleanupWhenUnmountedFromWidgetTree: false`.");
                  value.cleanup();
                }
              : null,
        );

  /// Retrieves the nearest [MastroBox] of type [T] from the widget tree.
  ///
  /// Throws a helpful [FlutterError] if the box is not found.
  ///
  /// - [context]: The context to search from.
  static T of<T extends MastroBox>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError.fromParts([
        ErrorSummary('BoxProvider<$T> not found in the widget tree.'),
        ErrorDescription(
            'BoxProvider.of<$T>() was called with a context that does not include a BoxProvider<$T>.'),
        ErrorHint('Ensure you have wrapped your widget tree with:\n\n'
            'BoxProvider<$T>(\n'
            '  create: (_) => YourBox(),\n'
            '  child: YourView(),\n'
            ')'),
        ErrorHint(
            '\nOr pass the box explicitly to MastroView via the `box:` constructor parameter.'),
        ErrorDescription('\nContext used: $context'),
      ]);
    }
  }
}

/// A generic [Provider] wrapper for exposing any class type.
///
/// Useful for dependency injection of services, controllers, etc.
class ClassProvider<T> extends Provider<T> {
  /// Creates a [ClassProvider] for exposing a non-Mastro class.
  ///
  /// - [create]: Function that creates the instance.
  /// - [onDispose]: Optional cleanup function.
  ClassProvider({
    required super.create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
    Dispose<T>? onDispose,
  }) : super(dispose: onDispose);

  /// Retrieves the nearest instance of type [T] from the widget tree.
  ///
  /// Throws a [FlutterError] if not found.
  static T of<T>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError.fromParts([
        ErrorSummary('ClassProvider<$T> not found in the widget tree.'),
        ErrorDescription(
            'ClassProvider.of<$T>() was called with a context that does not include a ClassProvider<$T>.'),
        ErrorHint('Ensure you have wrapped your widget tree with:\n\n'
            'ClassProvider<$T>(\n'
            '  create: (_) => YourClass(),\n'
            '  child: YourView(),\n'
            ')'),
        ErrorDescription('Context used: $context'),
      ]);
    }
  }

  /// Retrieves the nearest instance of type [T], or returns `null` if not found.
  static T? ofNullable<T>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// A [MultiProvider] wrapper that makes it easier to group multiple
/// [BoxProvider] or [ClassProvider] widgets together.
class MultiBoxProvider extends MultiProvider {
  /// Creates a widget that exposes multiple providers to the subtree.
  MultiBoxProvider({
    super.key,
    required super.providers,
    required super.child,
  });
}
