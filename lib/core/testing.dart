import 'mastrobox.dart';
import 'events.dart';

class Testmastrobox<T extends MastroEvent> extends MastroBox<T> {
  final List<T> _eventHistory = [];

  List<T> get eventHistory => List.unmodifiable(_eventHistory);

  @override
  Future<void> addEvent(T event, {Callbacks? callbacks}) async {
    _eventHistory.add(event);
    await super.addEvent(event, callbacks: callbacks);
  }

  void clearHistory() {
    _eventHistory.clear();
  }
}
