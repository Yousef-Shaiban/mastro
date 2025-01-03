import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';
import 'package:mastro_example/features/notes/presentation/notes_view.dart';

import 'features/notes/logic/notes_box.dart';

// Initialize the app with persistent storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MastroInit.initialize();

  runApp(MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: MultiBoxProvider(
      providers: [
        BoxProvider(
          create: (context) => NotesBox(),
        )
      ],
      child: const NotesView(),
    ),
  ));
}
