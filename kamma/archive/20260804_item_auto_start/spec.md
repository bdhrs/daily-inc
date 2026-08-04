# Spec — Per-item Auto-start

## Goal

Auto-start becomes a property of the **individual item**, not of the sequence.
A sequence's Auto-start switch becomes a bulk setter that writes the value down
to its children.

## Requirements

1. Every time-based item — Countdown Timer (`minutes`) and Stopwatch
   (`stopwatch`) — gets an **Auto-start** toggle in the add/edit form.
   Non-time types (`reps`, `check`, `percentage`, `trend`) do not: there is no
   clock to start.
2. When an item with Auto-start on is opened, its timer/stopwatch starts
   running immediately, with no tap.
3. A sequence's Auto-start is authoritative for its time-based children: on
   **on** they all become on, on **off** they all become off. Every save of the
   sequence re-asserts it, not only a save where the switch changed.
4. Auto-start inside a sequence chain is driven by each item's own flag.

## Current state (verified by reading)

- `DailyThing.autoStart` already exists, is serialised, and is in `copyWith`.
  It is documented as sequence-only.
- `add_edit_daily_item_view.dart` shows the Auto-start switch only under
  "Sequence Options", greyed out and force-cleared unless Auto-advance is on;
  on submit it writes `autoStart: type == sequence ? _autoStart : false`.
- `daily_things_view.dart`
  - `_showSequenceTimer` passes `autoStart: seq.autoPlay && seq.autoStart` and
    `chainAutoStart: seq.autoPlay && seq.autoStart`.
  - `_showFullscreenTimer` and `_showFullscreenStopwatch` pass no auto-start.
- `timer_view.dart` has both `autoStart` (start me now) and `chainAutoStart`
  (propagate to the next item); `_navigateToNextTask` forwards
  `autoStart: widget.chainAutoStart`.
- `StopwatchView` has no auto-start param at all.
- **Latent bug:** `_createUpdatedItem` in *both* `timer_view.dart:845` and
  `stopwatch_view.dart:484` rebuilds the item field-by-field and omits
  `autoStart` (also `autoPlay`, `childIds`, `chainDelaySeconds`). Today that is
  invisible because non-sequence items never carried `autoStart`. Once they do,
  running a timer once silently clears the user's flag. Must be fixed for this
  feature to work at all.
- No test references `autoStart` or `chainAutoStart`.

## Design

### Model
No structural change. Only the doc comment on `DailyThing.autoStart` is updated
— it is no longer sequence-specific.

### Form (`add_edit_daily_item_view.dart`)
- Add an ungated `Auto-start` `SwitchListTile` for `minutes` and `stopwatch`
  types, placed directly after the interval selector.
  Subtitle: `Start the timer automatically when opened`.
- Submit writes `autoStart: _autoStart` for `sequence`, `minutes` and
  `stopwatch`; `false` for all other types.
- Remove the Auto-advance gate on the sequence's Auto-start switch (the
  greyed-out styling and the `if (!v) _autoStart = false` clearing).
  Rationale: the switch is now a bulk setter for children that auto-start on
  their own, so gating it would mean "turn Auto-advance off" silently
  propagates Auto-start **off** to every child — a destructive surprise.
- After the sequence's own save and the existing child-stealing sweep,
  propagate on **every** sequence save (no change-detection gate):
  reload items from storage, and for each id in `_childIds` that is time-based
  (`_isTimeBased` — `minutes` or `stopwatch`, deliberately *not*
  `_supportsAutoStart`, which includes `sequence` and would write a flag to a
  nested sequence non-recursively), save
  `child.copyWith(autoStart: _autoStart)`.

### Launch sites (`daily_things_view.dart`)
- `_showFullscreenTimer` → `autoStart: item.autoStart`.
- `_showFullscreenStopwatch` → `autoStart: item.autoStart`.
- `_showSequenceTimer` → `autoStart: firstUndone.autoStart`,
  `chainAutoStart` removed (see below).

