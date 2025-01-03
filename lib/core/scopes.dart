import 'package:flutter/material.dart';

import 'providers.dart';
import 'state.dart';

/// Manages pop navigation behavior and loading state.
class OnPopScope {
  /// Callback to show a message when pop is waiting.
  final Function(BuildContext context) onPopWaitMessage;

  /// Current loading state.
  final isLoading = false.mastro;

  /// Creates an OnPopScope instance.
  OnPopScope({required this.onPopWaitMessage});
}

/// Widget that provides scope for Mastro functionality.
class MastroScope extends StatelessWidget {
  /// Optional pop scope handler.
  final OnPopScope? onPopScope;

  /// Child widget.
  final Widget child;

  /// Creates a MastroScope widget.
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
