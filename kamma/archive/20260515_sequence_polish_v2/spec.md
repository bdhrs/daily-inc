# Spec — Sequence Polish v2

## Overview
Seven follow-on improvements to the Sequence feature. No new
concepts. Two small data-model additions (`chainDelaySeconds`,
`startBellSoundPath`). The rest is UI / behavior wiring.

## Project context (as discovered)
- `DailyThing` (lib/src/models/daily_thing.dart): immutable, has
  `childIds`, `autoPlay`, `autoStart`, `bellSoundPath` (end bell),
  `subdivisionBellSoundPath`, `isArchived`. Persists via `toJson` /
  `fromJson`.
- `SequenceHelper` (lib/src/core/sequence_helper.dart):
  `findParentSequence`, `resolveChildren`,
  `sequenceShouldShowInList`, etc.
- Sequence rendering lives in `daily_things_view.dart`:
  - `_buildDisplayRows` flattens sequence + children into rows.
  - `_sequenceExpanded` controls per-sequence collapse.
  - `_isExpanded` controls per-item expansion (used for everything
    that isn't a sequence header, including children).
  - `_expandAllVisibleItems` uses `filterDisplayedItems`, which
    *excludes* children — so the current collapse-all skips them.
  - `_duplicateItem` already handles sequence-on-sequence cloning,
    but for a child it inserts the new item at `originalIndex + 1`
    without touching the parent sequence's `childIds` — so the copy
    lands outside the sequence.
- `data_manager.dart` exposes `archiveDailyThing(item)` /
  `unarchiveDailyThing(item)`; both currently flip a single item.
- Bell sound UI lives in `add_edit_daily_item_view.dart`:
  - `_bellSoundController` + `_selectedBellSoundPath` (end bell, in
    its own gated `if minutes` block, lines ~1655–1703).
  - Subdivision bell lives inside the "Subdivisions" section (~1715+)
    and uses a similar `CustomBellSelectorDialog`.
  - These two are styled differently today.
- Chain delay between auto-advanced items is hardcoded
  `Future.delayed(const Duration(seconds: 10))` in
  `timer_view.dart::_onTimerComplete` (line 579).
- Sequence's own item-graph (`GraphView`) and the compact
  `MiniGraphWidget` currently graph the sequence's *own* history —
  which is always empty — so sequences show a flat zero line.
- The category graph (`category_graph_view.dart`) already iterates
  all items by category and sums `actualValue` per day; sequences
  contribute 0 because they have no history. No double-counting risk
  there.
- The "main graph view" the user referenced is the per-item
  `GraphView` opened from a sequence's expanded card.

## What it should do

### 1. Per-sequence chain delay (data + setting)
- Add `int chainDelaySeconds` field to `DailyThing` (default `20`).
  Persist via JSON.
- In the "Sequence Options" block of `add_edit_daily_item_view.dart`,
  add a minutes + seconds picker (two `TextFormField`s side by side,
  matching the existing duration / nag-time styling). Label "Delay
  between items".
- `_showSequenceTimer` in `daily_things_view.dart` passes
  `seq.chainDelaySeconds` into `TimerView`; `_onTimerComplete` uses
  that value in place of the hard-coded `10`.

### 2. Cascade archive across a sequence
- When the user archives a sequence, archive every current child of
  that sequence too. When the user unarchives a sequence, unarchive
  every current child as well.
- Implementation: in `daily_thing_item.dart::_archiveItem`, branch
  on `ItemType.sequence` and write the whole set in one
  `saveData(items)` call (avoid per-item `updateDailyThing` round
  trips so the archive flip is atomic).

### 3. Per-item start bell + grouped bell layout
- Add `String? startBellSoundPath` to `DailyThing`. Persist via JSON.
- Play the item's start bell whenever its timer begins:
  - On the very first start of a TimerView session (the user taps
    play).
  - On chained auto-start in `TimerView.initState` when
    `widget.autoStart` is true.
  - If `startBellSoundPath` is `null`, play nothing on start.
- In `add_edit_daily_item_view.dart`, render a single "Bells" group:
  - For `minutes` items, three rows, in this order:
    1. Start bell → `startBellSoundPath`
    2. End bell → `bellSoundPath`
    3. Subdivision bell → `subdivisionBellSoundPath`
  - For `stopwatch` items, two rows (no end bell):
    1. Start bell → `startBellSoundPath`
    2. Subdivision bell → `subdivisionBellSoundPath`
  - Other types unchanged.
  - All rows use the same control type, prefix icon, trailing
    chevron, and `CustomBellSelectorDialog`.
- Use `AudioHelper.playStartBell(item)` (new) so future hooks have a
  single entry point. Internally it calls
  `_player.play(AssetSource(...))` only when the path is non-null.

### 4. Collapse-all cascades to sequence children
- The "expand/collapse all" action should set `_isExpanded[childId]
  = newValue` for every child of every visible sequence in addition
  to the parents.
- Implementation: in `_expandAllVisibleItems`, expand the visible
  list to also include `SequenceHelper.resolveChildren(seq,
  _dailyThings)` for each sequence in the displayed list before
  passing to `toggleExpansionForVisibleItems`.

### 5. Sequence summary graph (sum of children)
- When `widget.dailyThing.itemType == ItemType.sequence`:
  - `GraphView` builds per-day spots by summing each child's
    `actualValue` for that date (and `doneToday ? 1 : 0` for `check`
    children). Trend children contribute their accumulated value.
  - `MiniGraphWidget` does the same over its 14-day window.
- The category and per-item graphs already work correctly because
  the sequence parent contributes 0 (no history). No changes needed
  there.

### 6. Hide a sequence when no children are due
- `SequenceHelper.sequenceShouldShowInList` becomes a one-liner:
  `resolveChildren(seq, allItems).any((c) => c.shouldShowInList)`.
  Children drive sequence visibility 100%; the sequence's own
  startDate / interval fields no longer affect it.
- Verify: a sequence whose children are all weekday-restricted and
  none scheduled for today no longer appears in the main list.

### 7. Copy a child stays in the sequence
- In `_duplicateItem`, when the source item has a parent sequence
  (use `SequenceHelper.findParentSequence`), append the cloned id to
  that sequence's `childIds` (in the same `items` list) and save in
  the same `saveData(items)` call. Keep the insertion-order
  behavior: clone lands immediately after the original within the
  flat `items` array.

## Assumptions & uncertainties
- The user-facing "main graph view" is the per-item `GraphView`
  reached from a sequence's `auto_graph` icon. We're not adding a
  new chart view.
- "Bells" group is presented only for item types where bells are
  meaningful today (minutes, stopwatch). Other types are unchanged.
- Default `chainDelaySeconds = 20` (changes today's hard-coded 10s
  for existing sequences; user-confirmed).
- Trend children won't appear in sequences in practice; we treat
  them as numeric (sum `actualValue`) for now.

## Constraints
- Backwards compatible JSON: every new field is optional with a
  default in `fromJson`.
- No new abstractions beyond the small `playStartBell` helper.
- No refactors of adjacent code.

## How we'll know it's done
1. A sequence shows a "Delay between items" min/sec setting; saving
   it and chaining waits that many seconds between items.
2. Archiving a sequence flips `isArchived` on every child;
   unarchiving flips them back.
3. Each timer-using item shows three identically-styled bell
   pickers; configured start bell plays when the timer starts.
4. Collapse-all collapses sequence children, expand-all expands
   them.
5. A sequence's mini-graph and full graph show the daily sum of its
   children's values; the category graph is unchanged.
6. A sequence with no due children is hidden from the main list
   (unless one is already done today).
7. Tapping copy on a child of a sequence inserts the clone as a
   child of the same sequence, right after the original.
