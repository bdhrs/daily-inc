# Plan — Sequence polish

## Architecture Decisions
- Single helper `SequenceHelper.isHandledToday(item, allItems)` covers both sequence and non-sequence completed/in-progress detection. Avoids duplicating switch-on-type logic.
- `NotificationService` loads `allItems` internally via `DataManager` rather than threading through 4 callsites.
- `onItemCompleted` calls `rescheduleAllNotifications(loadedItems)` — covers child-completes-parent-sequence-done case for free.
- `_buildSequenceSpots` refactored to return `(spots, history)` record — single pass over children.
- Remove `_hasIncompleteProgress` from `daily_thing_item.dart` (moved into helper).

## Phase 1 — Orange chip count
- [ ] Replace `'${seqChildren.length}'` at `lib/src/views/daily_thing_item.dart:320` with count of children where `!completedForToday`
  → verify: open sequence parent with 3 children, mark 1 done → chip shows "2"

## Phase 2 — Sequence graph tooltip
- [ ] Refactor `_buildSequenceSpots` in `lib/src/views/graph_view.dart` to return both spots and a synthesized `List<HistoryEntry>` (one entry per date, summed `actualValue` and `targetValue`)
- [ ] Pass synthesized history to `buildTouchTooltipData` instead of `widget.dailyThing.history`
  → verify: long-press bar on a sequence graph → date and summed actual value shown

## Phase 3 — Nag suppression
- [ ] Add `static bool SequenceHelper.isHandledToday(DailyThing item, List<DailyThing> allItems)` covering sequence + non-sequence cases
- [ ] In `lib/src/services/notification_service.dart`: `scheduleNotification` loads items via `DataManager`, checks `isHandledToday`, skips today in both byWeekdays and byDays branches
- [ ] Replace `onItemCompleted` body with `rescheduleAllNotifications(await DataManager().loadData())`
- [ ] Remove `_hasIncompleteProgress` from `daily_thing_item.dart`
  → verify: complete a sequence → no nag today; start a sequence → no nag; complete a minutes item → no nag; start a minutes item (timer >0 not done) → no nag

## Phase 4 — Validate
- [ ] `flutter test --no-pub` passes
