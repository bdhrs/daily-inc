# Plan — Backdated history entry: auto-fill target & re-sort

## Architecture Decisions
- Reuse `IncrementCalculator` math rather than duplicating; if no public
  "value for arbitrary date" helper exists, add a small static
  `valueForDate(DailyThing item, DateTime date)` next to
  `calculateTodayValue` so the logic lives in one place.
- Drive the auto-fill via a listener on `_newDateController` (the file
  already adds one at line 57), so target updates as the user types the
  date. User edits to target are preserved by only auto-filling when the
  target field is empty or matches the previously-computed value (so a
  manual override isn't clobbered on every keystroke).
- Re-sort inside the existing `setState` block at `history_view.dart:231`,
  immediately after `_history.insert(0, newEntry)`.

## Phase 1 — Auto-fill target on add
- [ ] Add `IncrementCalculator.valueForDate(DailyThing, DateTime)`
  (or confirm an equivalent already exists and reuse).
  → verify: `flutter test --no-pub` passes; new unit test covers
  start-date, mid-progression, post-end clamping.
- [ ] In `history_view.dart`, when `_startAddingEntry` runs, parse the
  default date and pre-fill `_newTargetValueController` using
  `valueForDate`.
  → verify: open history, tap `+`, target field shows the formula value
  for today.
- [ ] Extend the existing `_newDateController` listener (line 57) to
  recompute and update the target whenever the date parses cleanly and
  the user hasn't manually overridden the target.
  → verify: tap `+`, change date to 5 days ago, target updates to the
  projected value for that day.

## Phase 2 — Re-sort on add
- [ ] In `_addNewEntry` (around line 231), after `_history.insert(0, …)`
  add `_history.sort((a, b) => b.date.compareTo(a.date));` so the row
  lands chronologically.
  → verify: add an entry dated 3 days ago between two existing entries —
  it appears in the correct position without saving/reopening.

## Phase 3 — Regression sweep
- [ ] Run full test suite.
  → verify: `flutter test --no-pub` all green.
- [ ] Manual smoke test on Linux build: add today's entry, add backdated
  entry, override target manually, delete entry, save & reopen.
  → verify: all flows behave as described; no console errors.
