import 'package:flutter/material.dart';

import 'providers.dart';
import 'state.dart';

class OnPopScope {
  final Function(BuildContext context) onPopWaitMessage;
  final isLoading = false.mastro;

  OnPopScope({required this.onPopWaitMessage});
}

class MastroScope extends StatelessWidget {
  final OnPopScope? onPopScope;
  final Widget child;
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
