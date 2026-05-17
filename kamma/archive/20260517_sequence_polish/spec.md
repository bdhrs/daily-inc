# Spec — Sequence polish

## Overview
Four behavior fixes spanning sequence display, sequence graph tooltip, and nag-notification suppression.

## What it should do
1. Sequence parent collapsed chip (orange box) shows count of *incomplete* children, not total children.
2. Sequence graph long-press tooltip shows the date and summed actual value (bar height is already correct; only the tooltip data is broken).
3. Nag notifications do not fire for items that are already completed today.
4. Nag notifications do not fire for items actively in-progress today.
5. Rules 3–4 apply to all item types, not just sequences.

## Assumptions & uncertainties
- Nag is only delivered as a notification (confirmed by user and grep — no in-app nag widget exists).
- Sequence items may have a `nagTime` configured (add/edit form exposes `nagMessage` for all types).
- "In-progress" definitions reused from existing `_hasIncompleteProgress` in `daily_thing_item.dart`:
  - minutes: `actualValue > 0 && !doneToday`
  - reps: `actualValue != null && !doneToday`
  - other single-shot types (check/percentage/trend/stopwatch): only the "completed" branch applies.
- For sequences, in-progress = any child has progress today AND not all children complete.

## Constraints
- Don't change call-site signatures of `scheduleNotification` / `onItemCompleted` — load `allItems` inside the service via `DataManager`.
- Keep one pass over sequence children in graph spot building.

## How we'll know it's done
- Sequence parent with 3 children, 1 done → chip shows "2".
- Long-pressing a bar on a sequence's graph shows date + summed value.
- Completing or starting an item before nag time → no notification fires today.
- `flutter test --no-pub` passes.

## What's not included
- No in-app nag UI (none exists).
- No retroactive cancellation of already-fired notifications.
- No changes to test notifications.
