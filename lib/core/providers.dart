import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mastrobox.dart';

/// A provider for [MastroBox] instances in the widget tree.
///
/// Extends [Provider] to manage and provide access to a [MastroBox] instance.
///
/// Type parameter [T] represents the specific [MastroBox] subclass being provided.
class BoxProvider<T extends MastroBox> extends Provider<T> {
  /// Creates a provider for a [MastroBox].
  ///
  /// [create] is a function that constructs the [MastroBox] instance. [key], [child],
  /// [builder], and [lazy] are inherited from [Provider] for widget configuration.
  BoxProvider({
    required super.create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
  }) : super(dispose: (context, value) => value.dispose());

  /// Retrieves the [MastroBox] of type [T] from the widget tree.
  ///
  /// [context] is the build context to search from. [listen] determines if the widget
  /// rebuilds on changes (defaults to false). Throws a [FlutterError] if no provider is found.
  static T of<T extends MastroBox>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError(
        '''
        BoxProvider.of() called with a context that does not contain a $T.
        No ancestor could be found starting from the context that was passed to BoxProvider.of<$T>().

        This can happen if the context you used comes from a widget above the BoxProvider.

        The context used was: $context
        ''',
      );
    }
  }
}

/// A provider for arbitrary class instances in the widget tree.
///
/// Extends [Provider] to manage and provide access to any class instance.
///
/// Type parameter [T] represents the type of the instance being provided.
class ClassProvider<T> extends Provider<T> {
  /// Creates a provider for a class instance.
  ///
  /// [create] is a function that constructs the instance. [key], [child], [builder],
  /// and [lazy] are inherited from [Provider] for widget configuration.
  ClassProvider({
    required super.create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
  });

  /// Retrieves the instance of type [T] from the widget tree.
  ///
  /// [context] is the build context to search from. [listen] determines if the widget
  /// rebuilds on changes (defaults to false). Throws a [FlutterError] if no provider is found.
  static T of<T>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError(
        '''
        ClassProvider.of() called with a context that does not contain a $T.
        No ancestor could be found starting from the context that was passed to ClassProvider.of<$T>().

        This can happen if the context you used comes from a widget above the ClassProvider.

        The context used was: $context
        ''',
      );
    }
  }

  /// Retrieves the instance of type [T] from the widget tree, or null if not found.
  ///
  /// [context] is the build context to search from. [listen] determines if the widget
  /// rebuilds on changes (defaults to false). Returns null instead of throwing if no provider is found.
  static T? ofNullable<T>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (_) {
      return null;
    }
  }
}

/// A provider that combines multiple [MastroBox] providers into a single widget.
///
/// Extends [MultiProvider] to allow nesting multiple [BoxProvider] instances.
class MultiBoxProvider extends MultiProvider {
  /// Creates a provider that merges multiple [MastroBox] providers.
  ///
  /// [providers] is a list of providers to combine. [child] is the widget tree to provide to.
  /// [key] is optional for widget identity.
  MultiBoxProvider({
    super.key,
    required super.providers,
    required super.child,
  });
}
