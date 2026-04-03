## Overview
After saving edits to a timer item (from the Edit Item screen accessed via the timer), all changes — start value, end value, subdivisions, etc. — must be immediately reflected in the timer display without requiring an exit and re-entry.

## What It Should Do
- When the user edits an item while the countdown timer is open and saves changes, the timer should reinitialize its state from the updated item.
- Changes to duration/target (derived from start value, end value, progression) must update `_remainingSeconds` and `_todaysTargetMinutes`.
- Changes to subdivisions must update `_completedSubdivisions` and subdivision interval state.
- Timer is left in a paused state after editing (same as entering the timer fresh).

## Root Cause
In `timer_view.dart`, `_editItem()` receives the updated `DailyThing` back from the edit screen but only updates `_currentItem`. It does not call `TimerStateHelper.initializeTimerState()`, so all computed timer variables (`_remainingSeconds`, `_todaysTargetMinutes`, `_completedSubdivisions`, `_preciseSubdivisionInterval`, etc.) remain stale.

## Constraints
- Fix must be minimal and contained to `_editItem()` in `timer_view.dart`.
- Must not disrupt the "edit cancelled" branch (resume timer if it was running).
- Must not auto-resume the timer after saving edits.

## How We'll Know It's Done
- Changing start/end value in edit and saving shows the updated remaining time in the timer.
- Changing subdivisions in edit and saving shows the updated subdivision count.
- The timer starts paused after returning from edit.
- Cancelling edit with no changes resumes timer if it was running.

## What's Not Included
- Any changes to the edit screen itself.
- Any change to how progress is saved.
