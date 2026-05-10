# Spec — Sequence Feature

## Overview

Add a **Sequence** item type to the Daily Inc app. A Sequence is a named container
that holds an ordered list of existing `DailyThing` child items and runs them
back-to-back when its play button is tapped. The goal is to support exercise
circuits, morning routines, or any ordered set of timed activities that should
chain automatically without the user needing to navigate between them.

## What It Should Do

### Data model
- `ItemType.sequence` added to the enum — appears **first** in the type dropdown.
- `DailyThing` gains `List<String> childIds` (default `[]`), serialised as JSON.
- `DailyThing` gains `bool autoPlay` (default `false`), serialised as JSON.
- A child id appears in **at most one** sequence's `childIds` (many-to-one).
- The sequence wrapper uses its own `intervalType/intervalValue/intervalWeekdays`
  to govern due-ness. Children's own scheduling fields are suppressed while
  parented — the parent sequence is the scheduling authority.
- The sequence wrapper does **not** use `startValue`, `endValue`, `duration`,
  `increment`, `history`, `bellSoundPath`, or `subdivisions`. These are set to
  safe defaults on creation and hidden in the form.
- All other fields (`name`, `icon`, `category`, `notes`, `nagTime`,
  `notificationEnabled`, `isPaused`, `isArchived`) are active on the wrapper.
- Child items remain full `DailyThing` objects — their progression, history, and
  increment math are completely unchanged.

### Creating a sequence
- Selecting `Sequence` in the item-type dropdown of the add/edit form shows a
  simplified form: icon, name, type, category, interval schedule, notification,
  notes. The "Incremental Progress" section (start date, start/end values,
  duration, increment, bell sound, subdivisions) is hidden.
- A "Sequence Options" section is shown with:
  - **Auto-advance** toggle (`autoPlay`) — when on, completing one `minutes`
    child automatically navigates to the next; when off, ▶ launches only the
    first undone item with no chaining.
  - **Auto-start** toggle (`autoStart`) — only active when Auto-advance is on;
    when on, each chain-launched timer starts counting immediately without a tap.
    Turning Auto-advance off also forces Auto-start off.
  - **Items** list — shows current children with a remove button each.
  - **Add Items** button — opens a checkbox dialog listing all non-sequence,
    non-archived items not already in this sequence.
- Saving sweeps newly claimed children from any other sequence's `childIds`.

### Assigning a child from the child's own form
- Non-sequence items show a **"Belongs to sequence"** dropdown (None + all
  sequences). Changing it updates the old and new sequence's `childIds` on save.

### List rendering
- The daily list renders a **flat expanded list** of rows built as:
  `List<({DailyThing item, DailyThing? parent})>`
- Top-level row: any `DailyThing` that is not a child of any sequence.
- Child rows: immediately follow their parent sequence header, rendered indented
  with a left accent border and a slightly elevated card background color
  (`colorScheme.surfaceContainerHighest`) to visually distinguish them from top-level items.
- Sequence header row uses the **same visual layout as a normal item row**:
  - Left: collapse/expand chevron, done/undone icon (derived), item icon, name.
  - Right: same 90×35 chip — blue + ✓ when complete; red with child count + ▶ when not.
  - Tapping the chip launches the sequence timer (same as tapping ▶ on a normal minutes item).
- Collapse state is persisted per-sequence in `SharedPreferences`
  (`key: 'seq_expanded_<id>'`, default true = expanded).

### Done state
- A sequence is **complete for today** when all its due children are done.
- A sequence is **undone today** when any child is undone.
- These are derived; the user cannot manually toggle the sequence's done state.

### Playback
- Tapping ▶ on a sequence resolves its children in order, finds the first undone
  child, then:
  - If `autoPlay` is **on**: pushes `TimerView` with `allItems = resolvedChildren`
    and `currentItemIndex = indexOfFirstUndoneChild` (existing chain behaviour).
  - If `autoPlay` is **off**: pushes `TimerView` with `allItems = [firstUndoneChild]`
    and `currentItemIndex = 0` (single item, no chaining).
