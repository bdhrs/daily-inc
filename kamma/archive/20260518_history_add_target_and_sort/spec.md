# Spec — Backdated history entry: auto-fill target & re-sort

## Overview
The History editor (`lib/src/views/history_view.dart`) lets the user add a
backdated entry via the `+` toolbar button. Two long-standing rough edges:
the target value must be typed by hand, and the new row is inserted at the
top of the list regardless of its date. This thread fixes both.

## What it should do
1. When the user taps `+` to add a new entry, the **Target** field should
   pre-fill with the value the progression formula would have produced for
   the entered date (using the item's startValue, endValue, duration, and
   startDate via `IncrementCalculator`). The field stays editable so the
   user can override.
2. The target field should update whenever the user edits the date in the
   add-row.
3. After the user confirms the add, `_history` should be re-sorted by date
   descending (same order as the initial load at line 45) so the new row
   lands in the correct chronological position.

## Assumptions & uncertainties
- The formula to use is `startValue + increment * daysSinceStart`, clamped
  to `[startValue, endValue]` — same shape as `HistoryManager`
  lines 46–53 and `IncrementCalculator.calculateTodayValue`.
- For non-numeric types (CHECK, TREND, PERCENTAGE, REPS, STOPWATCH,
  SEQUENCE) the formula may not be meaningful. Current plan: keep the
  existing manual entry for those types and only auto-fill for MINUTES
  and REPS-style numeric progressions. Will confirm by checking which
  ItemTypes actually surface the History editor with editable targets.
- "Sorted descending" matches the existing load-time order; if the user
  prefers ascending we'd flip both this sort and line 45.

## Constraints
- Don't change the JSON shape of `HistoryEntry` or how data is persisted.
- Don't touch the in-row editing of existing entries' target values —
  scope is the **add new entry** flow only.
- Don't refactor history_view; minimal, surgical edits.

## How we'll know it's done
- Open an item's history, tap `+`, enter a past date → Target field
  populates automatically with the projected value for that date.
- Edit the date in the add-row → Target field updates.
- Tap the inline check to confirm the add → the new row sorts into the
  correct chronological position immediately (no save+reopen needed).
- `flutter test --no-pub` passes.

## What's not included
- No change to existing-entry editing.
- No change to the load-time sort order.
- No new helper for non-numeric progression types.
