# Spec — Sequence chip shows total time when all children are countdown timers

## Overview
The orange chip on a sequence row in the items list currently shows `[incomplete child count] ▶`. When every child of the sequence is a countdown timer (`ItemType.minutes`), show the summed remaining time instead of the count. The play triangle stays. Mixed-type sequences keep current behavior unchanged.

## What it should do
- Resolve the sequence's children via `SequenceHelper.resolveChildren` (already done in the widget).
- If the list is non-empty AND every child has `itemType == ItemType.minutes`:
  - Sum `todayValue` of children where `!c.completedForToday`.
  - Format with `TimeConverter.toSmartString(sum)` and show it in place of the count, with the existing `Icons.play_arrow` to its right.
- Otherwise (mixed types, or no children, or any non-minutes child): unchanged — show incomplete-child count + play arrow.
- The `seqDone` branch (check icon) is unchanged.

## Affected files
- `lib/src/views/daily_thing_item.dart` (chip render block around lines 291–336)

## Assumptions & uncertainties
- "Countdown timer" = `ItemType.minutes` (the only countdown type; `stopwatch` counts up).
- "Sum of children" = sum of `todayValue` of children still incomplete today (per user clarification).
- An empty sequence keeps current behavior (count "0" + arrow).

## Constraints
- No model, helper, or persistence changes.
- No styling/size changes to the chip.

## How we'll know it's done
- Sequence with all-minutes children shows e.g. `12m ▶` instead of `3 ▶`.
- Sequence with at least one non-minutes child still shows `3 ▶`.
- `flutter test --no-pub` passes.

## What's not included
- Refactoring chip layout or extracting a helper.
- Changes to non-sequence chips.
