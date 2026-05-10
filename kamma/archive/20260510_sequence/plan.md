# Plan — Sequence Feature (`20260510_sequence`)

## Architecture Decisions

| Decision | Rationale |
|---|---|
| `ItemType.sequence` on existing `DailyThing` | Reuses all scaffolding (persistence, list, routing). Avoids a second model class. |
| `childIds: List<String>` on the parent | Order encoded in the list. Many-to-one invariant enforced at assign time. |
| `SequenceHelper` static class in `lib/src/core/` | Sequence logic needs `allItems` context that `DailyThing` getters don't have. Keeps the model pure. |
| Flat expanded `({item, parent?})` row list | Lets `ReorderableListView` stay unchanged. Drag semantics detected from row metadata in `onReorder`. |
| No changes to `timer_view.dart` | Existing chain pops on non-`minutes` items — this is exactly the right behaviour for sequences. |
| Suppress child scheduling while parented | The sequence is the scheduling authority. Children's own intervals are irrelevant inside a sequence. |

---

## Phase 1 — Complete the Data Model

### Partially done (already applied before this plan was created)
- `ItemType.sequence` added to enum ✅
- `DailyThing.childIds` field declaration + constructor param added ✅

### Tasks

- [x] Complete `DailyThing` serialisation and helpers for `childIds`
  - Add `'childIds': childIds` to `toJson()`
  - Add `childIds: List<String>.from(json['childIds'] as List? ?? [])` to `fromJson()`
  - Add `List<String>? childIds` param to `copyWith()`, defaulting to `this.childIds`
  - Add `ItemType.sequence` case to the `isUndoneToday` switch returning `false`
    (SequenceHelper is authoritative; the model getter must not crash on sequence items)
  - File: `lib/src/models/daily_thing.dart`
  → verify: `flutter analyze lib/src/models/daily_thing.dart` — zero errors/warnings on the file

- [x] PHASE COMPLETE: verify all tasks done, no regressions

---

## Phase 2 — SequenceHelper

- [x] Create `lib/src/core/sequence_helper.dart`

  Implement the following static methods:

  ```dart
  // Returns the sequence that contains item, or null.
  static DailyThing? findParentSequence(DailyThing item, List<DailyThing> allItems)

  // Returns ordered, non-archived children of seq.
  static List<DailyThing> resolveChildren(DailyThing seq, List<DailyThing> allItems)

  // True if any non-archived child isUndoneToday.
  static bool sequenceIsUndoneToday(DailyThing seq, List<DailyThing> allItems)

  // True if seq.isDueToday AND all non-archived children are done for today.
  // True (vacuously) if seq is not due today.
  static bool sequenceCompletedForToday(DailyThing seq, List<DailyThing> allItems)

  // True if seq.isDueToday or any child hasBeenDoneLiterallyToday.
  static bool sequenceShouldShowInList(DailyThing seq, List<DailyThing> allItems)

  // Returns a new list with deletedId removed from every sequence's childIds.
  static List<DailyThing> sweepDeletedItem(String deletedId, List<DailyThing> allItems)
  ```

  → verify: `flutter analyze lib/src/core/sequence_helper.dart` — zero errors

- [x] PHASE COMPLETE: verify all tasks done, no regressions

---

## Phase 3 — Filtering and Reorder Helpers

- [x] Update `lib/src/views/widgets/filtering_helpers.dart`

  In `filterDisplayedItems`:
  1. After the archived filter, remove items where
     `SequenceHelper.findParentSequence(item, allItems) != null`
     (children are rendered inline under their sequence, not as top-level rows).
  2. In the `showItemsDueToday` filter, for `ItemType.sequence` items use
     `SequenceHelper.sequenceShouldShowInList(item, allItems)` instead of
     `item.shouldShowInList`.
  3. In the `hideWhenDone` branch, for `ItemType.sequence` items use
     `SequenceHelper.sequenceIsUndoneToday(item, allItems)` instead of
     `item.isUndoneToday`.

  → verify: `flutter analyze lib/src/views/widgets/filtering_helpers.dart` — zero errors

