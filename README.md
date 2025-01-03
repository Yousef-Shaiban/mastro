# Mastro

A powerful and flexible state management solution for Flutter that combines reactive programming with event handling and persistence.

## Features

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

Add Mastro to your `pubspec.yaml`:

```yaml
dependencies:
  mastro: ^1.0.0
```

## Initialization

Initialize Mastro in your main.dart:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MastroInit.initialize();
  
  runApp(
    MastroApp(
      onPopScope: OnPopScope(
        onPopWaitMessage: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait...')),
          );
        },
      ),
      child: MaterialApp(
        home: YourHomeWidget(),
      ),
    ),
  );
}
```

## Core Concepts

### 1. State Management

#### Lightro - Lightweight State
For simple, single-value states:

```dart
// Basic usage
final counter = 0.lightro;
final isEnabled = false.lightro;
final name = "John".lightro;

// Updating values
counter.value++;
isEnabled.toggle();
name.value = "Jane";

// Listening to changes
counter.addListener(() {
  print('Counter changed: ${counter.value}');
});

// Modifying state
name.modify((state) {
  state.value = 'New Value';
});
```

#### Mastro - Advanced State
For complex state management with computed values and validation:

```dart
// Basic usage
final counter = 0.mastro;
final items = <String>[].mastro;

// Computed values
final isEven = counter.compute((value) => value % 2 == 0);
final isEmpty = items.compute((list) => list.isEmpty);

// Dependencies
counter.dependsOn(otherState);

// Validation
counter.setValidator((value) => value >= 0 && value <= 100);

// Observers
counter.observe('counterChanged', (value) {
  print('Counter changed to: $value');
});

// Modifying collections
items.modify((state) {
  state.value.add('New Item');
});
```

### 2. MastroBox Pattern

MastroBox is the core container for your application's state and logic:

```dart
class TodoBox extends MastroBox<TodoEvent> {
  // State declarations
  final todos = PersistroMastro.list<Todo>(
    'todos',
    initial: [],
    fromJson: (json) => Todo.fromJson(json),
  );
  final filter = TodoFilter.all.mastro;
  final searchQuery = ''.lightro;

