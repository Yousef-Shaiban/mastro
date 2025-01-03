import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mastrobox.dart';

class BoxProvider<T extends MastroBox> extends Provider<T> {
  BoxProvider({
    required super.create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
  });

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

class ClassProvider<T> extends Provider<T> {
  ClassProvider({
    required super.create,
    super.key,
    super.child,
    super.builder,
    super.lazy = true,
  });

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

class MultiBoxProvider extends MultiProvider {
  MultiBoxProvider({
    super.key,
    required super.providers,
    required super.child,
  });
}
