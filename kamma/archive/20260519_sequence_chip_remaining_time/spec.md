# Spec — Sequence chip shows remaining time when all children are countdown timers

## Overview
The orange chip on a sequence row currently shows the sum of children's `todayValue` (full daily target) for incomplete children when every child is a countdown timer. Change it to show the *remaining* time: completed children contribute 0; partially-completed children contribute only their remaining minutes (`todayValue - actualValue`).

## What it should do
For all-minutes sequences, compute the chip label as the sum across children of:
- 0 if `child.completedForToday`
- otherwise `max(0, child.todayValue - (child.todayHistoryEntry?.actualValue ?? 0))`

Format with `TimeConverter.toSmartString(sum)` followed by the existing play arrow. Mixed-type and `seqDone` branches are unchanged.

## Affected files
- `lib/src/views/daily_thing_item.dart` (chip render block ~lines 315–327)

## Assumptions & uncertainties
- `actualValue` is stored in minutes (same unit as `todayValue`) — confirmed via `lib/src/views/helpers/timer_state.dart:51` where `completedMinutes = todayEntry.actualValue ?? 0.0` is compared against `dailyTarget` (minutes).
- Partially-complete = a history entry for today with `actualValue > 0` but `doneToday == false`; `!completedForToday` catches this.
- Clamp per-child at 0 to defend against floating-point edge cases.

## Constraints
- No model, helper, or persistence changes.
- No styling/size changes to the chip.
- Mixed-type sequence chip behavior unchanged.

## How we'll know it's done
- All-minutes sequence with one child fully done (10m) and one untouched (5m) shows `5m ▶`.
- Child with 10m target and `actualValue` 4m contributes `6m`.
- All children done → existing `seqDone` check-icon branch, unchanged.
- Mixed-type sequence still shows incomplete-child count.
- `flutter test --no-pub` passes.

## What's not included
- Refactoring chip layout or extracting a helper.
- Live updates during an active timer (chip recomputes on next rebuild, same as today).
