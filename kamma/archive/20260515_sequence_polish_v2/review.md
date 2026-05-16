## Thread
- **ID:** 20260515_sequence_polish_v2
- **Objective:** Seven follow-on improvements to the Sequence feature (chain delay, cascade archive, per-item start bell, collapse-all, sum graphs, hide-when-no-due-children, copy-stays-in-sequence)

## Files Changed
- `lib/src/models/daily_thing.dart` — added `chainDelaySeconds` (int, default 20) and `startBellSoundPath` (String?)
- `lib/src/core/sequence_helper.dart` — `resolveChildren` includeArchived param; empty-list guards on `isUndoneToday`, `completedForToday`, `shouldShowInList`; children-driven visibility
- `lib/src/views/helpers/audio_helper.dart` — added `playStartBell(item)`
- `lib/src/views/timer_view.dart` — `chainDelaySeconds` param replaces hardcoded 10s; start bell on first toggle; field preserved in `_createUpdatedItem`
- `lib/src/views/daily_thing_item.dart` — cascade archive for sequences; `isCardExpanded` prop for sequence ExpansionTile; `allItems` passed to GraphView and MiniGraphWidget
- `lib/src/views/daily_things_view.dart` — sequence timer filters to timer-compatible children; `chainDelaySeconds` wired; `_duplicateItem` keeps clone in parent sequence; expand-all fixed for two-map state; `_persistSequenceExpandedStates` added; `nextUndoneIndex` guard fixed
- `lib/src/views/add_edit_daily_item_view.dart` — "Delay between items" min/sec fields; unified Bells section with `_buildBellPicker`; `startBellSoundPath` saved
- `lib/src/views/graph_view.dart` — `allItems` param; `_buildSequenceSpots` sums children; `_getFilteredDates` uses merged child history
- `lib/src/views/widgets/mini_graph_widget.dart` — same sequence-sum dispatch; passes `allItems` to GraphView on tap
- `lib/src/views/widgets/graph_mixin.dart` — Y-axis label uses `toStringAsFixed(1)` when interval < 1
- `lib/src/views/widgets/reorder_helpers.dart` — full rewrite: row-position-based algorithm, placeholder awareness, correct same-sequence and cross-container moves
- `lib/src/views/widgets/filtering_helpers.dart` — no direct change (logic changes went through SequenceHelper)
- `lib/src/core/value_converter.dart` — `startBellSoundPath` preserved
- `lib/src/views/stopwatch_view.dart` — `startBellSoundPath` preserved in `_createUpdatedItem`
- `justfile` — added `android-install-offline` recipe

## Findings

| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | blocking | `daily_things_view.dart:1241` | `nextUndoneIndex < length` doesn't guard against -1 — crashes when list non-empty and all done | `displayedItems[-1]` throws RangeError | Changed to `nextUndoneIndex >= 0` |
| 2 | minor | `timer_view.dart:347-351` | autoStart path called `playStartBell` then `_toggleTimer` which also called it (since `_hasStarted` still false) — start bell played twice per chained item | Audibly wrong; user hears double bell on every auto-chain | Removed explicit call; `_toggleTimer`'s `!_hasStarted` guard handles it |

## Fixes Applied
- Fixed `nextUndoneIndex >= 0` guard (pre-existing bug, blocked smoke test)
- Removed duplicate `playStartBell` call from autoStart `postFrameCallback`

## Test Evidence
- `flutter analyze --no-pub` → No issues found
- `flutter test --no-pub` → 60 passed, 0 failed (was 59 passed, 1 failed before fix #1)
- CodeRabbit → unavailable (not connected to org)

## Verdict
PASSED
- Review date: 2026-05-16
- Reviewer: kamma (inline, same agent as implementation)
