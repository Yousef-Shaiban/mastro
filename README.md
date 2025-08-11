<img src="https://i.imgur.com/zLRQvjd.png" > 

# Mastro

A pragmatic, fast, and ergonomic **Flutter state toolkit** that blends
**reactive state**, **event orchestration**, **persistence**, and **view/scope glue**
into a clean, testable, **feature‑based** architecture.

> Zero boilerplate for simple state — strong patterns for complex flows.

---

# Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Project Structure (Feature-based)](#project-structure-featurebased)
- [Overall Flow (How it links up)](#overall-flow-how-it-links-up)
- [Quick Start](#quick-start)
- [Reactive State](#reactive-state)
  - [Lightro vs Mastro (Comparison)](#lightro-vs-mastro-comparison)
  - [Lightro](#lightro)
  - [Mastro](#mastro)
  - [Mastro Functions](#mastro-functions)
  - [Validation & Error Handling](#validation--error-handling)
  - [AsyncState](#asyncstate)
  - [`late()` state and helpers](#late-state-and-helpers)
- [Persistence (Persistro)](#persistence-persistro)
- [Boxes & Events](#boxes--events)
  - [Local vs Scoped (Global) Boxes](#local-vs-scoped-global-boxes)
  - [MastroBox lifecycle & options](#mastrobox-lifecycle--options)
  - [Creating a Box](#creating-a-box)
  - [Creating Events](#creating-events)
  - [Running Events](#running-events)
  - [EventRunningMode](#eventrunningmode)
  - [Box Tagging & Loose Callbacks](#box-tagging--loose-callbacks)
- [Widget Building](#widget-building)
  - [MastroBuilder](#mastrobuilder)
  - [TagBuilder](#tagbuilder)
  - [RebuildBoundary](#rebuildboundary)
- [MastroScope (back-blocking UX)](#mastroscope-backblocking-ux)
- [MastroView (view glue & lifecycle)](#mastroview-view-glue--lifecycle)
- [FAQ](#faq)
- [Examples](#examples)
- [Contributions](#contributions)
- [License](#license)

---

## Features

- **Feature‑based structure**: each feature owns its **presentation**, **logic** (boxes & events), and optional **states**.
- **Reactive state**: `Lightro<T>` , `Mastro<T>` both support `.modify`, `.late()`, and builders.
- **Events engine**: `parallel`, **per‑type** `sequential` (FIFO with awaitable queued calls), and **per‑type** `solo` (suppress duplicates of the same type).
- **Gesture‑friendly builders**: `MastroBuilder` / `TagBuilder` rebuild **immediately when safe**.
- **Persistence**: `PersistroLightro` / `PersistroMastro` on top of `SharedPreferences`.
- **Scopes**: `MastroScope` integrates back‑blocking UX for long tasks.
- **Views**: `MastroView<T>` pairs a screen with its box (local or scoped) and exposes lifecycle hooks.

---

## Installation

```yaml
dependencies:
  mastro: ^<latest>
```

```bash
flutter pub get
```

If you use persistence, initialize it **once** before `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Persistro.initialize();
  runApp(const MyApp());
}
```

---

## Project Structure (Feature‑based)

Each **feature** owns its UI and logic (and optional custom states). Keep shared bits in `core/`.

```
lib/
  core/                        # theming, routing, env, DI helpers, shared states
  features/
    auth/
      presentation/            # widgets, screens, MastroView subclasses
        auth_view.dart         
      logic/                   # boxes + events for this feature
        auth_box.dart
        auth_event.dart
      states/                  # custom sealed/union states (optional)
    todos/
      presentation/
        components/
        todo_view.dart
      logic/
        todos_box.dart
        todos_event.dart
  app.dart
  main.dart
```

**Naming convention** (logic):
- `*_box.dart` for boxes
- `*_event.dart` for events
- `*_view.dart` for views

---

## Overall Flow (How it links up)

1) **Provide or create a box**
  - **Scoped (Global)**: provide with `BoxProvider` / `MultiBoxProvider` high in the tree.
  - **Local**: pass a factory directly to your `MastroView` super constructor.

2) **Render a view (`MastroView<T>`)**
  - If you passed a local factory → the view uses that instance.
  - Otherwise → it resolves the box from `BoxProvider.of<T>(context)`.

3) **Build widgets** with `MastroBuilder` / `TagBuilder` listening to reactive state.

4) **Run events** via `box.execute(event)` (or `executeBlockPop(context, event)` to block back via `MastroScope`).

5) **Persist state over sessions** with `Persistro` - `PersistroLightro` - `PersistroMastro` when needed.

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBoxProvider(
      providers: [
        // Scoped (Global) box
        BoxProvider(create: (_) => CounterBox()),
      ],
      child: const MaterialApp(
        home: CounterView(),
      ),
    );
  }
}

// features/counter/logic/counter_box.dart
class CounterBox extends MastroBox<CounterEvent> {
  final count = 0.lightro;
}

// features/counter/logic/counter_event.dart
sealed class CounterEvent extends MastroEvent<CounterBox> {
  const CounterEvent();
  const factory CounterEvent.increment() = _Increment;
}

class _Increment extends CounterEvent {
  const _Increment();
  @override
  Future<void> implement(CounterBox box, Callbacks callbacks) async {
    box.count.value++;
  }
}

// features/counter/presentation/counter_view.dart
class CounterView extends MastroView<CounterBox> {
  // Local: pass a box directly to the super constructor:
  // const CounterView({super.key}) : super(box: () => CounterBox());
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, CounterBox box) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: MastroBuilder(
          state: box.count,
          builder: (state, context) => Text('Count: ${state.value}', style: const TextStyle(fontSize: 36)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => box.execute(const CounterEvent.increment()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

> **Local vs Scoped (Global)**: in a `MastroView`, pass `super(box: () => YourBox())` to use a **local** instance.  
> If you omit it, the view will resolve a **scoped** box from `BoxProvider`.

---

## Reactive State

### Lightro vs Mastro (Comparison)

| Capability                              | **Lightro\<T\>**                         | **Mastro\<T\>**                                           |
|----------------------------------------|------------------------------------------|-----------------------------------------------------------|
| Reactive `.value`                      | ✅ (`state.value = x`)                    | ✅                                                         |
| `modify` in‑place mutation             | ✅ `state.modify((state) { state.value.field = ...; })` | ✅            |
| `late()` (uninitialized start)         | ✅                                        | ✅                                                         |
| Computed/derived values                | ❌                                        | ✅ `compute((self) => ...)` + `.dependsOn(other)`          |
| Validation                             | ❌                                        | ✅ `setValidator(...)` + `onValidationError`               |
| Observers (side effects)               | ❌                                        | ✅ `.observe('key', (v) => ...)`                           |

> **Tip:** Start with **Lightro**; choose **Mastro** when you need compute/validation/dependencies/observers.

### Lightro

```dart
final isEnabled = false.lightro;

MastroBuilder(
  state: isEnabled,
  builder: (state, context) => Switch(
    value: state.value,
    onChanged: (value) => state.value = value,
  ),
);
```

### Mastro

```dart
class Profile { String name; int age; Profile(this.name, this.age); }

final profile = Profile('Alice', 30).mastro;

// In-place updates
profile.modify((s) {
  s.value.name = 'Bob';
  s.value.age++;
});

// Computed with dependency
final factor = 2.mastro;
final scaledAge = profile
  .compute((p) => p.age * factor.value);

// Validation & observers
profile
  ..setValidator((p) => p.name.isNotEmpty && p.age >= 0)
  ..observe('log', (p) => debugPrint('Profile → ${p.name}(${p.age})'));
```

### Mastro Functions

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

  validatedState.value = 1; // accepted
  validatedState.value = -1; // rejected (see next section to handle errors)
  ```

- **observe**: Observe changes in the state and execute a callback when the state changes.
  ```dart
  observedState.observe('observedState', (value) {
    print('State changed to $value');
  });
  ```

### Validation & Error Handling

Mastro supports validation **and** error callbacks out of the box:

```dart
final age = 25.mastro;

// Validation rule + error handler
age.setValidator(
  (v) => v >= 0 && v <= 120,
  onValidationError: (invalid) {
    // Show a toast/snack, log, or recover
    debugPrint('Invalid age: $invalid');
  },
);

// Setting an invalid value will NOT update the state;
// instead, onValidationError is invoked.
age.value = -5;   // ❌ rejected, handler runs
age.value = 26;   // ✅ accepted
```

Validation can also be added to **computed** states:

```dart
final price = 10.mastro;
final qty   = 2.mastro;

final total = price.compute((p) => p * qty.value)
  // ensure positive totals only
  ..setValidator((t) => t > 0, onValidationError: (t) {
    debugPrint('Non-positive total: $t');
  });
```

### AsyncState

Wrap `AsyncState<T>` in a reactive container so the UI can **listen**:

```dart
// Best practice: wrap in Lightro (or Mastro)
final userState = const AsyncState<User>.initial().lightro;
// or: final userState = const AsyncState<User>.initial().mastro;

Future<void> loadUser() async {
  userState.value = const AsyncState.loading();
  try {
    final u = await repo.fetchUser();
    userState.value = AsyncState.data(u);
  } catch (e) {
    userState.value = AsyncState.error('Failed: $e');
  }
}

MastroBuilder(
  state: userState,
  builder: (state, _) => state.value.when(
    initial: (_) => const Text('Tap to load'),
    loading: () => const CircularProgressIndicator(),
    data: (u) => Text('Hello ${u.name}'),
    error: (msg, _) => Text(msg ?? 'Error'),
  ),
);
```

### `late()` state and helpers

Both Lightro & Mastro support **uninitialized** state via `.late()`:

```dart
final token = Lightro<String>.late();  // or: final profile = Mastro<User>.late();

// Accessing before setting throws UninitializedLate...Exception:
token.value; // ❌ throws

// Initialize first:
token.value = 'abc'; // ✅

// Safe branching:
final label = token.when(
  uninitialized: () => 'No token',
  initialized: (v) => 'Token: $v',
);
```

Key helpers & properties (both kinds):
- `isInitialized`
- `ensureInitialized()`
- `when({uninitialized, initialized})`
- `resetToUninitialized()`
- `notify()`

---

## Persistence (Persistro)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Persistro.initialize();
  runApp(const MyApp());
}
```

Low‑level API + reactive wrappers:

```dart
// Low-level key/value
await Persistro.putString('token', 'abc');
final token = await Persistro.getString('token');

// Reactive persisted state (Lightro flavor)
final cart = PersistroLightro.list<CartItem>(
  'cart',
  initial: [],
  fromJson: (j) => CartItem.fromJson(j),
);

// Reactive persisted state (Mastro flavor)
final isDark = PersistroMastro.boolean('isDarkMode', initial: false);

// Manual control if needed
await isDark.persist();
await isDark.restore();
await isDark.clear();
```

---

## Boxes & Events

### Local vs Scoped (Global) Boxes

- **Local**: Pass a box **directly to your view** via the `MastroView` super constructor.
  ```dart
  class SearchView extends MastroView<SearchBox> {
    const SearchView({super.key}) : super(box: () => SearchBox()); // local
    ...
  }
  ```

- **Scoped (Global)**: Provide a box using `BoxProvider`/`MultiBoxProvider` high in the tree, then let views resolve it automatically.
  ```dart
  MultiBoxProvider(
    providers: [
      BoxProvider<AuthBox>(create: (_) => AuthBox()),
    ],
    child: const App(),
  );
  ```

Access anywhere via:
```dart
final box = BoxProvider.of<AuthBox>(context);
```

### MastroBox lifecycle & options

Each box exposes small lifecycle hooks and options:

- `init()` → override to set up (call `super.init()`).
- `cleanup()` → override to tear down (call `super.cleanup()`); **idempotent**.

**Auto cleanup knobs**
- `autoCleanupWhenAllViewsDetached` *(bool; box property, provider option)*  
  When `true`, the box **calls `cleanup()` automatically** after the **last** attached `MastroView` detaches.
- `autoCleanupWhenUnmountedFromWidgetTree` *(bool; provider option)*  
  When `true`, the provider **calls `cleanup()`** when the provider subtree unmounts (e.g., navigating away).

> TL;DR
> - Short‑lived screens → Local box (pass via view).
> - Long‑lived features → Scoped box (provider), and fine‑tune cleanup with the two flags above.

### Creating a Box

```dart
// features/notes/logic/notes_box.dart
class NotesBox extends MastroBox<NotesEvent> {
  final notes = <Note>[].mastro;

  @override
  void init() { super.init(); }

  @override
  void cleanup() { super.cleanup(); }
}
```

### Creating Events

```dart
// features/notes/logic/notes_event.dart
sealed class NotesEvent extends MastroEvent<NotesBox> {
  const NotesEvent();
  const factory NotesEvent.add(String title) = _AddNote;
  const factory NotesEvent.load() = _Load;
}

class _AddNote extends NotesEvent {
  final String title;
  const _AddNote(this.title);

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    box.notes.modify((s) => s.value.add(Note(title)));
    callbacks.invoke('toast', data: {'msg': 'Note added'}); // optional loose callback
  }
}

class _Load extends NotesEvent {
  const _Load();

  @override
  EventRunningMode get mode => EventRunningMode.sequential; // serialize

  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    // fetch and assign
  }
}
```

### Running Events

```dart
// With callbacks:
await box.execute(
  const NotesEvent.add('New Note'),
  callbacks: Callbacks.on('toast', (data) {
    // receive callback from event
  }),
);

// Override mode at call-site & block back while running:
await box.executeBlockPop(
  context,
  const NotesEvent.load(),
  mode: EventRunningMode.solo,
);
```

### EventRunningMode

- `parallel` (default): Multiple instances can run simultaneously, run freely.
- `sequential`: Events of same type are queued, **per‑type FIFO** — one event of a given runtime type at a time; others queue behind it.  
  **Queued calls return a Future that completes when that specific queued item finishes.**
- `solo`: **per‑type exclusivity** — another SOLO of the **same** type is ignored while one runs (different SOLO types may run concurrently).

### Box Tagging & Loose Callbacks

- **Tagging**: fire a **targeted UI refresh** without wiring explicit state:
  ```dart
  // in box
  tag(tag: 'refresh-notes');

  // in view/widget
  TagBuilder(tag: 'refresh-notes', box: box, builder: (_) => NotesList());
  ```

- **Loose callbacks**: decouple UI actions from events:
  ```dart
  // register once (e.g., in view initState)
  box.registerCallback(key: 'toast', callback: (data) {
    final msg = data?['msg'] as String? ?? 'Done';
    showToast(msg);
  });

  // from event
  callbacks.invoke('toast', data: {'msg': 'Saved ✅'});

  // cleanup (e.g., view dispose)
  box.unregisterCallback(key: 'toast');
  ```

---

## Widget Building

### MastroBuilder

Listens to one primary `Basetro` (plus optional `listeners`). It rebuilds **immediately when safe**

```dart
MastroBuilder(
  state: box.profile,
  listeners: [box.settings], // optional
  shouldRebuild: (prev, next) => prev.id != next.id, // optional
  builder: (state, context) => Text('Hello ${state.value.name}'),
);
```
- `state`: The state object that the widget depends on.
- `builder`: A function that builds the widget based on the current state.
- `listeners` (optional): Additional states to listen to.
- `shouldRebuild` (optional): Predicate `(prev, next) => bool` to skip redundant rebuilds.

### TagBuilder

Rebuild only when a **specific tag** is fired by the box:

```dart
TagBuilder(
  tag: 'refresh-notes',
  box: box,
  builder: (_) => NotesList(notes: box.notes.value),
);

// later
box.tag(tag: 'refresh-notes');
```

### RebuildBoundary

Force a subtree to rebuild via a key swap (handy for resetting animations/forms):

```dart
final boundary = RebuildBoundary();

Widget build(BuildContext context) {
  return boundary.build((context, key) => AnimatedSwitcher(
    key: key,
    duration: kThemeChangeDuration,
    child: MyForm(),
  ));
}

// later
boundary.trigger();
```

---

## MastroScope (back‑blocking UX)

Wrap your app (or subtree) with a `MastroScope` to enable **back‑blocking** for long‑running tasks via `executeBlockPop`:

```dart
MaterialApp(
home: MastroScope(
onPopScope: OnPopScope(
onPopWaitMessage: (context) {
// e.g., show a SnackBar/overlay while back is blocked
},
),
child: HomeView(),
),
);
```

How it works:
- `executeBlockPop(context, event)` wraps the event in a scope that **blocks the system back** (via `PopScope`) until the event finishes.
- While blocked, `OnPopScope.onPopWaitMessage` is invoked to let you show feedback (e.g., “Please wait…”).

---

## MastroView (view glue & lifecycle)

`MastroView<T extends MastroBox>` pairs a screen/page with its box and wires lifecycle/UX:

- **Constructor**
  - `const MyView({super.key}) : super(box: () => MyBox());` → **Local** box
  - `const MyView({super.key});` + provider → **Scoped** box
- **Box resolution** (internal)
  - Local factory provided → use that instance.
  - Otherwise → resolve via `BoxProvider.of<T>(context)`.
- **Lifecycle hooks** you can override (all receive `context` and `box`):
  - `initState`: called when the view is initialized
  - `dispose`: called when the view is disposed
  - `onResume`: called when the app is resumed from background
  - `onInactive`: called when the app becomes inactive
  - `onPaused`: called when the app is paused
  - `onHide`: called when the app is hidden
  - `onDetached`: called when the app is detached
  - `rebuild(context)`: rebuilds the view
- **MastroScope integration**
  - If a `MastroScope` with an `OnPopScope` is present above, `executeBlockPop` will **guard back navigation** until the event completes.

---

## FAQ

**Do sequential events of type A block type B?**  
No — queues are **per event type**.

**Does SOLO block everything?**  
No — SOLO is **per‑type**: duplicates of the **same** SOLO type are suppressed while one runs; different SOLO types may run concurrently.

**Can I await a queued sequential call?**  
Yes — queued sequential calls return a `Future` that completes when **that specific queued item** finishes.

**Is `modify` only for Mastro?**  
No — `modify` is available on **all** Basetro containers (Lightro & Mastro).

**How do I use a local box in a view?**  
Pass it via the super constructor: `const MyView() : super(box: () => MyBox());`

---

## Examples

Check the `example` folder for more detailed examples of how to use Mastro in your Flutter app.

---

## Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on GitHub.

---

## License

MIT © Yousef Shaiban
