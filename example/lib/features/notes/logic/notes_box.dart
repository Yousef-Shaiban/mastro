import 'package:mastro/mastro.dart';
import 'package:mastro_example/shared/models/note.dart';

part 'notes_events.dart';

class NotesBox extends MastroBox<MastroEvent> {
  final notes = PersistroMastro.list<Note>(
    'notes',
    initial: [],
    fromJson: (json) => Note.fromJson(json),
  );

  final isDarkMode = PersistroLightro.boolean('isDarkMode', initial: false);
  final sortByPinned = false.lightro;
  final lastViewedNoteId = PersistroLightro.string('lastViewedNoteId');

  @override
  void init() {
    notes.dependsOn(sortByPinned);
    super.init();
  }

  // Get sorted notes
  List<Note> get sortedNotes {
    if (!sortByPinned.value) return notes.value;
    return notes.value.toList()
      ..sort((a, b) {
        if (a.isPinned == b.isPinned) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return b.isPinned ? 1 : -1;
      });
  }
}
