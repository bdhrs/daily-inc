# Plan — Default items for a fresh install

## Architecture Decisions
- Defaults live in `assets/default_items.json`, in the store's own
  `{"dailyThings": [...], "meta": {}}` shape, so `Save Template` can regenerate
  them and no bespoke reader is needed.
- The seed is a **verbatim text copy** of the asset into the store path. No
  parsing, no object construction, no `startDate` stamping — an untouched item's
  target clamps to `startValue` regardless of how old its `startDate` is
  (`increment_calculator.dart:229-242`). No new Dart file is created.
- Seed hook is in `DataManager.loadData()`, guarded on `File.existsSync()` rather
  than on the `{}` from `_readRawStore()`; that value also means "read failed",
  and seeding then would overwrite real data. The write sits above the read so
  the read's error path can never reach it.
- `daily_things_view._resetAllData()` gets smaller, not bigger: the redundant
  second `resetAllData()` and the dead try/catch go, leaving a delete, an
  explicit list clear, and a reload. Net deletion in the view.
- `settings_view.dart` is untouched.

## Phase 1: The defaults asset
- [x] Create `assets/default_items.json` with the 9 items from the spec table —
      readable fixed ids, sequence `childIds` pointing at the Stretch and
      Breathing ids, empty `history`, a past `startDate`, and
      startValue 0.0 / duration 1 / endValue 0.0 for
      check / percentage / trend / stopwatch / sequence
  → verify: `python3 -m json.tool assets/default_items.json` parses
- [x] `pubspec.yaml` — add `- assets/default_items.json` to the existing
      `flutter: assets:` list (do NOT touch the `version:` line)
  → verify: `flutter pub get` succeeds
- [x] Create `test/default_items_test.dart` — reads the real shipped asset from
      disk with `dart:io` (no binding needed) and asserts: 9 items; each
      `ItemType` appears exactly once among non-child items; every `icon`
      non-empty; `SequenceHelper.resolveChildren(...)` returns 2; every `history`
      empty; every item `isDueToday`; Meditation's `todayValue` is 5.0
  → verify: `flutter test --no-pub test/default_items_test.dart`, all pass
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 2: Seed on first load and after reset
- [x] `data_manager.dart` `loadData()` — if the store file does not exist, copy
      `rootBundle.loadString('assets/default_items.json')` to it, logged, in a
      try/catch that degrades to the current empty-list behavior; then fall
      through to the existing read
  → verify: `flutter analyze` clean; confirm by reading that the write precedes
    `_readRawStore()` and is guarded by `existsSync`
- [x] `daily_things_view.dart:773` `_resetAllData()` — reduce the body to
      `resetAllData()` → clear the list → `_loadData()`, dropping the redundant
      second delete and the try/catch around calls that already log their own
      failures
  → verify: `flutter analyze` clean; trace that `_loadData()` sets state and
    re-reads the sequence expansion prefs
  → DRIFT: the `setState(() => _dailyThings = [])` was KEPT, not dropped.
    `_loadData()`'s empty branch deliberately does not wipe state (so a transient
    read error can't blank the UI), so without the explicit clear a failed seed
    would leave the old items on screen after a reset.
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 3: Full verification
- [x] `flutter analyze` — clean
- [x] `flutter test --no-pub` — full suite green (baseline was 76 passing)
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
