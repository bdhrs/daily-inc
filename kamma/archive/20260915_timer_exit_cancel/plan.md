# Plan — Cancel option when exiting a countdown timer early

## Architecture Decisions
- **Reuse the existing `null` branch.** `_exitTimerDisplay()` in
  `lib/src/views/timer_view.dart` already treats a `null` dialog result as
  "cancel, don't exit". No new control flow is added — a third dialog action
  simply makes that branch reachable.
- **The exit routine owns the pause.** The app-bar back arrow and the `PopScope`
  handler currently call `_toggleTimer()` before `_exitTimerDisplay()`, which
  destroys the information needed to resume. Those two pre-pauses are removed;
  the exit routine already pauses, cancels the tick timer and releases the
  wakelock itself. This also makes all three user-facing exit paths identical,
  matching the "Exit" button, which never pre-paused.
- **Resume via `_toggleTimer()`, not a new helper.** It is the existing start
  path and already handles wakelock, screen dimming, the minimalist fade timer
  and choosing the countdown branch. It plays the start bell only when the task
  has not started, so resuming a part-done task is silent — no new guard needed.
- **One local flag, no new state field.** `wasRunning` is a local in
  `_exitTimerDisplay()` captured before the pause. Nothing else needs it.
- **Nothing abstracted across views.** The stopwatch has no save dialog and is
  out of scope, so there is no shared helper to extract.

## Phase 1: Make Cancel reachable and resume on it

- [x] Add a Cancel action to the save dialog
  - In `lib/src/views/timer_view.dart`, in `_showSaveDialog()`, add a
    `TextButton` as the **last** entry in `actions` that pops `null`, labelled
    `Cancel`, so it renders on the right. Leave `barrierDismissible: false`
    unchanged — the dialog stays modal by decision.
  - Order the actions "Save" (pops `true`), "Don't Save" (pops `false`),
    "Cancel" (pops `null`).
  → verify: run `flutter analyze`, expect no new issues; read the method back and
    confirm three actions are present, popping `true`, `false`, `null` in that
    order, and that `barrierDismissible` is still `false`.
  - AMENDED mid-thread (2026-09-15): Cancel was first built as the leftmost
    action; on device the user moved it to last, then set the final order as
    Save, Don't Save, Cancel.

- [x] Capture whether the timer was running, and resume it on cancel
  - In `_exitTimerDisplay()`, add `final wasRunning = !_isPaused;` as the first
    statement, before the existing `if (!_isPaused) { setState(...) }` pause
    block.
  - In the `else if (shouldSave == null)` branch (currently a bare `return;`),
    call `_toggleTimer()` when `wasRunning` is true, then `return`. When
    `wasRunning` is false, return as it does today, leaving the timer paused.
  - Do not touch the `true` / `false` branches, and do not move the
    `_saveMinimalistModePreference` / `onExitCallback` / `Navigator.pop` calls —
    the early `return` must skip all three, as it already does.
  → verify: run `flutter analyze`, expect no new issues; confirm by reading that
    the cancel branch returns before `_saveMinimalistModePreference` is reached.

- [x] Stop the back-button paths from pre-pausing the timer
  - In `lib/src/views/timer_view.dart`, remove the
    `if (!_isPaused) { _toggleTimer(); }` block from the app-bar back-arrow
    `onPressed` handler, leaving the `await _exitTimerDisplay();` call.
  - Remove the same block from the `PopScope` `onPopInvokedWithResult` handler,
    again leaving the `await _exitTimerDisplay();` call.
  - Leave the "Exit" button path in
    `lib/src/views/widgets/timer_controls.dart` alone — it already calls the exit
    routine directly.
  - Leave the `_navigateToNextTask()` call site alone — it runs only after the
    timer has completed, so the dialog never appears there.
  → verify: `grep -n "_exitTimerDisplay" lib/src/views/timer_view.dart` and
    confirm no remaining `_toggleTimer()` call immediately precedes any of them.

- [x] Run the automated checks
  → verify: `flutter analyze` reports no new issues, and `flutter test --no-pub`
    passes with the same result as before the change (note the pass/fail counts
    in this file).
  - RESULT: baseline before the change was `flutter analyze` = 1 issue (a
    pre-existing `onReorder` deprecation info in `daily_things_view.dart:1264`)
    and `flutter test --no-pub` = 95 passed. After the change both are identical:
    1 issue (same pre-existing one) and 95 passed.
  - NOTE: `flutter analyze` itself rewrote `analysis_options.yaml` ("Upgrading
    analysis_options.yaml to exclude build and platform directories"). That tree
    change was not made by this thread.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
  - All four Phase 1 tasks verified. No regressions: analyze and test results
    match the baseline exactly.

## Phase 2: Confirm the behaviour on a real device

The project has no widget tests — nothing covers `TimerView` — so a device run is
the only verification. Install with `just update` (never `adb uninstall` or
`pm clear`, which wipe user data).

- [x] Confirm Cancel resumes a running timer from all three exit paths
  - Pick a task with a countdown of a few minutes and start it. Let it run a
    little, then exit via the "Exit" button; press Cancel.
  - Repeat with the app-bar back arrow, and again with the system/gesture back.
  → verify: after each Cancel the timer screen is still showing and the displayed
    countdown is still decreasing. Record all three outcomes in this file.

- [x] Confirm Cancel leaves a manually paused timer paused
  - Start a task, pause it with the Pause button, then press Exit and Cancel.
  → verify: still on the timer screen, the countdown is not moving, and pressing
    Start resumes it from where it stopped.

- [x] Confirm Save and Don't Save are unchanged
  - Start a task, run it briefly, Exit → Save; check today's recorded time for
    that item reflects the partial progress.
  - Start it again, run briefly, Exit → Don't Save; check today's recorded time
    is unchanged from the previous step.
  → verify: both recorded values match the expectation above.

- [x] Confirm the dialog is still modal
  - Open the dialog and tap the dimmed area outside it.
  → verify: the dialog stays open and the app does not exit the task.

- [x] Confirm the screen behaves while resumed
  - With screen dimming enabled, Cancel a running timer and wait for the dim
    interval; then repeat with minimalist mode enabled.
  → verify: dimming still kicks in after Cancel, the minimalist UI still fades,
    and the screen does not sleep while the timer runs.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
  - CONFIRMED by the user on a real device (2026-09-15): they reported running
    through the whole Phase 2 list and the behaviour was correct. Recorded from
    the user's report; not independently observed by the agent.

### Mid-thread change: dialog button order
The user adjusted the action order twice while testing on device. Final order,
left to right: Save, Don't Save, Cancel. `spec.md` and `plan.md` were updated at
the time of each change; `flutter analyze` was re-run after each and stayed at
the same single pre-existing issue.

## Phase 3: Review fixes (added 2026-09-15 after `/kamma:3-review`)

- [x] Release the next-task navigation latch on a cancelled exit
  - `_exitTimerDisplay()` returns `Future<bool>`, `false` on the cancel branch.
  - `_navigateToNextTask()` resets `_isNavigatingNext` when it returns `false`.
  → verify: `flutter analyze` clean of new issues; confirmed by reading that the
    latch is the only one-way flag on that path.
- [x] Guard the resume with `mounted`
  → verify: `flutter analyze` clean of new issues.
- [x] Record that the overtime dialog variant does not handle a cancel
  → verify: comment present at the dialog builder.
- [x] PHASE COMPLETE: `flutter analyze` = 1 pre-existing issue, `flutter test
  --no-pub` = 95 passed, `coderabbit review --agent --uncommitted --dir lib` = 0
  findings. See `review.md` for the full findings table, including two findings
  deliberately not fixed.

