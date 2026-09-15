# Spec — Cancel option when exiting a countdown timer early

## Overview
The countdown timer view asks "Save Progress?" when you leave a task part-way
through. The dialog offers only "Don't Save" and "Save" — both of which exit the
task. There is no way to say "I hit exit by mistake, keep going". This thread adds
a Cancel option that closes the dialog, stays on the timer screen, and resumes the
countdown if it was running when exit was pressed.

Thread type: feature (the option has never existed in the UI).

## Current behaviour (verified by reading the code, not from memory)
- `lib/src/views/timer_view.dart` — `_exitTimerDisplay()`:
  - Pauses the timer, cancels the tick timer and the dim timer, releases the
    wakelock and restores screen brightness.
  - If the task has started and time remains, it awaits `_showSaveDialog()`.
  - It already branches on three results: `true` → save progress, `false` → save
    comment only, `null` → `return` without exiting. **The `null` branch is
    currently unreachable.**
- `_showSaveDialog()` builds an `AlertDialog` with exactly two actions, popping
  `false` and `true`, and sets `barrierDismissible: false`. Nothing pops `null`.
- Three user-facing paths reach `_exitTimerDisplay()`:
  1. The "Exit" button in `lib/src/views/widgets/timer_controls.dart` — calls it
     directly, no pre-pause.
  2. The app-bar back arrow in `timer_view.dart` — calls `_toggleTimer()` first
     if the timer is running, then exits.
  3. The system/gesture back button via `PopScope` — same pre-pause, then exits.
  A fourth, non-interactive path (`_navigateToNextTask()` when no tasks remain)
  also calls it, but only after the timer has completed, so the dialog never
  shows there.
- Because paths 2 and 3 pause the timer *before* the exit routine runs, the exit
  routine cannot tell whether the timer was running. A Cancel button alone would
  leave the user on a stopped timer.
- `_toggleTimer()` is the existing resume path: it re-enables the wakelock,
  restarts screen dimming and the minimalist fade timer, and restarts the
  countdown. It only plays the start bell when the task has not started, so
  resuming a part-done task is silent.

## What it should do
1. The "Save Progress?" dialog shows three actions, left to right:
   Save, Don't Save, Cancel. This order was set by the user on device
   (2026-09-15, mid-thread) after seeing earlier arrangements.
2. Cancel closes the dialog and does not leave the timer screen. Nothing is
   written to history, no comment is saved, and the minimalist-mode preference is
   not written.
3. If the timer was running at the moment the user asked to exit, Cancel resumes
   it — counting down, screen awake, dimming and minimalist fade behaving exactly
   as they did before.
4. If the timer was already paused when the user asked to exit, Cancel leaves it
   paused and the user presses Start themselves.
5. The dialog stays modal: tapping outside it does nothing.
6. Save and Don't Save behave exactly as they do today.

## Assumptions & uncertainties
- Assumed: moving the pause out of the two back-button call sites and letting the
  exit routine own it is safe. The exit routine already performs the same work
  (pause state, cancel tick timer, release wakelock) plus brightness restore. The
  one thing `_toggleTimer()` does that the exit routine does not is clear the
  minimalist fade flag and its timer; while the modal dialog is up this is not
  visible, and on cancel `_toggleTimer()` restores it. **Not verified on a device
  yet** — this is the main risk and Phase 2 covers it.
- Assumed: the overtime variant of the save dialog (`isOvertime: true`) is dead
  code — nothing in the codebase calls it, exiting during overtime saves silently.
  Left untouched, but its actions are updated alongside the normal ones since they
  share one builder.
- Not verified: behaviour when the Android back gesture is used mid-dialog. The
  dialog is modal and barrier-dismissible is off, so the expectation is that it is
  unaffected, but this is an observation about Flutter defaults, not a test.
- The project has no widget tests at all — nothing covers `TimerView`. There is
  no automated way to prove this dialog change; verification is a real device run.

## Constraints
- Countdown timer only. The stopwatch view saves silently on exit with no dialog
  and stays exactly as it is.
- Do not change what Save or Don't Save write to history.
- Do not add a widget-test harness as part of this thread.
- `flutter test --no-pub` and `flutter analyze` must stay green.

## How we'll know it's done
On a real device, with a task that has a countdown of a few minutes:
1. Start the task, let it run, press Exit → dialog shows three options.
2. Press Cancel → still on the timer screen, and the countdown is ticking down.
3. Repeat with the app-bar back arrow and with the system back gesture → same.
4. Pause the task manually, press Exit, press Cancel → still on the timer screen,
   still paused, Start resumes it.
5. Press Exit then Save → exits and today's partial time is recorded.
6. Press Exit then Don't Save → exits and today's time is unchanged.
7. Tapping outside the dialog does nothing.

## Amended during review (2026-09-15)
- `_exitTimerDisplay()` now returns `Future<bool>` — `false` when the user
  cancelled. This was not in the original plan. Review found that
  `_navigateToNextTask()` sets a one-way `_isNavigatingNext` latch before calling
  it; because a cancelled exit returns without exiting, the latch would stay set
  and kill the next-task arrow for the session. The bool lets that caller unwind.
  This also corrects the spec's claim that the `_navigateToNextTask` call site
  could never show the dialog — it can, via the arrow after an item edit.
- The cancel branch now also checks `mounted` before resuming.

## What's not included
- Any change to the stopwatch view.
- Reviving or wiring up the unused overtime save dialog.
- Widget tests for the timer view.
- Any change to how partial progress is calculated or stored.
