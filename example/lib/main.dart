import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';
import 'package:mastro_example/features/notes/logic/notes_box.dart';
import 'package:mastro_example/features/notes/presentation/notes_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Persistro.initialize();
  runApp(MultiBoxProvider(
    providers: [
      BoxProvider(
        create: (context) => NotesBox(),
      )
    ],
    child: const MaterialApp(
      home: NotesView(),
    ),
  ));
}