### Chain (`timer_view.dart`)
- Delete the `chainAutoStart` param. It is now identical to `autoAdvance` at
  every call site, so it does not need to exist.
- `_navigateToNextTask` passes `autoStart: nextTask.autoStart`. It is **not**
  gated on `autoAdvance`: `_navigateToNextTask` is also reached from the manual
  next-arrow, and gating there would mean an item with Auto-start on does not
  auto-start — contradicting requirements 2 and 4.

### Auto-start must only fire for a fresh session
Auto-start starts a clock without the user touching anything, so it must not
resume an item that already ran today.
- `TimerView`: `if (_isPaused && !_hasStarted) _toggleTimer();`
  `TimerStateHelper.initializeTimerState` returns `hasStarted: true` for an
  item finished earlier today (`timer_state.dart:27,57`), which is also the
  `startInOvertime` path reached by tapping a completed item. Without the
  guard, opening a finished item silently accumulates overtime and
  `_saveProgress` persists the inflated `actualValue`. Chained and
  freshly-opened items always have `hasStarted == false`, so every intended
  case survives.
- `StopwatchView`: `if (_isPaused && _elapsedSeconds == 0) _toggleStopwatch();`
  `_initializeState` restores `_elapsedSeconds` from today's accumulated
  value. The guard also avoids a spurious subdivision bell: with restored
  elapsed time, `_lastTriggeredSubdivision` (`-1`) is already behind
  `floor(elapsed / interval)`, so the first 100 ms tick would ring a bell with
  no user action.

### Stopwatch (`stopwatch_view.dart`)
- Add `final bool autoStart` (default `false`).
- In `initState`, when `autoStart` is true, `addPostFrameCallback` with the
  fresh-session guard above. `_toggleStopwatch` handles wakelock, dimming and
  fade itself, and the stopwatch has no *start* bell, so there is no
  start-bell double-fire risk.

### Persistence fix
Replace both `_createUpdatedItem` bodies with
`_currentItem.copyWith(history: updatedHistory)`. This preserves `autoStart`
and every other field. `actualTodayValue` is a non-final field absent from both
the constructor and `copyWith`, so it is dropped either way — no change in
behaviour there.

## Behaviour changes to be aware of

- A sequence's first item now auto-starts based on its own flag even when
  Auto-advance is off. Previously auto-start required Auto-advance. No existing
  data is affected: `autoStart` was only ever set on sequences, and sequences
  do not open a timer view themselves.
- **Upgrade regression (accepted, handled manually).** A sequence that has
  Auto-advance + Auto-start on *today* loses auto-start, because auto-start now
  reads the child's flag and no child has ever had it set. Propagation does not
  self-heal this: it is gated on the sequence's own flag *changing*, and
  reopening the form shows the switch already on and equal to the stored value,
  so a plain save propagates nothing. Recovering it requires toggling the
  switch off, saving, on, saving.

  Decision (user, 2026-08-04, superseding an earlier choice of a manual
  re-toggle): drop the change-detection gate so every sequence save re-asserts
  the flag onto its children. This self-heals the upgrade case — one plain save
  of an affected sequence fixes it — and makes the switch's subtitle true.
  Accepted cost: the sequence is authoritative, so a deliberate per-child
  difference ("first item manual, rest auto-start") lasts only until the next
  save of that sequence. A one-shot `DataManager` migration was also rejected
  as permanent code that mutates stored data on load for a one-time transition.

## Out of scope

- `_showSequenceTimer` puts `stopwatch` children into `TimerView`, and
  `_navigateToNextTask` ends the chain on any non-`minutes` item. That
  pre-existing oddity is untouched.
- No new toggle for non-time item types.

## Assumptions

- "Any time related tasks" means exactly `minutes` and `stopwatch`.
- Propagation applies only to time-based children; storing a dead flag on a
  checkmark child would be noise.

## Confidence

8/10 — the code paths are all read and the change is small. The one judgement
call is dropping the Auto-advance gate on the sequence switch, which is
argued above.
