# Plan — Sequence Polish

## Architecture Decisions
- Clone children inline in `_duplicateItem` (single caller; no helper).
- Wakelock continuity: re-enable in next TimerView.initState (runs
  before old.dispose under pushReplacement).
- Start bell from postFrame in initState, not inside `_toggleTimer`.

## Phase 1 — Copy sequence with children
- [ ] Branch `_duplicateItem` on sequence type; clone children with
      new ids and empty history; rebuild sequence's `childIds`; insert
      sequence then children after original index; single saveData.
      → verify: 3-item sequence duplicate yields a new sequence with
        3 fresh children; originals unchanged.

## Phase 2 — Add-in-sequence wiring
- [ ] In add/edit submit path, re-fetch the parent sequence by id via
      `dataManager.loadData()` (don't rely on the possibly-empty
      `_allDailyThings` cache) before appending the new child id.
      → verify: tap placeholder, create new item, save; item is a
        child of the sequence on return.

## Phase 3 — 10s chain delay
- [ ] `timer_view.dart::_onTimerComplete`: 2s → 10s.
      → verify: ~10s pause between chained items.

## Phase 4 — Wakelock across chain
- [ ] `initState`: if `widget.autoStart`, call `WakelockPlus.enable()`
      synchronously.
- [ ] `_navigateToNextTask`: drop the `WakelockPlus.disable()` call.
      → verify: screen does not blank between chained items.

## Phase 5 — Start bell on auto-start
- [ ] `initState` postFrame: if `widget.autoStart`, call
      `_audioHelper.playTimerCompleteNotification(_currentItem)`
      before `_toggleTimer()`.
      → verify: bell audible when next item begins.

## Phase 6 — Hide alarm row when notifications off
- [ ] In `daily_thing_item.dart`, gate both alarm-row guards on
      `notificationEnabled && nagTime != null`.
      → verify: item with notifications off shows no alarm row.

## Phase 7 — Verification
- [ ] `flutter analyze` → zero errors.
