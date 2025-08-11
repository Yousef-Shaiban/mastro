import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';

import '../logic/notes_box.dart';

class NotesView extends MastroView<NotesBox> {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context, NotesBox box) {
    return MastroBuilder(
      state: box.isDarkMode,
      builder: (darkMode, context) => Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: darkMode.value ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Notes'),
            actions: [
              IconButton(
                icon: Icon(darkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => darkMode.toggle(),
              ),
              MastroBuilder(
                state: box.sortByPinned,
                builder: (sort, context) => IconButton(
                  icon: Icon(sort.value ? Icons.push_pin : Icons.push_pin_outlined),
                  onPressed: () => sort.toggle(),
                ),
              ),
            ],
          ),
          body: MastroBuilder(
            state: box.notes,
            builder: (notes, context) => ListView.builder(
              itemCount: box.sortedNotes.length,
              itemBuilder: (context, index) {
                final note = box.sortedNotes[index];
                return Dismissible(
                  key: Key(note.id),
                  onDismissed: (_) => box.execute(NotesEvent.delete(note.id)),
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      ),
                      onPressed: () => box.execute(NotesEvent.toggle(note.id)),
                    ),
                    trailing: Text(
                      '${note.createdAt.day}/${note.createdAt.month}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => box.lastViewedNoteId.value = note.id,
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddNoteDialog(context, box),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, NotesBox box) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                box.execute(NotesEvent.add(titleController.text, contentController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