- [x] Add `reorderWithSequences` to `lib/src/views/widgets/reorder_helpers.dart`

  Signature:
  ```dart
  List<DailyThing> reorderWithSequences({
    required List<({DailyThing item, DailyThing? parent})> rows,
    required List<DailyThing> fullList,
    required int oldIndex,
    required int newIndex,
  })
  ```

  Four cases detected from `rows[oldIndex].parent` and `rows[newIndex].parent`:

  | Source parent | Dest parent | Action |
  |---|---|---|
  | null | null | Standard top-level reorder: use existing `reorderDailyThings` logic |
  | null | not null (seq) | Remove item from top-level; append to dest sequence's `childIds` |
  | not null (seq) | same seq | Reorder within `childIds` of that sequence |
  | not null (seq) | different parent (null or different seq) | Remove from source `childIds`; if dest is null → top-level; if dest is seq → append to dest `childIds` |

  Returns the updated `fullList`.

  → verify: `flutter analyze lib/src/views/widgets/reorder_helpers.dart` — zero errors

- [x] PHASE COMPLETE: verify all tasks done, no regressions

---

## Phase 4 — UI

- [x] Update `lib/src/views/add_edit_daily_item_view.dart`

  1. Add `sequence` case to the `ItemType` dropdown switch:
     `icon = Icons.playlist_play; name = 'Sequence';`
  2. Wrap the entire "Incremental Progress" section (start date, start/end values,
     duration, increment fields, bell sound, subdivisions) in:
     `if (_selectedItemType != ItemType.sequence)`
  3. In `_submitDailyItem`, add a branch for `ItemType.sequence`:
     pass `startValue: 0, endValue: 0, duration: 1, childIds: const []`.
  4. In `_haveTemplateParametersChanged` and `_storeOriginalTemplate`, handle
     the `childIds` field (pass through unchanged; no change detection needed for it).
  5. In `_duplicateItem` in `daily_things_view.dart` (handled in Phase 4 task below),
     ensure `childIds: const []` for duplicates.

  → verify: `flutter analyze lib/src/views/add_edit_daily_item_view.dart` — zero errors;
    selecting "Sequence" type in the form hides the Incremental Progress section

- [x] Update `lib/src/views/daily_thing_item.dart`

  Add two new constructor params (both with defaults so existing call sites compile):
  ```dart
  final bool isSequenceChild;       // default false
  final DailyThing? parentSequence; // default null
  final List<DailyThing> allItems;  // default const [] — needed for sequence done state
  final VoidCallback? onPlaySequence; // called when ▶ tapped on a sequence row
  ```

  In `build()`:
  - If `widget.item.itemType == ItemType.sequence`: render the sequence header row:
    - Left: collapse arrow (`onTap` calls a passed-in `onToggleCollapse` callback)
    - Icon + name
    - Spacer
    - Child count text (e.g. `3 items`)
    - ✓ / ✗ done indicator (Icon only, not tappable):
      `SequenceHelper.sequenceCompletedForToday(item, allItems)` → green check or red X
    - ▶ `IconButton` calling `onPlaySequence`
    - Expand to show existing action buttons (edit, delete, archive, etc.) as normal
  - If `widget.isSequenceChild == true`: wrap the existing `Card` in a `Padding`
    with `EdgeInsets.only(left: 16)` and add a 4dp left accent border using
    `DecoratedBox` or `Container` with `BoxDecoration(border: Border(left: BorderSide(...)))`.

  → verify: `flutter analyze lib/src/views/daily_thing_item.dart` — zero errors

