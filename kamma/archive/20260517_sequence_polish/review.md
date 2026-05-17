## Thread
- **ID:** 20260517_sequence_polish
- **Objective:** Sequence chip count + sequence graph tooltip + nag suppression for completed/in-progress items

## Files Changed
- `lib/src/views/daily_thing_item.dart` — orange chip now counts incomplete children, not total
- `lib/src/views/graph_view.dart` — sequence spot-builder synthesizes per-date HistoryEntry; tooltip uses it
- `lib/src/core/sequence_helper.dart` — added `isHandledToday` covering sequence + minutes/reps in-progress + any-type completed
- `lib/src/services/notification_service.dart` — `scheduleNotification` loads items + skips today when handled; `onItemCompleted` does full reschedule (covers parent-sequence rollover)

## Findings
No findings.

Notes verified during review:
- `scheduleNotification` called from `add_edit_daily_item_view.dart:868` runs after the item is saved, so internal `DataManager().loadData()` sees the new item.
- `rescheduleAllNotifications` passes `items` through, so the per-item `??` short-circuits — no N×N load.
- `sequenceCompletedForToday` returns true when not-due-today; in that case `skipToday=true` just rolls scheduling forward, which is correct (no notification was due anyway).
- `_nextWeekdayWithTime`'s `skipToday` advance is a no-op when today's weekday isn't selected; subsequent while-loop handles that case.

## Fixes Applied
None — no issues found during review.

## Test Evidence
- `flutter test --no-pub` → 71/71 pass
- Manual test by user → confirmed

## Verdict
PASSED
- Review date: 2026-05-17
- Reviewer: kamma (inline)

## Out-of-scope notice
- `lib/src/views/trend_input_dialog.dart` had a pre-existing uncommitted change (reordered comment field). Not touched.