  // Computed states
  late final filteredTodos = todos.compute((list) {
    return list.where((todo) {
      final matchesFilter = filter.value.matches(todo);
      final matchesSearch = todo.title
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  });

  @override
  void init() {
    // Setup dependencies
    filteredTodos.dependsOn(filter);
    filteredTodos.dependsOn(searchQuery);

    // Debug logging
    todos.debugLog('todos');
    filter.debugLog('filter');
  }
}
```

### 3. Event Handling

Events provide a structured way to handle state changes:

```dart
// Event definitions
sealed class TodoEvent extends MastroEvent<TodoBox> {
  const TodoEvent();
  
  factory TodoEvent.add(String title) = _AddTodoEvent;
  factory TodoEvent.toggle(String id) = _ToggleTodoEvent;
  factory TodoEvent.delete(String id) = _DeleteTodoEvent;
  factory TodoEvent.reorder(String id, int newIndex) = _ReorderTodoEvent;
}

// Event implementations
class _AddTodoEvent extends TodoEvent {
  final String title;
  
  const _AddTodoEvent(this.title);

  @override
  EventRunningMode get mode => EventRunningMode.sequential;

  @override
  Future<void> implement(TodoBox box, Callbacks callbacks) async {
    final todo = Todo(
      id: DateTime.now().toString(),
      title: title,
      completed: false,
    );
    
    box.todos.modify((state) {
      state.value.add(todo);
    });
    
    callbacks.invoke('todoAdded', data: {'id': todo.id});
  }
}

// Using events with callbacks
todoBox.addEvent(
  TodoEvent.add('New Todo'),
  callbacks: Callbacks({
    'todoAdded': ({data}) {
      print('Todo added with ID: ${data?['id']}');
    },
  }),
);
```

### 4. Persistent Storage

Mastro provides built-in persistence capabilities:

```dart
class SettingsBox extends MastroBox<SettingsEvent> {
  // Primitive persistence
  final isDarkMode = PersistroLightro.boolean(
    'isDarkMode',
    initial: false,
    autoSave: true,
  );
  
  final fontSize = PersistroLightro.number(
    'fontSize',
    initial: 16,
  );
  
  // Complex object persistence
  final userPreferences = PersistroMastro<UserPreferences>(
    'userPreferences',
    initial: UserPreferences.defaults(),
    decoder: (json) => UserPreferences.fromJson(jsonDecode(json)),
    encoder: (value) => jsonEncode(value.toJson()),
  );
  
  // List persistence
  final recentSearches = PersistroMastro.list<String>(
    'recentSearches',
    initial: [],
    fromJson: (json) => json as String,
  );
  
  // Map persistence
  final cachedData = PersistroMastro.map<String>(
    'cachedData',
    initial: {},
    fromJson: (json) => json as String,
  );
}
```

### 5. Widget Building Patterns

#### MastroBuilder
For reactive widget updates:

```dart
// Single state
MastroBuilder(
  mastro: counter,
  builder: (state, context) => Text('${state.value}'),
);

// Multiple states
MastroBuilder(
  mastro: counter,
  listeners: [isEven, isActive],
  builder: (state, context) => Text(
    'Count: ${state.value} (${isEven.value ? "Even" : "Odd"})',
  ),
);

// Conditional rebuilds
MastroBuilder(
  mastro: counter,
  shouldRebuild: (prev, current) => prev != current,
  builder: (state, context) => Text('${state.value}'),
);
```

#### TagBuilder
For targeted widget updates:

```dart
TagBuilder(
  tag: 'updateTodo',
  box: todoBox,
  builder: (context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => FadeTransition(
      opacity: _fadeAnimation,
      child: child,
    ),
  ),
);

// Trigger update
todoBox.tag(
  tag: 'updateTodo',
  data: {'id': 'todo-123'},
);
```

### 6. MastroView Pattern

MastroView provides a structured way to create screens with lifecycle management:

```dart
class TodoView extends MastroView<TodoBox> {
  TodoView({super.key}) : super(box: TodoBox());

  @override
  void initState(BuildContext context, TodoBox box) {
    // Initialize view-specific logic
  }

  @override
  void onResume(BuildContext context, TodoBox box) {
    // Called when app resumes
    box.addEvent(TodoEvent.refresh());
  }

  @override
  Widget build(BuildContext context, TodoBox box) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          MastroBuilder(
            mastro: box.filter,
            builder: (filter, context) => DropdownButton<TodoFilter>(
              value: filter.value,
              onChanged: (value) => filter.value = value!,
              items: TodoFilter.values.map((f) => 
                DropdownMenuItem(
                  value: f,
                  child: Text(f.name),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
      body: MastroBuilder(
        mastro: box.filteredTodos,
        builder: (todos, context) => ListView.builder(
          itemCount: todos.value.length,
          itemBuilder: (context, index) {
            final todo = todos.value[index];
            return TodoItem(todo: todo);
          },
        ),
      ),
    );
  }
}
```

### 7. Advanced Features

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

#### State Validation
```dart
final password = ''.mastro
  ..setValidator((value) {
    if (value.length < 8) return false;
    if (!value.contains(RegExp(r'[A-Z]'))) return false;
    if (!value.contains(RegExp(r'[0-9]'))) return false;
    return true;
  });

// Invalid updates are ignored
password.value = '123'; // Value remains unchanged
```

#### Debug Tools
```dart
// State logging
counter.debugLog('counter');

// Custom observers
counter.observe('analytics', (value) {
  analytics.logEvent('counter_changed', {'value': value});
});

// Test helpers
class TestTodoBox extends TestMastroBox<TodoEvent> {
  // Access event history
  void verifyEvents() {
    final history = eventHistory;
    expect(history.length, 2);
    expect(history.first, isA<_AddTodoEvent>());
  }
}
```

## Best Practices

### 1. State Organization

```dart
class UserBox extends MastroBox<UserEvent> {
  // Group related states
  final user = PersistroMastro<User>(
    'user',
    initial: User.empty(),
    decoder: User.fromJson,
    encoder: (u) => u.toJson(),
  );
  
  // Derived states
  late final isLoggedIn = user.compute((u) => u.id.isNotEmpty);
  late final displayName = user.compute((u) => 
    u.nickname.isNotEmpty ? u.nickname : u.email);
    
  // UI states
  final isLoading = false.lightro;
  final errorMessage = ''.lightro;
  
  @override
  void init() {
    // Setup dependencies
    displayName.dependsOn(user);
    
    // Debug logging
    user.debugLog('user');
  }
}
```

### 2. Event Handling

```dart
// Event hierarchy
sealed class UserEvent extends MastroEvent<UserBox> {
  const UserEvent();
  
  // Authentication events
  factory UserEvent.login(String email, String password) = _LoginEvent;
  factory UserEvent.logout() = _LogoutEvent;
  
  // Profile events
  factory UserEvent.updateProfile(UserProfile profile) = _UpdateProfileEvent;
  factory UserEvent.changePassword(String current, String new) = _ChangePasswordEvent;
}

// Error handling
class _LoginEvent extends UserEvent {
  final String email;
  final String password;
  
  const _LoginEvent(this.email, this.password);
  
  @override
  Future<void> implement(UserBox box, Callbacks callbacks) async {
    try {
      box.isLoading.value = true;
      box.errorMessage.value = '';
      
      final user = await authService.login(email, password);
      box.user.value = user;
      
      callbacks.invoke('loginSuccess');
    } catch (e) {
      box.errorMessage.value = e.toString();
      callbacks.invoke('loginError', data: {'error': e});
    } finally {
      box.isLoading.value = false;
    }
  }
}
```

### 3. Widget Structure

```dart
// Reusable components
class UserAvatar extends StatelessWidget {
  final UserBox box;
  
  const UserAvatar({super.key, required this.box});
  
  @override
  Widget build(BuildContext context) {
    return MastroBuilder(
      mastro: box.user,
      builder: (user, context) => CircleAvatar(
        backgroundImage: NetworkImage(user.value.avatarUrl),
        child: user.value.isOnline
            ? const Badge(
                backgroundColor: Colors.green,
                alignment: Alignment.bottomRight,
              )
            : null,
      ),
    );
  }
}

// Page organization
class ProfileView extends MastroView<UserBox> {
  ProfileView({super.key}) : super(box: UserBox());
  
  @override
  Widget build(BuildContext context, UserBox box) {
    return Scaffold(
      appBar: AppBar(
        title: MastroBuilder(
          mastro: box.displayName,
          builder: (name, context) => Text(name.value),
        ),
        actions: [
          UserAvatar(box: box),
        ],
      ),
      body: MastroBuilder(
        mastro: box.isLoading,
        builder: (loading, context) {
          if (loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return const ProfileContent();
        },
      ),
    );
  }
}
```

## Testing

```dart
void main() {
  group('TodoBox Tests', () {
    late TestTodoBox box;
    
    setUp(() {
      box = TestTodoBox();
    });
    
    test('Add Todo', () async {
      await box.addEvent(TodoEvent.add('Test Todo'));
      
      expect(box.todos.value.length, 1);
      expect(box.todos.value.first.title, 'Test Todo');
      
      // Verify event history
      expect(box.eventHistory.length, 1);
      expect(box.eventHistory.first, isA<_AddTodoEvent>());
    });
    
    test('Sequential Events', () async {
      // Queue multiple events
      box.addEvent(TodoEvent.add('Todo 1'));
      box.addEvent(TodoEvent.add('Todo 2'));
      
      // Wait for all events to process
      await Future.delayed(Duration.zero);
      
      expect(box.todos.value.length, 2);
      expect(
        box.todos.value.map((t) => t.title),
        ['Todo 1', 'Todo 2'],
      );
    });
  });
}
```

## Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on [GitHub](https://github.com/Yousef-Shaiban/pressable).

##  License

This project is licensed under the MIT License - see the LICENSE file for details.
