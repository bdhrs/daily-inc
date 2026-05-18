## Thread
- **ID:** 20260518_history_add_target_and_sort
- **Objective:** Auto-fill projected target and chronologically re-sort when adding a backdated history entry.

## Files Changed
- `lib/src/core/increment_calculator.dart` — added `valueForDate(item, date)` helper for the pure formula value on an arbitrary day.
- `lib/src/views/history_view.dart` — pre-fill target on add, refresh on date change (preserving manual overrides), re-sort `_history` after insert.

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | nit | `history_view.dart:_maybeAutoFillTarget` | Override detection uses exact string equality against last auto-fill | If user re-types the exact same number, treated as "still auto" | Acceptable — re-typing the same value yields the same state, no user-visible difference |

No blocking or major findings.

## Fixes Applied
- None (review surfaced no actionable issues).

## Test Evidence
- `flutter test --no-pub` → 71/71 pass
- Manual user test confirmed: auto-fill on open, refresh on date change, manual override preserved, re-sort lands in correct position.

## Verdict
PASSED
- Review date: 2026-05-18
- Reviewer: kamma (inline)
