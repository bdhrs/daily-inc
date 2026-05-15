# Spec — Sequence Polish

## Overview
Six small improvements on top of the Sequence feature (commit d2780ad).
No new concepts, no schema changes, no architectural shifts.

## What it should do

### 1. Copy whole sequence (FIRST priority)
- Duplicating a sequence in the daily list duplicates **the sequence and all
  its current children**. Each duplicated child gets a fresh UUID and empty
  history. The duplicated sequence's `childIds` references the new ids (not
  the originals). Insert the new sequence right after the original; insert
  the cloned children immediately after the new sequence (preserving order).
- Duplicating a non-sequence item is unchanged.

### 2. Add inside sequence (placeholder path)
- Tapping the empty-sequence placeholder ("Drop items here or tap to add")
  must reliably create a new item that lands as a child of that sequence.
  The wiring already passes `initialParentSequenceId: seqId`; verify and
  fix any bug preventing the parent-sequence link from persisting on save.

### 3. 10-second chain delay
- Between auto-advanced sequence items, the dwell is **10 seconds**
  (currently 2). Single value change in `timer_view.dart`.

### 4. Keep screen awake across the chain
- When auto-start chains to the next item, the screen must not blank.
  The wakelock must remain enabled through the `pushReplacement`
  transition.

### 5. Start bell on auto-start
- When a chained timer auto-starts, play the same bell sound as the
  timer-complete bell (`AudioHelper.playTimerCompleteNotification`).

### 6. Hide alarm row when notifications disabled
- In the expanded item overview, the right-hand alarm icon + nag-time
  row is shown only when both `item.notificationEnabled == true` AND
  `item.nagTime != null`.

## Assumptions & uncertainties
- "Notifications turned off in settings" = the per-item
  `notificationEnabled` toggle.
- Cloning a sequence's children is safe — progression math is
  independent of `childIds`.

## Constraints
- No new patterns. Touch only what each item requires.
- Backwards compatible.

## How we'll know it's done
1. Duplicate on a 3-item sequence creates a new sequence with 3 fresh
   children.
2. Placeholder → create item → save → item is a child of that
   sequence.
3. Auto-advance dwell ~10 s.
4. Screen stays on during chained transitions.
5. Audible bell when next item auto-starts.
6. Item with `notificationEnabled: false` + `nagTime` shows no alarm
   row.
