# Mastro

Mastro is a state management solution for Flutter that combines reactive programming with event handling and persistence. It provides a structured way to manage state, handle events, and persist data across app sessions.

# Table of Contents
- [Key Features](#key-features)
- [Installation](#installation)
- [1. Initialization](#1-initialization)
- [2. State Management](#2-state-management)
- [3. Persistent Storage](#3-persistent-storage)
- [4. MastroBox Pattern](#4-mastrobox-pattern)
- [5. BoxProviders](#5-boxproviders)
- [6. Event Handling](#6-event-handling)
- [7. Widget Building](#7-widget-building)
- [8. MastroView Pattern](#8-mastroview-pattern)
- [9. Scopes](#9-scopes)
- [Project Structure](#project-structure)
- [Examples](#examples)
- [Contributions](#contributions)
- [License](#license)

## Key Features

- 🎯 **Simple State Management** - Lightweight and Mastro state objects
- 🔄 **Reactive Updates** - Efficient widget rebuilding
- 💾 **Persistent Storage** - Built-in persistence capabilities
- 📦 **MastroBox Pattern** - Organized business logic and state
- 🎭 **Event Handling** - Structured event processing
- 🔍 **Debug Tools** - Built-in debugging capabilities
- 🏗️ **Builder Widgets** - Flexible widget building
- 🔒 **State Validation** - Input validation support
- 🔄 **Computed States** - Derived values with automatic updates
- 🎯 **Event Modes** - Parallel, Sequential, and Solo event processing
- 🔌 **Lifecycle Management** - Built-in lifecycle hooks
- 🎨 **UI Patterns** - Structured view and widget patterns

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  mastro: <latest_version>
```

Then, run `flutter pub get` to install the package.

### 1. Initialization

To use Mastro, you need to initialize it in your `main.dart` file. This setup ensures that all necessary components are ready before your app starts.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MastroInit.initialize(); // Initialize Mastro
  ...
  runApp(MaterialApp(home: MastroScope(child: YourHomeWidget())));
}
```

### 2. State Management

Mastro offers two primary ways to manage state: `Lightro` and `Mastro`. Both can handle any state, but `Mastro` provides additional features.

#### Lightro - Simple State

- **Purpose**: Manage states with a straightforward approach.
- **Usage**: Ideal for basic state management where you need to track a single value.
- **Example**:
  ```dart
  final counter = 0.lightro; // Create a simple state

  // Update the state
  counter.value++;

  // Reactive UI with MastroBuilder
  MastroBuilder(
    state: counter,
    builder: (state, context) => Text('Counter: ${state.value}'),
  );
  ```

#### Mastro - Advanced State

- **Purpose**: Manage states with additional features like dependencies, computed values, and validation.
- **Usage**: Suitable for scenarios where state changes depend on other states or require validation.
- **Example**:
  ```dart
  class User {
    String name;
    int age;

    User({required this.name, required this.age});
  }

  final user = User(name: 'Alice', age: 30).mastro; // Create a complex state

  // Modify the state without replacing the object
  user.modify((state) {
    state.value.name = 'Bob';
    state.value.age = 31;
  });

  // Reactive UI with MastroBuilder
  MastroBuilder(
    state: user,
    builder: (state, context) => Column(
      children: [
        Text('Name: ${state.value.name}'),
        Text('Age: ${state.value.age}'),
      ],
    ),
  );
  ```

#### Mastro Functions

- **dependsOn**: Establish dependencies between states. When the dependent state changes, the current state is notified.
  ```dart
  dependentState.dependsOn(anotherState);
  ```

- **compute**: Define computed values based on other states. Automatically updates when the source states change.
  ```dart
  final someState = 10.mastro;
  final computedState = someState.compute((value) => value * 5);
  ```

- **setValidator**: Set validation logic for a state. Ensures that the state value meets certain criteria.
  ```dart
  final validatedState = 2.mastro;
  validatedState.setValidator((value) => value > 0);

  validatedState.value = 1; // this will be accepted
  validatedState.value = -1; // this will be ignored
  ```

- **observe**: Observe changes in the state and execute a callback when the state changes.
  ```dart
  observedState.observe((value) {
    print('State changed to $value');
  });
  ```

#### Differences Between Lightro and Mastro

| Feature                  | Lightro  | Mastro |
|--------------------------|----------|--------|
| Modify method            | ✅       | ✅      |
| Dependencies             | ❌       | ✅      |
| Computed states          | ❌       | ✅      |
| Validation               | ❌       | ✅      |
| Observers                | ❌       | ✅      |


### 3. Persistent Storage

#### Persistro Class

- **Purpose**: Provides a base for persistent storage using `SharedPreferences`.
- **Usage**: Can be used directly for custom persistence logic.
- **Example**:
  ```dart
  // Direct usage example
  Future<void> saveCustomData(String key, String value) async {
    await Persistro.putString(key, value);
  }

  Future<String?> loadCustomData(String key) async {
    return await Persistro.getString(key);
  }
  ```

#### PersistroMastro and PersistroLightro

These classes extend the functionality of `Mastro` and `Lightro` by adding persistence capabilities, allowing state data to be saved and restored across app sessions.

- **PersistroLightro**:
  - **Purpose**: Manage simple, single-value states with persistence.
  - **Usage**: Ideal for persisting basic settings or preferences.
  - **Example**:
    ```dart
    final isDarkMode = PersistroLightro.boolean('isDarkMode', initial: false); // Persistent boolean state

    // Toggle dark mode
    isDarkMode.toggle();

    // Reactive UI with MastroBuilder
    MastroBuilder(
      state: isDarkMode,
      builder: (state, context) => Text('Dark Mode: ${state.value ? "On" : "Off"}'),
    );
    ```

- **PersistroMastro**:
  - **Purpose**: Manage complex states with persistence, including lists and maps.
  - **Usage**: Suitable for persisting collections or objects with multiple properties.
  - **Example**:
    ```dart
    final notes = PersistroMastro.list<Note>(
      'notes',
      initial: [],
      fromJson: (json) => Note.fromJson(json),
    );

    // Add a new note
    notes.modify((state) {
      state.value.add(Note(
        id: '1',
        title: 'New Note',
        content: 'This is a new note.',
        createdAt: DateTime.now(),
      ));
    });

    // Reactive UI with MastroBuilder
    MastroBuilder(
      state: notes,
      builder: (state, context) => ListView.builder(
        itemCount: state.value.length,
        itemBuilder: (context, index) {
          final note = state.value[index];
          return ListTile(title: Text(note.title));
        },
      ),
    );
    ```

### 4. MastroBox Pattern

MastroBox is the core container for your application's state and logic.

- **Purpose**: Organize state and business logic in a structured way.
- **Usage**: Extend `MastroBox` to create a container for your app's state and logic.
- **Example**:
  ```dart
  class NotesBox extends MastroBox<NotesEvent> {
    final notes = PersistroMastro.list<Note>(
      'notes',
      initial: [],
      fromJson: (json) => Note.fromJson(json),
    );

    @override
    void init() {
      notes.debugLog();
    }
  }
  ```

### 5. BoxProviders

`BoxProvider` and `MultiBoxProvider` are used to manage the lifecycle of `MastroBox` instances and provide them to the widget tree.

#### BoxProvider

- **Purpose**: Provides a single `MastroBox` instance to the widget tree.
- **Usage**: Use `BoxProvider` when you need to provide a single box to a subtree.
- **Example**:
  ```dart
  BoxProvider<NotesBox>(
    create: (_) => NotesBox(),
    child: NotesView(),
  );
  ```

#### MultiBoxProvider

- **Purpose**: Provides multiple `MastroBox` instances to the widget tree.
- **Usage**: Use `MultiBoxProvider` when you need to provide multiple boxes to a subtree.
- **Example**:
  ```dart
  MultiBoxProvider(
    providers: [
      BoxProvider(create: (_) => NotesBox()),
      BoxProvider(create: (_) => AnotherBox()),
    ],
    child: MyApp(),
  );
  ```

### 6. Event Handling

Events in Mastro provide a structured way to handle actions and state changes.

- **Purpose**: Define and handle events that modify the state.
- **Usage**: Create event classes that extend `MastroEvent` and implement the `implement` method.
- **Example**:
  ```dart
  sealed class NotesEvent extends MastroEvent<NotesBox> {
    const NotesEvent();
    factory NotesEvent.add(String title, String content) = _AddNoteEvent;
  }

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
      
      // Notify listeners that note was added successfully
      callbacks.invoke('onNoteAdded', data: {'noteId': note.id});
    }
  }

  // Using callbacks when adding event
  await box.addEvent(
    NotesEvent.add('Title', 'Content'),
    callbacks: Callbacks({
      'onNoteAdded': ({data}) {
        print('Note added with ID: ${data?['noteId']}');
      },
    }),
  );
  ```

#### Event Modes
```dart
class ComplexEvent extends MastroEvent<AppBox> {
  @override
  EventRunningMode get mode => EventRunningMode.sequential;
  // Available modes:
  // - parallel (default): Multiple instances can run simultaneously
  // - sequential: Events of same type are queued
  // - solo: Only one instance can run at a time
}
```

### 7. Widget Building

Mastro provides builder widgets to create reactive UIs.

#### MastroBuilder

- **Purpose**: Build widgets that automatically update when the state changes.
- **Usage**: Use `MastroBuilder` to wrap widgets that depend on a state.
- **Parameters**:
  - `state`: The state object that the widget depends on.
  - `builder`: A function that builds the widget based on the current state.
  - `listeners` (optional): A list of additional state objects to listen to. If any of these states change, the widget will rebuild.
  - `shouldRebuild` (optional): A function that determines whether the widget should rebuild when the state changes. It takes the previous and current state values as arguments and returns a boolean. If not provided, the widget will rebuild on every state change.
- **Example**:
  ```dart
  MastroBuilder(
    state: counter,
    builder: (state, context) => Text('Counter: ${state.value}'),
  );
  ```

#### TagBuilder

- **Purpose**: Rebuild parts of the UI by calling `box.tag` to trigger updates for specific tags.
- **Usage**: Use `TagBuilder` to create widgets that needs to be rebuild when a specific tag is triggered.
- **Example**:
  ```dart
  TagBuilder(
    tag: 'important',
    box: box,
    builder: (context) => Text('This is an important update!'),
  );

  // Trigger a rebuild for the 'important' tag
  box.tag('important');
  ```

### 8. MastroView Pattern

MastroView provides a structured way to create screens with lifecycle management.

- **Purpose**: Manage the lifecycle of a screen and its associated state.
- **Usage**: Extend `MastroView` to create a screen with lifecycle hooks.

#### Using Local Box

Create or pass a `MastroBox` instance directly to a `MastroView` super constructor.

- **Example**:
  ```dart
  class LocalNotesView extends MastroView<NotesBox> {
    LocalNotesView({super.key}) : super(box: NotesBox());

    @override
    Widget build(BuildContext context, NotesBox box) {
      return Scaffold(
        appBar: AppBar(title: const Text('Local Notes')),
        body: MastroBuilder(
          state: box.notes,
          builder: (notes, context) => ListView.builder(
            itemCount: notes.value.length,
            itemBuilder: (context, index) {
              final note = notes.value[index];
              return ListTile(title: Text(note.title));
            },
          ),
        ),
      );
    }
  }
  ```

#### Using BoxProvider

Use `MultiBoxProvider` or `BoxProvider` to define `MastroBox` instances in the widget tree prior to the creation of the MastroView.

- **Example**:
  ```dart
  class GlobalNotesView extends MastroView<NotesBox> {
    const GlobalNotesView({super.key});

    @override
    Widget build(BuildContext context, NotesBox box) {
      return Scaffold(
        appBar: AppBar(title: const Text('Global Notes')),
        body: MastroBuilder(
          state: box.notes,
          builder: (notes, context) => ListView.builder(
            itemCount: notes.value.length,
            itemBuilder: (context, index) {
              final note = notes.value[index];
              return ListTile(title: Text(note.title));
            },
          ),
        ),
      );
    }
  }
  ```

### 9. Scopes

Mastro provides a way to manage app-wide behaviors using scopes, particularly useful when handling events that block user interactions.

#### OnPopScope

- **Purpose**: Manage user interactions during blocking events within `MastroScope`.
- **Usage**: Use `OnPopScope` to define behavior when an event blocks user interactions.
- **Example**:
  ```dart
  MaterialApp(
    home: MastroScope(
      onPopScope: OnPopScope(
        onPopWaitMessage: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait...')),
          );
        },
      ),
      child: YourHomeWidget(),
    ),
  );
  ```

#### addEventBlockPop

- **Purpose**: Execute events that block user interactions until completion.
- **Usage**: Use `addEventBlockPop` to run events that should prevent user actions until they finish.
- **Example**:
  ```dart
  await box.addEventBlockPop(
    context,
    NotesEvent.add('New Note', 'This is a new note'),
  );
  ```

## Global vs. Local Box Usage

- **Global Usage**: Use `MultiBoxProvider` to define `MastroBox` instances that can be accessed from anywhere in the app. This is useful for app-wide settings or data that needs to be shared across multiple screens.
  
- **Local Usage**: Pass a `MastroBox` instance directly to a `MastroView` for data that is only relevant to a particular screen or widget.

## Project Structure

Mastro follows a feature-based architecture pattern that promotes organization and separation of concerns. Here's the recommended project structure:

```
lib/
├── core/                     # Core functionality and configurations
├── shared/                   # Shared resources (models, utilities, etc.)
│   └── models/
└── features/                 # Feature modules
    └── notes/               # Example feature
        ├── logic/
        │   ├── notes_box.dart
        │   └── notes_events.dart
        └── presentation/
            ├── components/   # Feature-specific widgets
            └── notes_view.dart
```

### Feature Structure Explanation

Each feature follows a consistent structure:

1. **Logic Layer** (`logic/`)
   - `*_box.dart`: Contains the MastroBox implementation for the feature
   - `*_events.dart`: Defines feature-specific events

2. **Presentation Layer** (`presentation/`)
   - `*_view.dart`: Main view implementation using MastroView
   - `components/`: Feature-specific widgets and UI components

### Example Feature Implementation

```dart
// features/notes/logic/notes_box.dart
class NotesBox extends MastroBox<NotesEvent> {
  final notes = PersistroMastro.list<Note>('notes', initial: []);
}

// features/notes/logic/notes_events.dart
sealed class NotesEvent extends MastroEvent<NotesBox> {
  const NotesEvent();
  factory NotesEvent.add(Note note) = _AddNoteEvent;
}

// features/notes/presentation/notes_view.dart
class NotesView extends MastroView<NotesBox> {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context, NotesBox box) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: MastroBuilder(
        state: box.notes,
        builder: (notes, context) => NotesListView(notes: notes.value),
      ),
    );
  }
}
```

This structure promotes:
- Clear separation of concerns
- Feature isolation
- Easy navigation and maintenance
- Scalable architecture
- Reusable components

## Examples

Check the `example` folder for more detailed examples of how to use Mastro in your Flutter app.

## Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on [GitHub](https://github.com/Yousef-Shaiban/pressable).

## License

This project is licensed under the MIT License - see the LICENSE file for details.