- [x] Update `lib/src/views/daily_things_view.dart`

  1. **Collapse state:** Add `Map<String, bool> _sequenceExpanded = {}`.
     Load from `SharedPreferences` with key `'seq_expanded_<id>'` (default `true`)
     after `_loadData()`. Save on toggle.

  2. **Flat row builder:** Add method `_buildDisplayRows()` that returns
     `List<({DailyThing item, DailyThing? parent})>` built from `displayedItems`:
     - For each item in `displayedItems`:
       - If not a sequence child: add `(item: item, parent: null)`.
       - If it's a sequence and `_sequenceExpanded[item.id] != false`:
         append each child from `SequenceHelper.resolveChildren(item, _dailyThings)`
         as `(item: child, parent: item)`.

  3. **Build method:** Replace `displayedItems.asMap().entries.map(...)` with
     `rows.asMap().entries.map(...)` where `rows = _buildDisplayRows()`.
     Pass `isSequenceChild: row.parent != null` and `parentSequence: row.parent`
     and `allItems: _dailyThings` to each `DailyThingItem`.
     Pass `onPlaySequence: () => _showSequenceTimer(row.item)` for sequence rows.
     Pass `onToggleCollapse: () => _toggleSequenceCollapse(row.item.id)` for sequence rows.

  4. **Sequence play launcher:** Add `_showSequenceTimer(DailyThing seq)`:
     - Resolves children via `SequenceHelper.resolveChildren`.
     - Finds first undone child.
     - If none, shows a snackbar ("All items complete").
     - Otherwise pushes `TimerView` with `allItems = resolvedChildren`,
       `currentItemIndex = indexOfFirstUndone`, `onExitCallback` same as existing.

  5. **Delete sweep:** In `_deleteDailyThing`, after `dataManager.deleteDailyThing(item)`,
     call `SequenceHelper.sweepDeletedItem(item.id, _dailyThings)` and save the result.

  6. **Duplicate:** Pass `childIds: const []` in `_duplicateItem`.

  7. **Completion check:** In `_checkAndShowCompletionSnackbar`, replace the
     `_dailyThings.where(!isArchived).every(completedForToday)` logic:
     - Exclude items where `findParentSequence != null` (don't double-count children).
     - For `ItemType.sequence`: use `SequenceHelper.sequenceCompletedForToday`.

  8. **Enhanced onReorder:** Replace current `onReorder` with call to
     `reorderWithSequences(rows: rows, fullList: _dailyThings, oldIndex: o, newIndex: n)`
     and save.

  → verify: `flutter analyze lib/src/views/daily_things_view.dart` — zero errors;
    app launches, sequence row renders correctly, play button chains timers

- [x] PHASE COMPLETE: verify all tasks done, no regressions

---

## Final Verification

- [x] Run `flutter analyze` on entire project — zero errors
- [ ] Manually confirm: create sequence → add item via form → tap ▶ → timers chain (auto-advance on) → non-timer pops back
- [ ] Manually confirm: auto-advance off → ▶ goes to first undone item only, no chaining
- [ ] Manually confirm: assign item to sequence from child's edit form
- [ ] Manually confirm: delete sequence → children appear at top-level
- [ ] Manually confirm: collapse state persists after hot-restart

## Post-initial Changes (follow-up)

- [x] Sequence is first item in type dropdown
- [x] Children managed from sequence edit form (add/remove via checkbox dialog)
- [x] Parent sequence assigned from child item edit form ("Belongs to sequence" dropdown)
- [x] `autoPlay: bool` field on `DailyThing` — serialised, default `false`
- [x] Auto-advance toggle in sequence form; `_showSequenceTimer` respects it
- [x] Drag-and-drop into an empty sequence: visible 48px placeholder row (`__seq_placeholder_<id>`) with "Drop items here or tap to add" text; tapping opens add-item form with sequence pre-selected via `AddEditDailyItemView(initialParentSequenceId:)`
- [x] `TimerView` gains `autoAdvance: bool` param — auto-calls `_navigateToNextTask()` after 2s when timer completes; forwarded through `pushReplacement` chain; `_showSequenceTimer` passes `autoAdvance: seq.autoPlay`
- [x] `autoStart: bool` added to `DailyThing` (serialised, default `false`)
- [x] `TimerView` gains `autoStart` and `chainAutoStart` params — `autoStart` triggers `_toggleTimer()` on first frame; `chainAutoStart` propagates through the chain; `_navigateToNextTask` sets `autoStart: widget.chainAutoStart`
- [x] Sequence form: "Auto-start" `SwitchListTile` below "Auto-advance", greyed/disabled when Auto-advance is off; turning Auto-advance off forces Auto-start off
- [x] Sequence header chip matches normal item chip exactly: 90×35, blue+tick when done, red with "N ▶" when not; tapping launches sequence; left section gains collapse chevron + derived done icon
- [x] Child cards use `colorScheme.surfaceContainerHighest` background to visually distinguish from top-level items
