import 'dart:async';
import 'state.dart';

class MastroTriggerable {
  final _state = false.mastro;
  Timer? _debounceTimer;

  void trigger({Duration? debounce}) {
    _debounceTimer?.cancel();

    if (debounce != null) {
      _debounceTimer = Timer(debounce, () {
        _state.value = !_state.value;
      });
    } else {
      _state.value = !_state.value;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  Mastro get mastro => _state;
}
