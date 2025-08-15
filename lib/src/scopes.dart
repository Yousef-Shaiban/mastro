import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';

/// Manages pop navigation behavior and loading state within the Mastro framework.
///
/// Used with [MastroScope] to handle navigation blocking and loading indicators.
class OnPopScope {
  /// Callback to show a message when pop navigation is waiting due to loading.
  ///
  /// [context] is the current build context, used to display the message.
  final Function(BuildContext context) onPopWaitMessage;

  /// The current loading state.
  ///
  /// A [Lightro<bool>] instance that tracks whether an operation is in progress.
  final isLoading = Lightro.of(false, showLogs: false);

  /// Creates an [OnPopScope] instance.
  ///
  /// [onPopWaitMessage] defines the behavior when pop is blocked due to loading.
  OnPopScope({required this.onPopWaitMessage});
}

/// A widget that provides scope for Mastro framework functionality.
///
/// Wraps the widget tree with optional [OnPopScope] support for managing navigation and loading.
class MastroScope extends StatelessWidget {
  /// Optional handler for pop navigation and loading state.
  final OnPopScope? onPopScope;

  /// The child widget to scope.
  final Widget child;

  /// Creates a [MastroScope] widget.
  ///
  /// [onPopScope] provides navigation control if present. [child] is the widget tree to wrap.
  /// [key] is optional for widget identity.
  const MastroScope({super.key, this.onPopScope, required this.child});

  @override
  Widget build(BuildContext context) {
    return onPopScope != null
        ? ClassProvider(
            create: (context) => onPopScope,
            child: child,
          )
        : child;
  }
}
