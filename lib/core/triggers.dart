import 'package:flutter/material.dart';
import 'package:mastro/core/builders.dart';

import 'state.dart';

class MastroTriggerable {
  final _state = false.mastro;

  void trigger() => _state.toggle();

  Widget build(Widget Function() builder) =>
      MastroBuilder(state: _state, builder: (_, __) => builder());
}