- `TimerView` gains `autoAdvance`, `autoStart`, and `chainAutoStart` params (all `bool`, default `false`).
  - `autoAdvance`: `_onTimerComplete` waits 2 s then calls `_navigateToNextTask()`.
  - `autoStart`: `initState` triggers `_toggleTimer()` on the first frame (this timer auto-starts).
  - `chainAutoStart`: forwarded through `pushReplacement`; `_navigateToNextTask` sets
    `autoStart: widget.chainAutoStart` so only chain-launched timers auto-start, not the first.
  - `_showSequenceTimer` passes `autoAdvance: seq.autoPlay, chainAutoStart: seq.autoPlay && seq.autoStart`.
  - `DailyThing` gains `autoStart: bool` (default `false`, serialised) alongside existing `autoPlay`.
- Only `minutes` children auto-advance. Non-`minutes` children cause the chain to
  pop back to the daily list (existing `timer_view.dart` behaviour).

### Drag-and-drop (via `ReorderableListView`)
- The flat row list is passed to `ReorderableListView`. The `onReorder` callback
  inspects source/destination rows and handles four cases:

  | Source | Destination | Action |
  |---|---|---|
  | top-level item | between top-level items | standard reorder |
  | top-level item | inside a sequence block | assign as child |
  | child item | within same sequence block | reorder within sequence |
  | child item | outside its sequence block | promote to top-level |

- **Empty sequence drop zone:** When a sequence has no children, an invisible
  placeholder row (`id: '__seq_placeholder_<seqId>'`) is inserted with `parent: seq`.
  It renders as a 48px "Drop items here or tap to add" box (muted border, low-opacity text).
  Dragging any item onto it assigns it as the first child. Tapping it opens the
  add-item form with the sequence pre-selected in "Belongs to sequence".
  The placeholder disappears once the sequence has at least one child.

### Lifecycle
- **Delete sequence:** children are promoted to top-level (removed from
  `childIds`); the sequence itself is deleted.
- **Delete child:** child id is swept from any sequence's `childIds`.
- **Archive sequence:** wrapper hidden from filtered view; children unaffected.
- **Duplicate item:** `childIds: []` always — a duplicate sequence is an empty
  shell.

## Assumptions & Uncertainties

- `timer_view.dart` and `stopwatch_view.dart` require **no changes** — existing
  chain logic already handles non-`minutes` items by popping to the main UI.
- `filterDisplayedItems` in `filtering_helpers.dart` must exclude items whose
  `findParentSequence != null` from the flat list (children are rendered inline,
  not as separate top-level rows).
- `checkAndShowCompletionSnackbar` in `daily_things_view.dart` must exclude
  child items from the "all done" calculation and use `SequenceHelper` for
  sequence completion state.
- The `isUndoneToday` switch in `DailyThing` needs a `sequence` case returning
  `false` — `SequenceHelper` is authoritative for sequences; the model getter is
  not called for sequence-level logic.

## Constraints

- Solo developer. Keep changes focused; do not refactor adjacent code.
- Backwards compatible: old JSON without `childIds` must load cleanly (default `[]`).
- `ReorderableListView` must remain — do not replace the list widget.

## How We'll Know It's Done

1. Can create a new Sequence via the add-item form (Sequence is first in the type list).
2. Items can be added to a sequence via the sequence's edit form (checkbox dialog).
3. Items can be assigned to a sequence from the child item's edit form ("Belongs to sequence").
4. Children render indented under the sequence header.
5. Collapse/expand persists across app restarts.
6. With Auto-advance on: tapping ▶ chains through `minutes` children automatically.
7. With Auto-advance off: tapping ▶ goes to first undone item only, no chaining.
8. When the chain hits a non-`minutes` child it returns to the main list.
9. Deleting a sequence promotes its children to top-level.
10. `flutter analyze` passes with zero errors.

## What's Not Included

- Sequences nested inside sequences (no recursion).
- Children belonging to multiple sequences (many-to-many).
- Per-child override of sequence scheduling.
- Graph or history views for sequences (no numeric data on the wrapper).
