# Plan — Per-item Auto-start

## Phase 1: Make the flag survive

- [x] `timer_view.dart:845` — replace `_createUpdatedItem` body with
      `_currentItem.copyWith(history: updatedHistory)`
      → verify: `flutter analyze` clean
- [x] `stopwatch_view.dart:484` — same replacement
      → verify: `flutter analyze` clean
- [x] `daily_thing.dart:37` — update the `autoStart` doc comment: per-item flag,
      no longer sequence-only
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 2: Per-item auto-start plumbing

- [x] `stopwatch_view.dart` — add `final bool autoStart` (default `false`) to
      `StopwatchView` and its constructor
- [x] `stopwatch_view.dart` `initState` — when `widget.autoStart`, post-frame
      `if (_isPaused) _toggleStopwatch();`
- [x] `timer_view.dart` — delete the `chainAutoStart` field and constructor param
- [x] `timer_view.dart` `_navigateToNextTask` — pass
      `autoStart: widget.autoAdvance && nextTask.autoStart`, drop `chainAutoStart`
- [x] `daily_things_view.dart` `_showFullscreenTimer` — pass `autoStart: item.autoStart`
- [x] `daily_things_view.dart` `_showFullscreenStopwatch` — pass `autoStart: item.autoStart`
- [x] `daily_things_view.dart` `_showSequenceTimer` — pass
      `autoStart: firstUndone.autoStart`, remove `chainAutoStart`
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 3: Form

- [x] `add_edit_daily_item_view.dart` — add an ungated `Auto-start` SwitchListTile
      for `minutes` and `stopwatch`, after the interval selector
- [x] `add_edit_daily_item_view.dart` — sequence Auto-start switch: remove the
      Auto-advance gate (greyed styling, `onChanged: null`, and the
      `if (!v) _autoStart = false` clearing in the Auto-advance handler)
- [x] `add_edit_daily_item_view.dart` `_submitDailyItem` — write
      `autoStart: _autoStart` for `sequence`/`minutes`/`stopwatch`, `false` otherwise
- [x] `add_edit_daily_item_view.dart` `_submitDailyItem` — after the existing
      child-stealing sweep, propagate a *changed* sequence `_autoStart` to
      time-based children (reload from storage, `copyWith(autoStart:)` each)
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 5: Review fixes (from independent review + CodeRabbit)

- [x] `timer_view.dart` — guard auto-start with `!_hasStarted` so tapping an
      item already finished today no longer starts an overtime clock that
      `_saveProgress` persists (review finding 2, major)
- [x] `stopwatch_view.dart` — guard auto-start with `_elapsedSeconds == 0`; also
      prevents a subdivision bell firing on the first tick against restored
      elapsed time (review findings 2 and 6)
- [x] `timer_view.dart` — drop the `widget.autoAdvance &&` gate on the chained
      `autoStart`; it contradicted spec reqs 2 and 4 on the manual next-arrow
      path (review finding 3)
- [x] `add_edit_daily_item_view.dart` — add `_isTimeBased`, use it for the
      propagation loop and the build guard so a nested sequence can never be
      written non-recursively (review findings 4 and 10)
- [x] `daily_thing.dart` — reword the `autoStart` comment to "timing session";
      it drives StopwatchView too, not only a timer (CodeRabbit)
- [x] Upgrade regression for existing Auto-start sequences (review finding 1,
      major) — resolved in code: the change-detection gate is dropped, so every
      sequence save re-asserts Auto-start onto its time-based children. Also
      resolves finding 7 (the switch could show a value no child held).
      Supersedes the earlier "manual re-toggle" decision; rationale in `spec.md`.
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 4: Verify

- [x] `flutter analyze` clean
- [x] `flutter test --no-pub` — full suite green (note any pre-existing failures
      from the baseline)
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
