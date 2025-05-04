import 'package:flutter/material.dart';

import 'builders.dart';
import 'state.dart';

/// A utility class for triggering widget rebuilds programmatically.
///
/// Uses a [Lightro<bool>] to toggle state and rebuild associated widgets.
class MastroTriggerable {
  /// Internal state for triggering rebuilds.
  final _state = false.lightro;

  /// Triggers a rebuild of the associated widget.
  ///
  /// Toggles the internal state, causing any [MastroBuilder] monitoring it to rebuild.
  void trigger() => _state.toggle();

  /// Builds a widget that rebuilds when triggered.
  ///
  /// [builder] is a function that constructs the widget tree. Returns a [MastroBuilder]
  /// that rebuilds whenever [trigger] is called.
  Widget build(Widget Function() builder) => MastroBuilder(state: _state, builder: (_, __) => builder());
}
