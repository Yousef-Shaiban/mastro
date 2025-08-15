<img src="https://i.imgur.com/zLRQvjd.png" > 

A pragmatic, fast, and ergonomic Flutter state toolkit that blends **reactive state**, **event orchestration**, **persistence**, and **view/scope glue** into a clean, testable, feature‑based architecture.

> Zero boilerplate for simple state — strong patterns for complex flows.

---

## Table of Contents

- [Features](#features)
- [Why Mastro](#why-mastro)
- [Installation](#installation)
- [Project Structure (Feature‑based)](#project-structure-feature-based)
- [Overall Flow (Clear, Step‑by‑Step)](#overall-flow-clear-step-by-step)
- [Quick Start](#quick-start)
- [Reactive State](#reactive-state)
  - [Lightro vs Mastro (Comparison)](#lightro-vs-mastro-comparison)
  - [Lightro](#lightro)
  - [Mastro](#mastro)
  - [Mastro Functions (What/When/How)](#mastro-functions-whatwhenhow)
  - [.modify() vs .value (when to use which?)](#modify-vs-value-when-to-use-which)
  - [Validation & Error Handling](#validation--error-handling)
  - [late() state](#late-state)
  - [AsyncState](#asyncstate)
  - [Custom Sealed State Classes (beyond AsyncState)](#custom-sealed-state-classes-beyond-asyncstate)
- [Persistence (Persistro → PersistroLightro → PersistroMastro)](#persistence-persistro--pestristrolightro--pestristromastro)
- [Boxes & Events](#boxes--events)
  - [Local vs Scoped (Global) Boxes](#local-vs-scoped-global-boxes)
  - [MastroBox lifecycle & options](#mastrobox-lifecycle--options)
  - [Creating a Box](#creating-a-box)
  - [Actions with or without Events](#actions-with-or-without-events)
  - [Creating Events (optional)](#creating-events-optional)
  - [Running Events (awaitable)](#running-events-awaitable)
  - [EventRunningMode](#eventrunningmode)
  - [Box Tagging & Loose Callbacks](#box-tagging--loose-callbacks)
- [Widget Building](#widget-building)
  - [MastroBuilder](#mastrobuilder)
  - [TagBuilder](#tagbuilder)
  - [RebuildBoundary](#rebuildboundary)
- [MastroScope (back‑blocking UX)](#mastroscope-backblocking-ux)
- [MastroView (view glue & lifecycle)](#mastroview-view-glue--lifecycle)
- [Provider placement with `MaterialApp` (important)](#provider-placement-with-materialapp-important)
- [Public API Reference (Quick Links)](#public-api-reference-quick-links)
- [FAQ](#faq)
- [Design Patterns & Recipes](#design-patterns--recipes)
- [License](#license)

---

## Features

- Feature‑based structure: each feature owns its presentation, logic (boxes & events), and optional states.
- Reactive state: `Lightro<T>` and `Mastro<T>` both support `.value`, `.modify(...)`, `.late()` and builder helpers.
- **New:** `.safe` accessor on state containers for late initialization ergonomics.
- **New:** `Mastro.dependsOn(...)` handles both **computed** *and* **notify‑only** modes (the old `compute()` method is removed).
- Events engine (optional): rich execution modes, callbacks, and back‑blocking UX — but you can also just call box methods.
- Gesture‑friendly builders: `MastroBuilder` / `TagBuilder` rebuild immediately when safe.
- Persistence: `PersistroLightro` / `PersistroMastro` built on top of `SharedPreferences` via `Persistro`.
- Scopes: `MastroScope` integrates back‑blocking UX for long‑running tasks.
- Views: `MastroView<T>` pairs a screen with its box (local or scoped) and exposes lifecycle hooks including **`onViewAttached` / `onViewDetached`**.

---

## Why Mastro

Mastro is intentionally structured and explicit — think of it like the statically‑typed approach to Flutter state.

- **Readable by design:** In `MastroBuilder`, you explicitly point to the exact state(s) that drive a widget. This precision keeps reviewers oriented and makes behavior obvious. Tools like GetX or Flutter Signals can feel lighter because they infer dependencies automatically. Mastro trades a bit of ceremony for **clarity, predictability, and team readability**.
- **Well‑defined structure:** Boxes own logic; views are thin; persistence is explicit. This scales cleanly as features multiply.
- **Minimal rebuilds:** Only the listening subtree rebuilds — no hidden global invalidations. Refine with `listeners` and `shouldRebuild` to make rebuilds laser‑focused.
- **Explicit dependencies:** Use `dependsOn([...], compute: ...)` to declare why something updates. Unlike implicit dependency systems, Mastro favors clarity and predictability.
- **Flexible orchestration:** For simple UIs, call box methods directly. When flows get tricky, opt into events for concurrency modes (`parallel`/`sequential`/`solo`), loose callbacks, and back‑blocking UX.

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

Keep each feature self‑contained: UI, logic (boxes + actions/events), and optional typed states. Shared bits live in `core/`.

### Recommended Layout (visual + consistent)

```
lib/
  core/                         # theme · router · DI · shared states
    theme/
    routing/
    env/
    states/
  features/
    auth/
      presentation/             # widgets & screens
        auth_view.dart
        widgets/
          auth_form.dart
      logic/                    # box + events
        auth_box.dart
        auth_event.dart         # (optional)
      states/                   # sealed/union types (optional)
        auth_states.dart
    todos/
      presentation/
        todos_view.dart
        widgets/
          todo_tile.dart
      logic/
        todos_box.dart
        todos_event.dart        # (optional)
  app.dart                      # root MaterialApp / scopes / providers
  main.dart                     # entry point
```

**Naming convention (logic):**

- `*_box.dart` for boxes
- `*_event.dart` for events (optional)
- `*_view.dart` for views

### App‑lifetime boxes

If you want a box to live for the whole app session, provide it above your app widget (wrap `MaterialApp`).

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

1) **Choose where your box lives**
- **Scoped (Global)** — provide it near the app root with `BoxProvider` / `MultiBoxProvider` if multiple screens need the same instance.
- **Local** — pass a factory to the `MastroView` super constructor if the box is screen‑local.

2) **Render the view**
- Create `class MyView extends MastroView<MyBox>` (generic is mandatory).
- Inside `build(context, box)`, you get a typed `MyBox` whether it’s local or resolved from `BoxProvider`.

3) **Build the UI from reactive state**
- Use `MastroBuilder` for specific state and `TagBuilder` for “ping refreshes” (tags).

4) **Perform actions**
- Simplest: call box methods (no events needed).
- Richer orchestration: dispatch events (`box.execute(...)`) to get concurrency modes, loose callbacks, and optional back‑blocking (`executeBlockPop`).

5) **(Optional) Persist state**
- Swap to `PersistroLightro` / `PersistroMastro` when a value must survive app restarts.

6) **(Optional) Scope UX**
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

class CounterBox extends MastroBox {
  final count = 0.lightro;

  // Simple action (no event required)
  void increment() => count.value++;
}

class CounterView extends MastroView<CounterBox> {
  CounterView({super.key}) : super(box: () => CounterBox()); // local box factory

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
      ),
    );
  }
}
```

> Flexibility: Keep things simple with box methods; use events only where you need their extra power.

---

## Reactive State

### Lightro vs Mastro (Comparison)

| Capability | Lightro | Mastro | Example |
| --- | --- | --- | --- |
| Reactive `.value` | ✅ | ✅ | `state.value = x` |
| In‑place `modify` | ✅ | ✅ | `state.modify((s) => s.field = ...)` |
| Uninitialized start `late()` | ✅ | ✅ | `final token = Lightro<String>.late();` |
| Computed values | — | ✅ | `sum.dependsOn([a,b], compute: () => a.value + b.value);` |
| Dependencies (`dependsOn`) | — | ✅ | `watcher.dependsOn([price, qty]);` (notify‑only if `compute` omitted) |
| Validation (`setValidator`) | — | ✅ | `state.setValidator((v) => v >= 0);` |
| Observers (`observe`) | — | ✅ | `state.observe('log', print);` |

> **Heads‑up:** the standalone `compute()` method has been **removed**. Use `dependsOn([...], compute: ...)` to derive values, or omit `compute` for notify‑only wiring.

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

// In-place updates; one notify at the end.
await profile.modify((s) {
  s.value.name = 'Bob';
  s.value.age++;
});

// Observe & validate
profile
  ..setValidator((p) => p.name.isNotEmpty && p.age >= 0)
  ..observe('log', (p) => debugPrint('Profile → ${p.name}(${p.age})'));
```

### Mastro Functions (What/When/How)

- `dependsOn<S>(Iterable<Basetro<S>> sources, {T Function()? compute})`  
  **What:** wire this state to other state(s).  
  **When:** you want derived values (provide `compute`) **or** you want to be notified without changing `.value` (omit `compute`).  
  **How:** call with one or more sources. You can remove all with `clearDependencies()` or one with `removeDependency(other)`.

- `setValidator(bool Function(T) validator, {void Function(T invalid)? onValidationError})`  
  **What:** gate assignments to `.value`.  
  **When:** you must enforce invariants (non‑negative totals, non‑empty names, etc.).  
  **How:** on invalid assignment, `.value` is not updated; `onValidationError` fires with the rejected value.

- `observe(String key, void Function(T value) handler)` / `removeObserver(String key)`  
  **What:** subscribe to value changes for side effects (logging, analytics, imperatives).  
  **When:** you need reactions outside the widget tree.  
  **How:** keys are unique; calling `observe` again with the same key replaces the old handler.

- `clearDependencies()`  
  **What:** drop **all** wired dependencies.  
  **When:** you temporarily derived from multiple sources and want to release them (e.g., screen change).

### .modify() vs .value (when to use which?)

- Use **`.value =`** for direct replacements of simple values.
- Use **`.modify(...)`** for *read‑modify‑write* on complex values to bundle edits and emit a **single** notification.

```dart
// Direct replacement
total.value = 0;

// Batched mutations (single notify)
await cart.modify((m) {
  m.value.items.add(newItem);
  m.value.taxes = computeTaxes(m.value.items);
});
```

### Validation & Error Handling

- Invalid assignments are rejected silently with an optional `onValidationError(invalid)` callback.
- Wrap business rules in `setValidator` and keep assignment sites clean.
- Throwing during `.modify(...)` bubbles as usual; no partial notification is emitted.

### late() state

- `.late()` creates an **uninitialized** state that throws if you read `.value` too early.
- The **`.safe`** getter returns `null` before initialization — ideal for first paints:

```dart
final token = Lightro<String>.late();
final name = Lightro<String>.late();

Text(token.safe ?? 'No token'); // ✅ no throw on first build

// name.value; // ❌ throws (uninitialized)
name.value = 'Alex'; // ✅ initialize

final label = token.when(
  uninitialized: () => 'No token',
  initialized: (value) => 'Token: $value',
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
- Plus **all** `Mastro` APIs: `dependsOn`, `setValidator`, `observe`, `removeDependency`, `removeObserver`, ....

---

## Boxes & Events

### Local vs Scoped (Global) Boxes

- **Local:** `MyView() : super(box: () => MyBox());`
- **Scoped:** provide high in the tree and resolve via `BoxProvider.of<T>(context)`

### MastroBox lifecycle & options

Overridables:

- `init()` — called once when the box is constructed (call `super.init()` if overridden).
- `cleanup()` — idempotent cleanup (call `super.cleanup()`).
- **View hooks:** **`onViewAttached(MastroView view)`** and **`onViewDetached(MastroView view)`** fire as views mount/unmount. Useful for ref counts and auto‑cleanup.


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

### Actions with or without Events

- **Without events:** call methods on the box for straightforward logic.
- **With events:** define `MastroEvent<BoxType>` subclasses to opt into concurrency controls, back‑blocking, and loose callbacks.

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

Both `execute(event)` and `executeBlockPop(context, event)` **return `Future<void>`** — you can `await` execution to chain actions or to ensure ordering in your widget logic:

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
- `sequential`: events of this type are queued and executed **one at a time** (FIFO).
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

Provide an `OnPopScope` so `executeBlockPop` can temporarily block the back button and show a “Please wait…” message while an event is running.

```dart
MastroScope(
  onPopScope: OnPopScope(
    onPopWaitMessage: (context) => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please wait…')),
    ),
  ),
  child: MaterialApp(home: const HomeView()),
);
```

---

## MastroView (view glue & lifecycle)

**Generic is mandatory:** `class MyView extends MastroView<MyBox> { ... }`

**Constructors:**
- Local: `MyView() : super(box: () => MyBox());`
- Scoped: `const MyView();` (and provide `MyBox` via `BoxProvider`)

Overridables:

- `initState(BuildContext context, T box)` / `dispose(BuildContext context, T box)`
- `onResume`, `onInactive`, `onPaused`, `onHide`, `onDetached` (app lifecycle)
- **Box receives:** **`onViewAttached(MastroView view)`** / **`onViewDetached(MastroView view)`** as the view mounts/unmounts

> ❗️**Removed:** `rebuild(context)` override on `MastroView` — it no longer exists.

**Box resolution order:**
1. If a local factory is provided → use it.
2. Else → `BoxProvider.of<T>(context)`.
---

## Providers placement with `MaterialApp` (important)

It is **recommended** to place `MastroScope` and your global `BoxProvider`/`MultiBoxProvider` **above** your `MaterialApp` (or in `MaterialApp.builder`).

Why? Because `home:` lives **inside** the `Navigator` that `MaterialApp` creates. A provider placed inside `home:` only wraps **that first route**. As soon as you navigate (`push`, `showDialog`, `showModalBottomSheet`, etc.), new routes won’t see those providers.

### Recommended

```dart
void main() {
  runApp(
    MastroScope(
      onPopScope: OnPopScope(onPopWaitMessage: (c) { /* ... */ }),
      child: MultiBoxProvider(
        providers: [
          BoxProvider(create: (_) => AppBox()),
        ],
        child: MaterialApp(
          home: const HomeView(),
        ),
      ),
    ),
  );
}
```

### Also OK: use `MaterialApp.builder`

```dart
MaterialApp(
  builder: (context, child) => MultiBoxProvider(
    providers: [BoxProvider(create: (_) => AppBox())],
    child: child!,
  ),
  home: const HomeView(),
);
```

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

**I need a “safe read” on a late state.**  
Use `.safe` to get a nullable view of the current value; on first paint it’s `null` until initialized or use `.when(uninitialized: () => ..., initialized: (value) => ...)`.

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

**How do I stop a computed state from listening?**  
Call `clearDependencies()` to remove all wired sources (or `removeDependency(other)`).

**Can I await events?**  
Yes — both `execute` and `executeBlockPop` return `Future<void>`.

**How do I derive from multiple states?**  
Use `dependsOn([a, b, c], compute: () { ... })`. Omit `compute` to just forward notifications (notify‑only).

---

## Examples

Check the `example` folder for more detailed examples of how to use Mastro in your Flutter app.

---

## Contributions

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on GitHub.

---

## License

MIT © Yousef Shaiban

