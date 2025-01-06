<div align="center">

# <img src="https://raw.githubusercontent.com/yourusername/mastro/main/assets/logo.gif" width="40"> Mastro

<div style="font-family: 'Montserrat', sans-serif;">
  
A robust state management solution for Flutter that seamlessly integrates reactive programming with event handling and persistence capabilities.

[![Pub Version](https://img.shields.io/pub/v/mastro?color=blue&style=for-the-badge)](https://pub.dev/packages/mastro)
[![License](https://img.shields.io/github/license/yourusername/mastro?style=for-the-badge)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/yourusername/mastro?style=for-the-badge)](https://github.com/yourusername/mastro/stargazers)

<p align="center">
  <img src="https://raw.githubusercontent.com/yourusername/mastro/main/assets/demo.gif" alt="Mastro Demo" width="600">
</p>

</div>

## ✨ Key Features

<div style="font-family: 'Roboto', sans-serif;">

| Feature | Description |
|---------|-------------|
| 🎯 **Streamlined State Management** | Efficient and intuitive state objects |
| 🔄 **Reactive Architecture** | Optimized widget rebuilding with fine-grained control |
| 💾 **Persistent Storage** | Built-in data persistence with SharedPreferences integration |
| 📦 **MastroBox Pattern** | Structured business logic and state management |
| 🎭 **Event System** | Comprehensive event processing with multiple execution modes |
| 🔍 **Development Tools** | Integrated debugging and logging capabilities |
| 🏗️ **Widget Framework** | Flexible and performant reactive UI components |
| 🔒 **Validation System** | Robust state validation mechanisms |
| 🔄 **Computed Properties** | Automatic derivation and updates of dependent values |
| 🎯 **Event Processing Modes** | Configurable event execution (Parallel, Sequential, Solo) |
| 🔌 **Lifecycle Management** | Comprehensive lifecycle hooks and state management |
| 🎨 **UI Architecture** | Structured patterns for view and widget organization |

</div>

# Table of Contents
- [1. Key Features](#1-key-features)
- [2. Installation](#2-installation)
- [3. Initialization](#3-initialization)
- [4. State Management](#4-state-management)
- [5. Persistent Storage](#5-persistent-storage)
- [6. MastroBox Pattern](#6-mastrobox-pattern)
- [7. BoxProviders](#7-boxproviders)
- [8. Event Handling](#8-event-handling)
- [9. Widget Building](#9-widget-building)
- [10. MastroView Pattern](#10-mastroview-pattern)
- [11. MastroTriggerable](#11-mastrotriggerable)
- [12. Scopes](#12-scopes)
- [13. Project Structure](#13-project-structure)
- [14. Examples](#14-examples)
- [15. Contributions](#15-contributions)
- [16. License](#16-license)

## 1. Key Features

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

## 2. Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  mastro: <latest_version>
```

Then, run `flutter pub get` to install the package.

## 3. Initialization

To use Mastro, you need to initialize it in your `main.dart` file. This setup ensures that all necessary components are ready before your app starts.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MastroInit.initialize(); // Initialize Mastro
  ...
  runApp(MaterialApp(home: MastroScope(child: YourHomeWidget())));
}
```

## 4. State Management

Mastro offers two primary ways to manage state: `Lightro` and `Mastro`. Both can handle any state, but `Mastro` provides additional features.

#### Lightro - Recommended for most cases

- **Purpose**: Manage states with a straightforward approach.
- **Usage**: Ideal for basic state management.
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

#### Mastro - With advanced features

- **Purpose**: Manage states with additional features like dependencies, computed states, validation, and observers.
- **Usage**: Suitable for scenarios where state changes depend on other states or require validation.
- **Example**:
  ```dart
  class User {
    String name;
    int age;

    User({required this.name, required this.age});
  }

  final user = User(name: 'Alice', age: 30).mastro; // Create a mastro state
  user.setValidator((value) => value.age > 20);

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

- **dependsOn**: Establish dependencies between states. When any dependency state changes, the dependent state will be notified.
  ```dart
  dependentState.dependsOn(anotherState); // dependentState gets notified when anotherState changes
  ```

- **compute**: Define computed values based on other states. Automatically updates when the source states change.
  ```dart
  final someState = 10.mastro;
  final computedState = someState.compute((value) => value * 5); // computedState is automatically updated when someState changes 
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
  observedState.observe('observedState', (value) {
    print('State changed to $value');
  });
  ```

#### Differences Between Lightro and Mastro

| Feature                  | Lightro  | Mastro |
|--------------------------|----------|--------|
| Modify method            | ✅       | ✅      |
| debugLog method          | ✅       | ✅      |
| Dependencies             | ❌       | ✅      |
| Computed states          | ❌       | ✅      |
| Validation               | ❌       | ✅      |
| Observers                | ❌       | ✅      |

We recommend using `Lightro` for most cases since it uses less memory, and `Mastro` for more complex scenarios.

## 5. Persistent Storage

#### Persistro Class

- **Purpose**: Provides a base for persistent storage using `SharedPreferences`.
- **Usage**: Can be used directly for storing key value pairs.
- **Example**:
  ```dart
  // Direct usage example
  Future<void> saveData(String key, String value) async {
    await Persistro.putString(key, value);
  }

  Future<String?> loadData(String key) async {
    return await Persistro.getString(key);
  }
  ```

#### PersistroMastro and PersistroLightro

These classes extend the functionality of `Mastro` and `Lightro` by adding persistence capabilities, allowing state data to be saved and restored across app sessions.

#### PersistroState Functions
- **persist**: persists the current value.
- **restore**: restores the persisted value.
- **clear**: clears the persisted value.
- **disposePersistence**: cleans up persistence resources.
- **dispose**: cleans up persistence resources.

- **PersistroLightro**:
  - **Purpose**: Manage states with persistence.
  - **Usage**: Ideal for persisting preferences.
  - **Example**:
    ```dart
    final notes = PersistroLightro.list<Note>(
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

- **PersistroMastro**:
  - **Purpose**: Manage states with persistence, with advanced features.
  - **Usage**: Suitable for persisting preferences with advanced features.
  - **Example**:
    ```dart
    final isDarkMode = PersistroMastro.boolean('isDarkMode', initial: false); // Persistent boolean state

    // Toggle dark mode
    isDarkMode.toggle();
    isDarkMode.dependsOn(anotherState);

    // Reactive UI with MastroBuilder
    MastroBuilder(
      state: isDarkMode,
      builder: (state, context) => Text('Dark Mode: ${state.value ? "On" : "Off"}'),
    );
    ```

## 6. MastroBox Pattern

MastroBox is the core container for your application's and view's state and logic.

- **Purpose**: Organize state and business logic in a structured way.
- **Usage**: Extend `MastroBox` to create a container for your view's state and logic.
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

#### MastroBox functions

- **init**: called when the linked view is initialized
```dart
  @override
  void init() {
    super.init();
  }
```

- **dispose**: called when the linked view is disposed
```dart
  @override
  void dispose() {
    super.dispose();
  }
```

- **tag**: notifies TagBuilder using specific tag
```dart
  box.tag(tag: 'important');
```

- **registerCallback**: registers a callback function with the given key.
```dart
  box.registerCallback(key: 'doSomething', callback: (data) {
    print('Callback triggered with data: $data');
  });
```

- **unregisterCallback**: unregisters a callback function with the given key.
```dart
  box.unregisterCallback(key: 'doSomething');
```

- **trigger**: triggers a callback function with the given key.
```dart
  box.trigger(key: 'doSomething', data: {'id': 1});
```

- **execute**: executes an event.
```dart
  box.execute(NotesEvent.add('New Note', 'This is a new note'));
```

- **executeBlockPop**: executes an event and blocks the pop of the view until the event is finished.
```dart
  box.executeBlockPop(context, NotesEvent.add('New Note', 'This is a new note'));
```

### 7. BoxProviders

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
- **Usage**: Use `MultiBoxProvider` when you need to provide multiple boxes to a subtree. (recommended to be used in the root of the app under MaterialApp)
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

## 8. Event Handling

Events in Mastro provide a structured way to handle actions and state changes.

- **Purpose**: Define and handle events that modify the state.
- **Usage**: Create event classes that extend `MastroEvent` and implement the `implement` method.
- **Example**:
  ```dart
  sealed class NotesEvent extends MastroEvent<NotesBox> {
    const NotesEvent();
    factory NotesEvent.add(String title, String content) = _AddNoteEvent;
    factory NotesEvent.delete(int id) = _DeleteNoteEvent;
  }

  class _AddNoteEvent extends NotesEvent {
    final String title;
    final String content;

    _AddNoteEvent(this.title, this.content);

    @override
    Future<void> implement(NotesBox box, Callbacks callbacks) async {
      //do your logic here
      
      // Notify listeners that note was added successfully
      callbacks.invoke('onNoteAdded', data: {'noteId': note.id});
    }
  }

  class _DeleteNoteEvent extends NotesEvent {
    final int id;

    _DeleteNoteEvent(this.id);

    @override
    Future<void> implement(NotesBox box, Callbacks callbacks) async {
      box.notes.modify((notes) => notes.value.removeWhere((note) => note.id == id));
    }
  }
  ```

- **Executing Event Without Callbacks**:
```dart
  await box.execute(
    NotesEvent.delete(13),
  );
```
- **Executing Event With Callbacks**:
```dart
  await box.execute(
    NotesEvent.add('Title', 'Content'),
    callbacks: Callbacks({
      'onNoteAdded': ({data}) {
        print('Note added with ID: ${data?['noteId']}');
      },
    }),
  );
```

#### Event Modes

- **parallel**: Multiple instances can run simultaneously
- **sequential**: Events of same type are queued
- **solo**: Only one instance can run at a time

```dart
class ComplexEvent extends MastroEvent<AppBox> {
  const ComplexEvent();

  @override
  EventRunningMode get mode => EventRunningMode.sequential; // here you override default mode

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    // do your logic here
  }
}
```

## 9. Widget Building

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

- **Purpose**: Rebuild parts of the UI by calling `box.tag` function to trigger updates for specific tags.
- **Usage**: Use `TagBuilder` to create widgets that needs to be rebuild when a specific tag is triggered.
- **Example**:
  ```dart
  TagBuilder(
    tag: 'new_number',
    box: box,
    builder: (context) => Text('The new number is ${Random().nextInt(100)}'),
  );

  // Trigger a rebuild for the 'important' tag
  box.tag('new_number');
  ```

## 10. MastroView Pattern

MastroView provides a structured way to create screens with lifecycle management.

- **Purpose**: Manage the lifecycle of a screen and its associated state.
- **Usage**: Extend `MastroView` to create a screen with lifecycle hooks.
- **Functions**:
  - **initState**: called when the view is initialized
  - **dispose**: called when the view is disposed
  - **onResume**: called when the app is resumed from background
  - **onInactive**: called when the app becomes inactive
  - **onPaused**: called when the app is paused
  - **onHide**: called when the app is hidden
  - **onDetached**: called when the app is detached
  - **rebuild**: rebuilds the view

#### Using Local Box

Create or pass a `MastroBox` instance directly to a `MastroView` super constructor.

- **Example**:
  ```dart
  class LocalNotesView extends MastroView<NotesBox> {
    LocalNotesView({super.key}) : super(box: NotesBox()); // here you pass the box

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

#### Using Global Box By Using MultiBoxProvider Or BoxProvider

Use `MultiBoxProvider` or `BoxProvider` to define `MastroBox` instances in the widget tree prior to the creation of the MastroView.

if you forget to use `MultiBoxProvider` or `BoxProvider` with the required box type, you will get an error.

- **Example**:
  ```dart
  class GlobalNotesView extends MastroView<NotesBox> {
    const GlobalNotesView({super.key});  // we don't need to pass the box here

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

## 11. MastroTriggerable
MastroTriggerable is a widget that can be triggered to rebuild specific parts of the UI.
- **Purpose**: rebuild specific parts of the UI.
- **Usage**: use `MastroTriggerable` to rebuild specific parts of the UI.
- **Example**:
```dart
final trigger = MastroTriggerable();

trigger.build(() => Text('This is a triggerable widget')); // this returns a widget.

trigger.trigger(); // this will rebuild the widget
```


## 12. Scopes

Mastro provides a way to manage app-wide behaviors using scopes, particularly useful when handling events that block user interactions.

#### OnPopScope

- **Purpose**: Manage user interactions during blocking events within `MastroScope`.
- **Usage**: Use `OnPopScope` to define behavior when an event blocks user from popping the view.
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

#### executeBlockPop

- **Purpose**: Execute events that block user interactions until completion.
- **Usage**: Use `executeBlockPop` to run events that should prevent user from popping the view until the event is finished.
- **Example**:
  ```dart
  await box.executeBlockPop(
    context,
    NotesEvent.add('New Note', 'This is a new note'),
  );
  ```

## Global vs. Local Box Usage

- **Global Usage**: Use `MultiBoxProvider` to define `MastroBox` instances that can be accessed from anywhere in the app. This is useful for app-wide settings or data that needs to be shared across multiple screens.
  
- **Local Usage**: Create or pass a `MastroBox` instance directly to a `MastroView` for data that is only relevant to a particular screen or widget.

## 13. Project Structure

Mastro follows a feature-based architecture pattern that promotes organization and separation of layers. Here's the recommended project structure:

```
lib/
├── core/                     # Core functionality and configurations
├── shared/                   # Shared resources (models, utilities, etc.)
│   ├── models/
│   └── repositories/
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
  const NotesView({super.key}) : super(box: NotesBox());

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
- Clear separation of layers
- Feature isolation
- Easy navigation and maintenance
- Scalable architecture
- Reusable components

## 14. Examples

Check the `example` folder for more detailed examples of how to use Mastro in your Flutter app.

## 15. Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on [GitHub](https://github.com/Yousef-Shaiban/mastro).

## 16. License

This project is licensed under the MIT License - see the LICENSE file for details.
