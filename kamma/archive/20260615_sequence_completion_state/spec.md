# Spec — Sequence Completion State

## Overview
A weekly sequence with three `check` children shows as completed
(blue) and then hides, even when only one of the three children is
done. It should only read as completed when **all** due children are
completed. Single-line root cause; small, behavior-preserving fix
plus the first tests for the sequence helpers.

## Project context (as discovered)
- `SequenceHelper` (lib/src/core/sequence_helper.dart) has three
  "state" helpers:
  - `sequenceShouldShowInList` → `children.any(shouldShowInList)`
    (purely child-driven; set this way in thread
    `20260515_sequence_polish_v2`, phase 7).
  - `sequenceIsUndoneToday` → `children.any(isUndoneToday)` (purely
    child-driven).
  - `sequenceCompletedForToday` → **gated on the sequence's own
    `seq.isDueToday`** before consulting children:
    ```dart
    if (!seq.isDueToday) return true;
    final children = resolveChildren(seq, allItems);
    if (children.isEmpty) return false;
    return children.every((child) => child.completedForToday);
    ```
- No code path ever writes a `HistoryEntry` to an
  `ItemType.sequence`. Verified across every history-writing site:
  `timer_view.dart`, `stopwatch_view.dart`, the check toggle in
  `daily_thing_item.dart`, and the reps / percentage / trend input
  dialogs. They all write to leaf items. A sequence's own `history`
  is therefore always empty, and its `isDueToday` is computed from a
  schedule (`intervalType` / `intervalWeekdays` / `startDate`) that
  nothing maintains.
- Consumers of `sequenceCompletedForToday`:
  - `daily_thing_item.dart:217` — the blue check / chip rendering.
  - `daily_things_view.dart:999` and `:1237` — completion-status
    aggregation.
  - `sequence_helper.dart::isHandledToday` — notification
    suppression.

## Root cause
`if (!seq.isDueToday) return true;` uses the sequence container's own
phantom schedule. For a weekday-based ("once a week") sequence, on
any day that is **not** the configured weekday, `seq.isDueToday` is
false, so the helper returns `true` (completed/blue) regardless of
child state. Meanwhile the children are carried over (due that week,
not all done) so the sequence is still shown — blue, with unfinished
children. The user perceives this as "completed one of three → turned
blue."

This also makes the three sequence-state helpers inconsistent:
visibility and undone-ness are child-driven, but completion consults
the sequence's own unreliable schedule.

## What it should do
- A sequence is "completed for today" only when **every resolved
  child** reports `completedForToday`. The sequence's own
  `isDueToday` must not short-circuit this.
- Children that are genuinely not due today still report
  `completedForToday == true`, so a child with a mismatched schedule
  does not wrongly block completion (unchanged from today's branch-2
  behavior).
- Resulting behavior:
  - 1 of 3 done → not completed → not blue, still shown.
  - 3 of 3 done → completed → blue; `sequenceIsUndoneToday` is false
    so `hideWhenDone` hides it until a child is next due.

## The fix
Drop the `seq.isDueToday` gate so completion is purely child-driven,
matching `sequenceShouldShowInList` and `sequenceIsUndoneToday`:

```dart
static bool sequenceCompletedForToday(
    DailyThing seq, List<DailyThing> allItems) {
  final children = resolveChildren(seq, allItems);
  if (children.isEmpty) return false;
  return children.every((child) => child.completedForToday);
}
```

## Assumptions & uncertainties
- The exact on-device item config isn't inspectable, but the
  mechanism is unambiguous from the code and holds across schedule
  combinations.
- Empty-children edge: previously returned `true` when the sequence
  wasn't due; now returns `false`. An empty sequence isn't a
  meaningful "completed" state, and this matches the existing
  `children.isEmpty → false` branch.

## Constraints
- Behavior-preserving outside the described change. No refactor of
  adjacent code.
- No new abstractions.

## How we'll know it's done
1. A weekly sequence with three check children, one done, renders
   not-completed (not blue) and stays visible.
2. The same sequence with all three done renders completed (blue)
   and is hidden by `hideWhenDone`.
3. New unit tests for `sequenceCompletedForToday` cover both cases.
4. `flutter test --no-pub` passes with no regressions.
