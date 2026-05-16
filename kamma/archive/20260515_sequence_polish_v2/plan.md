# Plan — Sequence Polish v2

## Architecture Decisions
- Data model additions go on `DailyThing` (not a side struct); two
  optional fields with sensible defaults, persisted via JSON.
  Matches existing pattern for `bellSoundPath`,
  `subdivisionBellSoundPath`, `autoPlay`, etc.
- `chainDelaySeconds` lives on the **sequence**, not on each child.
  The user described it as "one of the settings of a sequence."
- `startBellSoundPath` lives on each **item**, mirroring how end
  bell and subdivision bell already work — same field type, same
  picker dialog.
- Cascade archive uses a single `saveData(items)` round-trip rather
  than N `updateDailyThing` calls to keep the flip atomic and avoid
  re-reading the file repeatedly.
- Sequence sum-graph is computed inline in `GraphView` /
  `MiniGraphWidget` by branching on `itemType == sequence`. No new
  abstraction; the existing `_buildSpots` becomes a small dispatch.
- Bell group lives in one shared widget block inside
  `add_edit_daily_item_view.dart` to enforce identical layout.

## Phase 1 — Data model: `chainDelaySeconds` + `startBellSoundPath`
- [x] Add `final int chainDelaySeconds;` (default `20`) and
      `final String? startBellSoundPath;` to `DailyThing`
      constructor, `toJson`, `fromJson` (with backwards-compatible
      defaults), and `copyWith`.
      → verify: `flutter analyze` is clean; existing serialized JSON
        loads without error (mentally trace `fromJson` defaults).

## Phase 2 — Per-sequence delay setting + timer wiring
- [x] In `add_edit_daily_item_view.dart`, inside the existing
      `Sequence Options` block (~line 1181), add a two-field
      "Delay between items" row (minutes + seconds). Parse on
      submit and pass `chainDelaySeconds` into the saved
      `DailyThing`. Style identically to other numeric inputs in
      that block.
      → verify: edit a sequence, set delay 0m30s, save, re-open;
        the values persist.
- [x] In `daily_things_view.dart::_showSequenceTimer`, pass
      `chainDelaySeconds` through to `TimerView` (new constructor
      param). In `timer_view.dart::_onTimerComplete`, replace the
      hard-coded `Duration(seconds: 10)` with
      `Duration(seconds: widget.chainDelaySeconds)`. Default the
      new param to `20` so non-sequence callers don't break.
      → verify: chained sequence run waits exactly the configured
        delay; non-chained timers behave as before.

## Phase 3 — Cascade archive
- [x] In `daily_thing_item.dart::_archiveItem`, when the item is a
      sequence, load `dataManager.loadData()`, flip `isArchived`
      on the sequence and every item whose id is in
      `item.childIds`, then `saveData(items)`. Same for unarchive.
      Non-sequence items keep the existing single-item path.
      → verify: archive a 3-child sequence → toggle "show archived"
        → sequence and all three children appear archived;
        unarchive flips them all back together.

## Phase 4 — Per-item start bell
- [x] Add `AudioHelper.playStartBell(item)` that plays
      `item.startBellSoundPath` if non-null (mirror the existing
      `playTimerCompleteNotification` plumbing).
- [x] In `timer_view.dart`:
      - `initState`, when `widget.autoStart` is true: call
        `_audioHelper.playStartBell(_currentItem)`.
      - Manual start path (`_toggleTimer` first-press, where
        `_hasStarted` flips true): also call `playStartBell`.
- [x] In `add_edit_daily_item_view.dart`, replace the existing
      ad-hoc bell field + the subdivision bell row with a single
      **Bells** section. Rows by type:
      - `minutes`: Start, End, Subdivision (3 rows)
      - `stopwatch`: Start, Subdivision (2 rows)
      Each row uses `_buildBellPicker` — identical layout for all.

## Phase 5 — Collapse-all cascades to children
- [x] In `daily_things_view.dart::_expandAllVisibleItems`, expand
      the input list passed to `toggleExpansionForVisibleItems` to
      include every child returned by
      `SequenceHelper.resolveChildren(seq, _dailyThings)` for each
      visible sequence.

## Phase 6 — Sequence sum graphs
- [x] `MiniGraphWidget` accepts optional `allItems`; when item is
      a sequence, sums children's per-day values in
      `_buildSequenceSpots`.
- [x] `GraphView` accepts optional `allItems`; same dispatch in
      `_buildSpots` + `_buildSequenceSpots`. `_getFilteredDates`
      uses merged children's history for date-range calculation.

## Phase 7 — Hide sequence when no due children
- [x] `sequence_helper.dart::sequenceShouldShowInList` →
      `resolveChildren(seq, allItems).any((c) => c.shouldShowInList)`

## Phase 8 — Copy-inside-sequence stays inside
- [x] `daily_things_view.dart::_duplicateItem`: after inserting the
      clone at `originalIndex + 1`, find parent sequence via
      `SequenceHelper.findParentSequence`, and if found, splice the
      clone's id into the parent's `childIds` right after the
      original.

## Phase 9 — Verification
- [x] `flutter analyze` → zero issues (confirmed after each phase).
- [ ] Manual sanity check by user.
