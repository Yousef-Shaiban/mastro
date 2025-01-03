import 'package:mastro/mastro.dart';
import 'package:mastro_example/shared/models/note.dart';

part 'notes_events.dart';

class NotesBox extends MastroBox<MastroEvent> {
  final notes = PersistroMastro.list<Note>(
    'notes',
    initial: [],
    fromJson: (json) => Note.fromJson(json),
  );

  // Persist user preferences
  final isDarkMode = PersistroLightro.boolean('isDarkMode', initial: false);
  final sortByPinned = false.lightro;
  final lastViewedNoteId = PersistroLightro.string('lastViewedNoteId');

  @override
  void init() {
    // When sortByPinned changes, notes will be notified
    notes.dependsOn(sortByPinned);

    // Add observers for debugging and analytics
    notes.debugLog();
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
