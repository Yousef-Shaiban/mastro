part of 'notes_box.dart';

sealed class NotesEvent extends MastroEvent<NotesBox> {
  const NotesEvent();
  factory NotesEvent.add(String title, String content) = _AddNoteEvent;
  factory NotesEvent.toggle(String noteId) = _TogglePinEvent;
  factory NotesEvent.delete(String noteId) = _DeleteNoteEvent;
}

// Events
class _AddNoteEvent extends NotesEvent {
  final String title;
  final String content;

  _AddNoteEvent(this.title, this.content);

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    box.notes.modify((notes) => notes.value.add(note));
  }
}

class _TogglePinEvent extends NotesEvent {
  final String noteId;

  _TogglePinEvent(this.noteId);

  @override
  EventRunningMode get mode => EventRunningMode.sequential;

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    box.notes.value = box.notes.value.map((note) {
      if (note.id == noteId) {
        return Note(
          id: note.id,
          title: note.title,
          content: note.content,
          createdAt: note.createdAt,
          isPinned: !note.isPinned,
        );
      }
      return note;
    }).toList();
  }
}

class _DeleteNoteEvent extends NotesEvent {
  final String noteId;

  _DeleteNoteEvent(this.noteId);

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    box.notes.modify(
      (notes) => notes.value.removeWhere((note) => note.id == noteId),
    );
  }
}
