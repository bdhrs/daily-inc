# Review — Sequence Completion State

## Outcome
**Verdict: PASSED.** Verified on device by the user — solves the
reported problem.

## What changed
- `lib/src/core/sequence_helper.dart`: removed the
  `if (!seq.isDueToday) return true;` gate from
  `sequenceCompletedForToday`. Completion is now purely
  child-driven (`children.every((c) => c.completedForToday)`),
  consistent with `sequenceShouldShowInList` and
  `sequenceIsUndoneToday`.
- `test/sequence_completion_test.dart` (new): first tests for the
  sequence-state helpers. 5 cases, including a regression guard for
  the original bug (sequence not due by its own weekday schedule
  with carried-over undone children).

## Root cause (confirmed)
Sequences never accrue `HistoryEntry` records — verified across
every history-writing site (`timer_view`, `stopwatch_view`, the
check toggle in `daily_thing_item`, and the reps / percentage /
trend dialogs). The sequence container's own `isDueToday` is
therefore computed from an unmaintained schedule. For a weekday
("once a week") sequence, on any non-scheduled day `seq.isDueToday`
was false, so `sequenceCompletedForToday` returned `true` (blue)
regardless of child state, while the children stayed visible as
carried-over and undone.

## Verification
- `flutter analyze lib/src/core/sequence_helper.dart` → no issues.
- `flutter test --no-pub test/sequence_completion_test.dart` → 5/5.
- `flutter test --no-pub` (full suite) → 76 tests, 0 failures.

## Risk / blast radius
Four consumers of `sequenceCompletedForToday`
(`daily_thing_item` rendering, two aggregation sites in
`daily_things_view`, and `isHandledToday` for notifications) now
reflect actual child progress. Behavior only changes in the
previously-buggy case (sequence not due by its own schedule with
undone children); all other paths are unchanged because that gate
could only ever return `true`.

## Follow-ups (not in scope)
- Sequences carry schedule fields (`intervalType`, `startDate`,
  etc.) that are never used meaningfully. A future cleanup could
  hide or remove these from the sequence editor to avoid confusion,
  but that is a separate UX change.
