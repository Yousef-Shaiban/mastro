import 'package:flutter/material.dart';
import 'package:mastro/core/builders.dart';

import 'state.dart';

/// A widget that can be triggered to rebuild.
class MastroTriggerable {
  final _state = false.lightro;

  /// Triggers a rebuild of the widget.
  void trigger() => _state.toggle();

  /// Builds a widget that rebuilds when triggered.
  Widget build(Widget Function() builder) =>
      MastroBuilder(state: _state, builder: (_, __) => builder());
}
