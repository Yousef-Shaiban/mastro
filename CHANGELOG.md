## 1.6.0

* Minor bug fixes and improvements.
* Updated documentation.

### 🚨 Breaking / Behaviour Changes
- **Removed `MastroView.rebuild()`**  
  The manual rebuild method has been deleted. Views should rebuild reactively via `MastroBuilder`, `TagBuilder`, and state updates.
- **Removed standalone `compute()` on state**  
  All computed/derived wiring now goes through `dependsOn([...], compute: ...)`. See the **Migration Guide** below.
- **SEQUENTIAL events – waiting behaviour updated**  
  The semantics for *waiting* on `EventRunningMode.sequential` were refined. Each `execute(...)` now completes when **its own enqueued item** finishes, while the queue continues to drain in order. Code that implicitly relied on the first caller waiting for the **entire** queue to finish should be updated to `await` the specific calls it cares about

### ✨ Added
- **`.safe`** on state containers (`Basetro<T>.safe`)  
  A nullable accessor that returns `null` before a `.late()` state is initialized. Ideal for first-paint reads without throwing.
- **`clearDependencies()`** on `Mastro<T>`  
  Removes all wired dependencies established via `dependsOn(...)` (idempotent). Use when changing the set of sources dynamically.

### 🔁 Changed
- **Derived values via `dependsOn`**  
  `dependsOn([...], compute: ...)` now covers what `compute()` used to do and more:
    - Depend on **multiple** states simultaneously (value intersections).
    - Provide a `compute` function to set a derived value.
    - **Notify‑only mode:** omit `compute` to propagate changes without mutating the dependent’s `.value`.


## 1.5.1
* Minor bug fixes and improvements.
* README overhaul with clearer structure and richer explanations.

## 1.5.0

### Breaking changes
- **Boxes**
    - `dispose()` → `cleanup()` — Replace any `dispose()` overrides with `cleanup()` (call `super.cleanup()` inside).
    - New **Callbacks** mechanism:  
      Old: `Callbacks({'action': ({data}) { ... }})`  
      New: `Callbacks.on('action', (data) { ... }).on(...).on(...)`
- **Initialization**
    - `MastroInit.init()` is **no longer available** — use `Persistro.initialize()` for persistence setup.

### Added
- **Providers:** new flags
    - `autoCleanupWhenUnmountedFromWidgetTree`
    - `autoCleanupWhenAllViewsDetached`  
      Behavior unchanged — both control when `cleanup()` is called automatically.
- **Late state support:** `.late()` for uninitialized state on both `Lightro` and `Mastro`, with helpers: `isInitialized`, `ensureInitialized()`, `when(...)`, `resetToUninitialized()`.
- **AsyncState:** new `AsyncState<T>` class for predefined async states (`initial`, `loading`, `data`, `error`), with `.lightro` / `.mastro` wrappers for reactive binding in UI.
- **MastroBox:** new `autoCleanupWhenAllViewsDetached`, `onViewAttached`, and `onViewDetached` hooks.
- **Awaitable sequential events:** each queued `execute()` in `EventRunningMode.sequential` now returns a `Future` that completes **when that specific queued item finishes** (per-type FIFO preserved).
- **Rebuild utilities:** added `RebuildBoundary` helper to force subtree rebuilds via a `UniqueKey`.
- **ClassProvider.onDispose:** allows running custom cleanup logic when a provided class instance is disposed.
- **StaticWidgetProvider:** new provider type for supplying static widget instances in the tree without rebuilds.
- **Docs:** new README with feature-based structure, Lightro vs Mastro comparison, AsyncState, local vs scoped boxes, lifecycle hooks, and `MastroScope` guidance.

### Changed
- **Local boxes in views:** recommended pattern is to pass a **new box** through the `MastroView` super constructor (commonly via a small factory/closure), while **scoped** boxes are provided via `BoxProvider` / `MultiBoxProvider`.
- **Validation & observers (Mastro):** clarified usage; validators can gate assignments and run `onValidationError`.

### Improvements
- **Performance improvements** in event execution and builder notifications.
- **Builders responsiveness**
    - `MastroBuilder` and `TagBuilder` now perform **immediate rebuilds when safe** (idle / transient / mid-frame) and defer with **post-frame coalescing** only during build/layout/paint.
    - Internal **defer tokens** prevent stale callbacks, avoiding jank with fast gestures.
- **`TagBuilder` hot-swap safety:** re-attaches when `box` changes in `didUpdateWidget`.
- **Logging:** state changes are now logged for easier debugging and tracking.
- **Error handling:** improved error messages for validation failures and runtime exceptions.
- **Persistro:** improved initialization flow and persistence operations; now initialized explicitly via `Persistro.initialize()` and supports more reliable state restoration and storage.

## 1.0.2

* Minor fixes and improvements.

## 1.0.1

* Minor fixes and improvements.
* Updated documentation.

## 1.0.0+3

* Updated documentation.

## 1.0.0+2

* Updated documentation.

## 1.0.0+1

* Updated documentation.

## 1.0.0

* First stable release
* Minor fixes and improvements.
* Updated documentation.

## 0.9.7

* Minor fixes and improvements.

## 0.9.6

* Updated documentation.

## 0.9.5

* Minor fixes.

## 0.9.4

* Minor fixes.

## 0.9.3

* Minor fixes.

## 0.9.2

* Minor fixes.

## 0.9.1

* Minor fixes and improvements.

## 0.9.0

* Initial release.

