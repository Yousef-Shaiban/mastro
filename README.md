<img src="https://i.imgur.com/zLRQvjd.png" > 

A pragmatic, fast, and ergonomic Flutter state toolkit that blends **reactive state**, **event orchestration**, **persistence**, and **view/scope glue** into a clean, testable, **feature‑based** architecture.

> Zero boilerplate for simple state — strong patterns for complex flows.

---

## Table of Contents

- [Features](#features)
- [Why Mastro](#why-mastro)
- [Installation](#installation)
- [Project Structure (Feature‑based)](#project-structure-feature-based)
- [Overall Flow (Clear, Step‑by‑Step)](#overall-flow-clear-stepbystep)
- [Quick Start](#quick-start)
- [Reactive State](#reactive-state)
  - [Lightro vs Mastro (Comparison)](#lightro-vs-mastro-comparison)
  - [Lightro](#lightro)
  - [Mastro](#mastro)
  - [Mastro Functions (What/When/How)](#mastro-functions-whatwhenhow)
  - [.modify() vs .value (when to use which?)](#modify-vs-value-when-to-use-which)
  - [Validation & Error Handling](#validation--error-handling)
  - [`late()` state](#late-state)
  - [AsyncState](#asyncstate)
  - [Custom Sealed State Classes (beyond AsyncState)](#custom-sealed-state-classes-beyond-asyncstate)
- [Persistence (Persistro → PersistroLightro → PersistroMastro)](#persistence-persistro--persistrolightro--persistromastro)
- [Boxes & Events](#boxes--events)
  - [Local vs Scoped (Global) Boxes](#local-vs-scoped-global-boxes)
  - [MastroBox lifecycle & options](#mastrobox-lifecycle--options)
  - [Creating a Box](#creating-a-box)
  - [Actions **with or without** Events](#actions-with-or-without-events)
  - [Creating Events (optional)](#creating-events-optional)
  - [Running Events](#running-events)
  - [EventRunningMode](#eventrunningmode)
  - [Box Tagging & Loose Callbacks](#box-tagging--loose-callbacks)
- [Widget Building](#widget-building)
  - [MastroBuilder](#mastrobuilder)
  - [TagBuilder](#tagbuilder)
  - [RebuildBoundary](#rebuildboundary)
- [MastroScope (back‑blocking UX)](#mastroscope-backblocking-ux)
- [MastroView (view glue & lifecycle)](#mastroview-view-glue--lifecycle)
- [Public API Reference (Quick Links)](#public-api-reference-quick-links)
- [FAQ](#faq)
- [Design Patterns & Recipes](#design-patterns--recipes)
- [License](#license)

---

## Features

- **Feature‑based structure:** each feature owns its presentation, logic (boxes & events), and optional states.
- **Reactive state:** `Lightro<T>` and `Mastro<T>` both support `.value`, `.modify`, `.late()` and builder helpers.
- **Computed & orchestration:** `Mastro<T>` adds `compute`, `dependsOn`, `setValidator`, and `observe`.
- **Events engine (optional):** rich execution modes, callbacks, and back‑blocking UX — but **you can also just call box methods**.
- **Gesture‑friendly builders:** `MastroBuilder` / `TagBuilder` rebuild immediately when safe.
- **Persistence:** `PersistroLightro` / `PersistroMastro` built on top of `SharedPreferences` via `Persistro`.
- **Scopes:** `MastroScope` integrates back‑blocking UX for long‑running tasks.
- **Views:** `MastroView<T>` pairs a screen with its box (local or scoped) and exposes lifecycle hooks.

---

## Why Mastro

Mastro is intentionally **structured and explicit** — think of it like the *statically‑typed* approach to Flutter state.

- **Readable by design:** In `MastroBuilder`, you explicitly point to the **exact** state(s) that drive a widget. This precision keeps reviewers oriented and makes behavior obvious.
- **Well‑defined structure:** Boxes own logic; views are thin; persistence is explicit. This scales cleanly as features multiply.
- **Minimal rebuilds:** Only the listening subtree rebuilds — no hidden global invalidations. Refine further with `listeners` and `shouldRebuild` to make rebuilds laser‑focused.
- **Explicit dependencies:** Use `compute` and `dependsOn` to *declare* why something updates.  
  Tools like GetX or Flutter Signals can feel lighter because they infer dependencies automatically. Mastro trades a bit of ceremony for **clarity, predictability, and team readability**.
- **Flexible orchestration:** For simple UIs, **call box methods directly**. When flows get tricky, opt into **events** for concurrency modes (`parallel`/`sequential`/`solo`), loose callbacks, and back‑blocking UX.
- **Balanced philosophy:** Not the “easiest” at first glance, but like a statically typed language, it favors **readability, well‑defined structure, and correctness** — with **minimal rebuilds** and **rich features** when you need them.

---

## Installation

```yaml
dependencies:
  mastro: ^<latest>
```

```dart
// If you use persistence, initialize it once before runApp:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Persistro.initialize(); // shared prefs
  runApp(const MyApp());
}
```

---

## Project Structure (Feature‑based)

Keep **each feature self‑contained**: UI, logic (boxes + actions/events), and optional typed states. Shared bits live in `core/`.

### 📦 Recommended Layout (visual + consistent)

```text
lib/
  core/                         # 🎨 theme · 🧭 router · 🔧 DI · 🧱 shared states
    theme/
    routing/
    env/
    states/
  features/
    auth/
      presentation/             # 🖼️ widgets & screens (MastroView subclasses)
        auth_view.dart
        widgets/
          auth_form.dart
      logic/                    # 🧠 box + actions (+ optional events)
        auth_box.dart
        auth_event.dart         # (optional)
      states/                   # 🧩 sealed/union types (optional)
        auth_states.dart
    todos/
      presentation/
        todos_view.dart
        widgets/
          todo_tile.dart
      logic/
        todos_box.dart
        todos_event.dart        # (optional)
  app.dart                      # 🏠 root MaterialApp / scopes / providers
  main.dart                     # 🚀 entry point
```

**Naming convention (logic):**
- `*_box.dart` for boxes
- `*_event.dart` for events (optional)
- `*_view.dart` for views

### 🧱 App‑lifetime boxes

If you want a box to **live for the whole app session**, provide it **above** your app widget (wrap `MaterialApp`)

```dart
void main() {
  runApp(
    MultiBoxProvider(
      providers: [
        BoxProvider(create: (_) => SessionBox()), // lives as long as the app
      ],
      child: const MaterialApp(home: RootView()),
    ),
  );
}
```

> Placing the provider **outside** the `MaterialApp` ensures the box isn’t recreated when routes are replaced and keeps its state intact.

---

## Overall Flow (Clear, Step‑by‑Step)

**0) Choose where your box lives**
- **Scoped (Global)** — provide it near the app root with `BoxProvider` / `MultiBoxProvider` if multiple screens need the same instance.
- **Local** — pass a factory to the `MastroView` super constructor if the box is screen‑local.

**1) Render the view**
- Create `class MyView extends MastroView<MyBox>` (**generic is mandatory**).
- Inside `build(context, box)`, you get a typed `MyBox` whether it’s local or resolved from `BoxProvider`.

**2) Build the UI from reactive state**
- Use `MastroBuilder` for specific state and `TagBuilder` for “ping refreshes” (tags).

**3) Perform actions**
- **Simplest:** call **box methods** (no events needed).
- **Richer orchestration:** dispatch **events** (`box.execute(...)`) to get concurrency modes, loose callbacks, and optional back‑blocking (`executeBlockPop`).

**4) (Optional) Persist state**
- Swap to `PersistroLightro` / `PersistroMastro` when a value must survive app restarts.

**5) (Optional) Scope UX**
- Wrap screens with `MastroScope` to enable back‑blocking during long tasks.

---

## Quick Start (Counter with local box)

```dart
import 'package:flutter/material.dart';
import 'package:mastro/mastro.dart';

void main() => runApp(const CounterApp());

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CounterView());
  }
}

class CounterBox extends MastroBox<CounterEvent> {
  final count = 0.lightro;

  // Simple action (no event required)
  void increment() => count.value++;
}


class CounterView extends MastroView<CounterBox> {
  const CounterView({super.key}) : super(box: () => CounterBox()); // local box factory

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
          onPressed: box.increment,
          child: const Icon(Icons.add),
        )
    );
  }
}
```

> **Flexibility:** Keep things simple with **box methods**; use **events** only where you need their extra power.

---

## Reactive State

### Lightro vs Mastro (Comparison)

| Capability                         | Lightro<T> | Mastro<T> | Example |
| ---                                | :--:       | :--:      | --- |
| Reactive `.value`                  | ✅          | ✅         | `state.value = x` |
| In‑place `modify`                  | ✅          | ✅         | `state.modify((s) => s.value++)` |
| Uninitialized start `late()`       | ✅          | ✅         | `final token = Lightro<String>.late();` |
| Computed values (`compute`)    | ❌          | ✅         | `final doubled = count.compute((v) => v * 2);` |
| Dependencies (`dependsOn`)     | ❌          | ✅         | `total.dependsOn(price); total.dependsOn(qty);` |
| Validation (`setValidator`)        | ❌          | ✅         | `state.setValidator((v) => v >= 0);` |
| Observers (`observe`)              | ❌          | ✅         | `state.observe('log', print);` |

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

profile.modify((s) {
  s.value.name = 'Bob';
  s.value.age++;
});

final factor = 2;
final scaledAge = profile.compute((p) => p.age * factor);

profile
  ..setValidator((p) => p.name.isNotEmpty && p.age >= 0)
  ..observe('log', (p) => debugPrint('Profile → ${p.name}(${p.age})'));
```

### Mastro Functions (What/When/How)

- **`compute<R>(R Function(T value), {bool Function(R value)? validator, void Function(R invalid)? onValidationError}) → Mastro<R>`**  
  **What:** create a **derived** reactive value from this `Mastro<T>`.  
  **When:** you need a value kept in sync with a source (and optionally validated).  
  **How:** provide a pure function; updates propagate on source change. Optionally validate the computed result.

- **`dependsOn<B>(Basetro<B> other)`**  
  **What:** register **reactive dependency** on another state; when `other` changes, *this* mastro notifies its listeners.  
  **When:** you maintain your own `.value` but want rebuilds when related state changes.  
  **How:** call multiple times to depend on multiple states; remove with `removeDependency(other)`.

- **`setValidator(bool Function(T) validator, {void Function(T invalid)? onValidationError})`**  
  **What:** gate assignments to `.value`.  
  **When:** you must enforce invariants (non‑negative totals, non‑empty names, etc.).  
  **How:** on invalid assignment, `.value` is **not** updated; `onValidationError` fires with the rejected value.

- **`observe(String key, void Function(T value) handler)` / `removeObserver(String key)`**  
  **What:** subscribe to value changes for **side effects** (logging, analytics, imperatives).  
  **When:** you need reactions outside the widget tree.  
  **How:** keys are unique; calling `observe` again with the same key replaces the old handler.

---

### .modify() vs .value (when to use which?)

Both are safe, but they have different ergonomics:

- **`.value = newValue`**
  - **Best for replacements** (assign a brand new value).
  - Triggers validators/observers and notifies **once** per assignment.

- **`.modify((Mutable<T> s) { ... })`**
  - **Best for in‑place edits** of reference types (Lists, Maps, classes) or **batch updates**.
  - The callback receives a `Mutable<T>` (`s.value` is the live value). You can change multiple fields, push to lists, etc.  
    When the callback completes, listeners are **notified once** (coalesced), and validators/observers run once.
  - Supports `FutureOr` → you can `await` inside the modifier to wrap an async critical section in a **single** coherent update.
  - Avoids the common pitfall of mutating a field and forgetting to call `notify()` afterward — `modify` does it for you.

> **Manual notifications:** If you *must* force a rebuild without changing the value (rare), call `state.notify()`.

---

### Validation & Error Handling

```dart
final age = 25.mastro;

age.setValidator(
  (v) => v >= 0 && v <= 120,
  onValidationError: (invalid) {
    debugPrint('Invalid age: $invalid');
  },
);

age.value = -5; // ❌ rejected
age.value = 26; // ✅ accepted
```

### `late()` state

Both Lightro & Mastro support uninitialized state via `.late()`:

```dart
final token  = Lightro<String>.late();
final user   = Mastro<User>.late();

// token.value; // ❌ throws (uninitialized)
token.value = 'abc'; // ✅ initialize

final label = token.when(
  uninitialized: () => 'No token',
  initialized: (v) => 'Token: $v',
);
```

### AsyncState

Model async flows declaratively — then **wrap it** in a reactive container to listen in UI.

```dart
final userState = const AsyncState<User>.initial().lightro;
// or: final userState = const AsyncState<User>.initial().mastro;

Future<void> loadUser() async {
  userState.value = const AsyncState.loading();
  try {
    userState.value = AsyncState.data(await repo.fetchUser());
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

### Custom Sealed State Classes (beyond AsyncState)

You can define your **own** union/sealed state for richer UI states:

```dart
sealed class ProfileState {
  const ProfileState();
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.ready(User user) = _Ready;
  const factory ProfileState.error(String? message) = _Error;
}

class _Initial extends ProfileState { const _Initial(); }
class _Loading extends ProfileState { const _Loading(); }
class _Ready extends ProfileState { final User user; const _Ready(this.user); }
class _Error extends ProfileState { final String? message; const _Error(this.message); }

final profileState = const ProfileState.initial().lightro;
```

Use Dart 3 pattern matching or custom helpers:

```dart
Widget build(BuildContext context) {
  return MastroBuilder(
    state: profileState,
    builder: (s, _) => switch (s.value) {
      _Initial()           => const Text('Tap load'),
      _Loading()           => const CircularProgressIndicator(),
      _Ready(:final user)  => Text('Hi ${user.name}'),
      _Error(:final msg)   => Text(msg ?? 'Error'),
    },
  );
}
```

---

## Persistence (Persistro → PersistroLightro → PersistroMastro)

> `PersistroLightro` and `PersistroMastro` behave like **regular** `Lightro`/`Mastro` but add persistence (`persist/restore/clear`, optional `autoSave`).

### Persistro (low‑level key/value)

**Initialize once** before use.

**Static API** (all return `Future`):
- `initialize()`
- `putString/Int/Double/Bool/StringList(key, value)`
- `getString/Int/Double/Bool/StringList(key)`
- `isInitialized` (getter)

### PersistroLightro (reactive Lightro + persistence)

**Factories** (required/optional args and defaults):
- `boolean(String key, {bool initial = false, bool autoSave = true})`
- `number(String key, {num initial = 0.0, bool autoSave = true})`
- `string(String key, {String initial = '', bool autoSave = true})`
- `list<T>(String key, {required List<T> initial, required T Function(Object json) fromJson, bool autoSave = true})`
- `map<T>(String key, {required Map<String, T> initial, required T Function(Object json) fromJson, bool autoSave = true})`
- `json<T>(String key, {required T initial, required T Function(Map<String, Object?> json) fromJson, required Map<String, Object?> Function(T value) toJson, bool autoSave = true})`

**Constructor** (custom codec, persisted as `String`):
- `PersistroLightro<T>({required String key, required T initial, required String Function(T) encoder, required T Function(String) decoder, bool autoSave = true})`

**Instance methods**:
- `Future<void> persist()` / `restore()` / `clear()`

### PersistroMastro (reactive Mastro + persistence)

**Factories** (same shapes + defaults as Lightro variant):
- `boolean` / `number` / `string` / `list` / `map` / `json`

**Constructor** (custom codec):
- `PersistroMastro<T>({required String key, required T initial, required String Function(T) encoder, required T Function(String) decoder, bool autoSave = true})`

**Instance methods**:
- `Future<void> persist()` / `restore()` / `clear()`
- Plus **all** `Mastro` APIs: `compute`, `dependsOn`, `setValidator`, `observe`, `removeDependency`, `removeObserver`.

---

## Boxes & Events

### Local vs Scoped (Global) Boxes

- **Local**: `const MyView() : super(box: () => MyBox());`
- **Scoped**: provide high in the tree and resolve via `BoxProvider.of<T>(context)`

### MastroBox lifecycle & options

**Overridables**:
- `void init()` — called once when the box is first used (call `super.init()`).
- `void cleanup()` — idempotent cleanup (call `super.cleanup()`).

**Options**:
- `autoCleanupWhenAllViewsDetached` (bool; box property and provider option)
- `autoCleanupWhenUnmountedFromWidgetTree` (bool; provider option)

### Creating a Box

```dart
class NotesBox extends MastroBox<NotesEvent> {
  final notes = <Note>[].mastro;

  // Optional: simple methods instead of events
  void addNote(String title) => notes.modify((s) => s.value.add(Note(title)));
}
```

### Actions **with or without** Events

You can **choose** per‑feature:
- **Just methods (simplest):** `box.addNote('Hi')`
- **Events (richer):** `box.execute(NotesEvent.add('Hi'))`

**Prefer events** when you need:
- Concurrency modes (`parallel`/`sequential`/`solo`)
- Back‑blocking UX (`executeBlockPop`)
- Loose callbacks bus (`Callbacks.on/.invoke`)
- Auditing/telemetry conventions

### Creating Events (optional)

```dart
sealed class NotesEvent extends MastroEvent<NotesBox> {
  const NotesEvent();
  const factory NotesEvent.add(String title) = _AddNote;
  const factory NotesEvent.load() = _Load;
}

class _AddNote extends NotesEvent {
  final String title; const _AddNote(this.title);
  @override
  Future<void> implement(NotesBox box, Callbacks callbacks) async {
    box.addNote(title);
    callbacks.invoke('toast', data: {'msg': 'Note added'});
  }
}

class _Load extends NotesEvent {
  const _Load();
  @override
  EventRunningMode get mode => EventRunningMode.sequential;
  @override
  Future<void> implement(NotesBox box, Callbacks _) async {
    // fetch & assign
  }
}
```

### Running Events

```dart
// Common signatures:
// Future<void> execute(event, {Callbacks? callbacks, EventRunningMode? mode})
// Future<void> executeBlockPop(context, event, {Callbacks? callbacks, EventRunningMode? mode})

await box.execute(
  const NotesEvent.add('New Note'),
  callbacks: Callbacks.on('toast', (data) => showToast(data?['msg'])),
);

await box.executeBlockPop(
  context,
  const NotesEvent.load(),
  mode: EventRunningMode.solo,
);
```

### EventRunningMode

- `parallel` (default): run freely.
- `sequential`: per‑type FIFO queue; each queued `execute` is awaitable.
- `solo`: per‑type exclusivity — duplicates of the **same** SOLO type are ignored while one runs (different SOLO types may run concurrently).

### Box Tagging & Loose Callbacks

```dart
// Tagging (UI ping)
box.tag(tag: 'refresh-notes');

TagBuilder(
  tag: 'refresh-notes',
  box: box,
  builder: (_) => NotesList(notes: box.notes.value),
);

// Loose callbacks
box.registerCallback(key: 'toast', callback: (data) {
  final msg = data?['msg'] as String? ?? 'Done';
  showSnackBar(msg);
});

// from event
callbacks.invoke('toast', data: {'msg': 'Saved ✅'});

// cleanup
box.unregisterCallback(key: 'toast');
```

---

## Widget Building

### MastroBuilder

**Constructor (key parameters):**  
`MastroBuilder<T>({Key? key, required Basetro<T> state, required Widget Function(Basetro<T> state, BuildContext context) builder, List<Basetro>? listeners, bool Function(T prev, T next)? shouldRebuild})`

```dart
MastroBuilder<User>(
  state: box.profile,
  listeners: [box.settings], // optional
  shouldRebuild: (prev, next) => prev.id != next.id, // optional
  builder: (state, context) => Text('Hello ${state.value.name}'),
);
```

### TagBuilder

**Constructor (key parameters):**  
`TagBuilder({Key? key, required String tag, required Widget Function(BuildContext) builder, required MastroBox box})`

```dart
TagBuilder(
  tag: 'refresh-notes',
  box: box,
  builder: (_) => NotesList(notes: box.notes.value),
);
```

### RebuildBoundary

**API:**
- `Widget build(Widget Function(BuildContext context, Key key) builder)`
- `void trigger({Key? key})`

```dart
final boundary = RebuildBoundary();

Widget build(BuildContext context) {
  return boundary.build((context, key) => Form(key: key, child: const MyForm()));
}

boundary.trigger(); // forces subtree to rebuild (new key)
```

---

## MastroScope (back‑blocking UX)

```dart
MaterialApp(
  home: MastroScope(
    onPopScope: OnPopScope(
      onPopWaitMessage: (context) {
        // e.g., show overlay while busy
      },
    ),
    child: HomeView(),
  ),
);
```

**Use with** `executeBlockPop(context, event, {callbacks, mode})` to block system back until the event completes.

---

## MastroView (view glue & lifecycle)

**Generic is mandatory:** `class MyView extends MastroView<MyBox> { ... }`

**Constructors:**
- Local: `const MyView() : super(box: () => MyBox());`
- Scoped: `const MyView();` (and provide `MyBox` via `BoxProvider`)

**Overridables:**
- `initState`, `dispose`
- `onResume`, `onInactive`, `onPaused`, `onHide`, `onDetached`
- `rebuild(BuildContext context)`

**Box resolution order:**
1. If a local factory is provided → use it.
2. Else → `BoxProvider.of<T>(context)`.

---

## Public API Reference (Quick Links)

> Links point to the official API on pub.dev.

**Core containers**
- [`Basetro<T>`](https://pub.dev/documentation/mastro/latest/mastro/Basetro-class.html)
- [`Lightro<T>`](https://pub.dev/documentation/mastro/latest/mastro/Lightro-class.html)
- [`Mastro<T>`](https://pub.dev/documentation/mastro/latest/mastro/Mastro-class.html)
- [`Mutable<T>`](https://pub.dev/documentation/mastro/latest/mastro/Mutable-class.html)

**State helpers**
- [`AsyncState<T>`](https://pub.dev/documentation/mastro/latest/mastro/AsyncState-class.html)
- Extensions: [`StateTools`](https://pub.dev/documentation/mastro/latest/mastro/StateTools.html), [`MastroBoolTools`](https://pub.dev/documentation/mastro/latest/mastro/MastroBoolTools.html), [`BasetroBuilderTools`](https://pub.dev/documentation/mastro/latest/mastro/BasetroBuilderTools.html), [`MutableCall`](https://pub.dev/documentation/mastro/latest/mastro/MutableCall.html)

**Persistence**
- [`Persistro`](https://pub.dev/documentation/mastro/latest/mastro/Persistro-class.html)
- [`PersistroLightro<T>`](https://pub.dev/documentation/mastro/latest/mastro/PersistroLightro-class.html)
- [`PersistroMastro<T>`](https://pub.dev/documentation/mastro/latest/mastro/PersistroMastro-class.html)

**Boxes & events**
- [`MastroBox<TEvent extends MastroEvent>`](https://pub.dev/documentation/mastro/latest/mastro/MastroBox-class.html)
- [`MastroEvent<TBox>`](https://pub.dev/documentation/mastro/latest/mastro/MastroEvent-class.html)
- [`EventRunningMode`](https://pub.dev/documentation/mastro/latest/mastro/EventRunningMode.html)
- [`Callbacks`](https://pub.dev/documentation/mastro/latest/mastro/Callbacks-class.html)

**Widget glue & providers**
- [`MastroBuilder`](https://pub.dev/documentation/mastro/latest/mastro/MastroBuilder-class.html)
- [`TagBuilder`](https://pub.dev/documentation/mastro/latest/mastro/TagBuilder-class.html)
- [`RebuildBoundary`](https://pub.dev/documentation/mastro/latest/mastro/RebuildBoundary-class.html)
- [`MastroScope`](https://pub.dev/documentation/mastro/latest/mastro/MastroScope-class.html) • [`OnPopScope`](https://pub.dev/documentation/mastro/latest/mastro/OnPopScope-class.html)
- [`MastroView<T>`](https://pub.dev/documentation/mastro/latest/mastro/MastroView-class.html)
- [`BoxProvider<T extends MastroBox>`](https://pub.dev/documentation/mastro/latest/mastro/BoxProvider-class.html) • [`MultiBoxProvider`](https://pub.dev/documentation/mastro/latest/mastro/MultiBoxProvider-class.html) • [`ClassProvider<T>`](https://pub.dev/documentation/mastro/latest/mastro/ClassProvider-class.html) • [`StaticWidgetProvider`](https://pub.dev/documentation/mastro/latest/mastro/StaticWidgetProvider-class.html)

---

## FAQ

**Do I have to use Events?**  
No. You can call **box methods** directly for simple logic. Use **events** when you want orchestration: concurrency modes, back‑blocking (`executeBlockPop`), and loose callbacks.

**Where should I place a box that must survive `pushReplacement`?**  
Provide it **above** your `MaterialApp` (e.g., wrap the app with `MultiBoxProvider`). This keeps the box alive across route replacements.

**How do I avoid unnecessary rebuilds?**  
Listen only to the state you need via `MastroBuilder(state: ...)`. Use `listeners` for additional dependencies and `shouldRebuild(prev, next)` to short‑circuit rerenders.

**What’s the difference between `.value` and `.modify(...)`?**  
Use `.value = newValue` for simple replacement. Use `.modify(...)` to batch in‑place edits (lists/maps/objects) and notify exactly **once** at the end (validators/observers also run once).

**When do I need `notify()`?**  
Rarely. It’s a `Basetro` method that manually notifies listeners **without** changing `.value`.

**Does `compute` update automatically?**  
Yes — a computed `Mastro<R>` updates when its **source** changes. If your value depends on multiple sources, call `dependsOn(...)` to make dependencies explicit.

**How do I persist a nested object?**  
Use `PersistroLightro.json` or `PersistroMastro.json` and supply `fromJson`/`toJson` for the type. For collections, use `list<T>`/`map<T>` factories.

**Will scoped boxes auto‑dispose?**  
By default, providers clean up when unmounted. You can also enable `autoCleanupWhenAllViewsDetached` to clean when the last `MastroView` detaches.

---

## Design Patterns & Recipes

**Thin Events, Fat Methods**  
Keep feature logic in **box methods**. Use **events** only for orchestration (modes, callbacks, block‑back).

**Batch saves with `autoSave: false`**  
Prefer `autoSave: false` when you mutate many times in a row; call `persist()` once at the end.

**Back‑blocking only for critical ops**  
Reserve `executeBlockPop` for actions that must finish or be cancelled explicitly (e.g., payment submit).

**Tags for cheap refresh**  
Use `TagBuilder` when you need to refresh a section without introducing a dedicated state.

---

## Examples

Check the `example` folder for more detailed examples of how to use Mastro in your Flutter app.

---

## Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on GitHub.

---

## License

MIT © Yousef Shaiban
