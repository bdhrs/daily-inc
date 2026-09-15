## Thread
- **ID:** 20260915_timer_exit_cancel
- **Objective:** Add a Cancel option to the countdown timer's early-exit dialog
  that keeps the user in the task and resumes the countdown if it was running.

## Files Changed
- `lib/src/views/timer_view.dart` — added the Cancel action to `_showSaveDialog`,
  captured `wasRunning` in `_exitTimerDisplay` and resumed via `_toggleTimer` on
  cancel, removed the pre-pause from the app-bar back arrow and the `PopScope`
  handler, and changed `_exitTimerDisplay` to return a bool so callers can unwind
  latched state on a cancelled exit.

Not part of this thread: `analysis_options.yaml` is modified in the working tree.
`flutter analyze` rewrote it on its own ("Upgrading analysis_options.yaml to
exclude build and platform directories") before any edit was made. It should be
committed separately or reverted, not folded into this thread's commit. The
independent reviewer confirmed the added exclude block is inert — no `.dart`
files exist under any of the excluded platform directories.

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | minor | `timer_view.dart:793-808` | `_isNavigatingNext` is set true and never reset. Before this thread `_exitTimerDisplay` always exited, so it never mattered; now a cancelled exit returns and leaves the latch stuck. | Reachable: finish a task (next-task arrow appears, `_showNextTaskArrow` is never cleared), edit the item to raise its target (`_editItem` resets `_remainingSeconds` but not the arrow flag), tap the arrow with no next task → the save dialog now appears → Cancel → the arrow is dead for the rest of the session. The plan's claim that this call site was safe to leave alone was wrong. | Applied: `_exitTimerDisplay` now returns `Future<bool>` (`false` on cancel) and `_navigateToNextTask` releases the latch when it returns false. |
| 2 | minor | `timer_view.dart:626` | `_toggleTimer()` calls `setState` after an await with no `mounted` guard, inconsistent with the same method's own `if (mounted)` before `Navigator.pop` and with `_editItem`. | Defensive only — no concrete disposal path reaches it, since the tick timer is cancelled before the dialog opens. | Applied: `if (wasRunning && mounted)`. |
| 3 | minor | `timer_view.dart:653-687` | The shared dialog builder now emits a Cancel action for the `isOvertime` variant, whose caller has no null handling. | The `isOvertime` variant is genuinely uncalled (verified by sweep), but anyone wiring it up later would get a Cancel that silently exits. | Applied: comment at the builder recording that the overtime path does not handle a cancel. |
| 4 | minor | `timer_view.dart:587`, `timer_controls.dart:44` | `_exitTimerDisplay` has no re-entrancy guard; the Exit button has no debounce. | Pre-existing in kind, not introduced here — the pre-existing worse case (two invocations both popping) predates the thread. Neither reviewer could reproduce it without a device. | **Deferred** as out of scope for this thread. An `_isExiting` flag would close it. |
| 5 | nit | `timer_view.dart:597-601` | The pause block does not clear `_shouldFadeUI` / `_fadeUITimer` the way `_toggleTimer`'s pause branch did. | This was the spec's main unverified assumption. Traced in full: every consumer of `_shouldFadeUI` is gated on `!_isPaused`, and the state self-heals via `_startFadeUITimer` on resume and `dispose` on exit. **The spec's assumption holds** — no visible effect. | **Not applied**; no bug to fix. |

## Fixes Applied
- Findings 1, 2 and 3 above. Findings 4 and 5 deliberately left alone, with
  reasons recorded.
- Side benefit confirmed by the reviewer and resolved in the spec's favour:
  pressing Android back *while the dialog is open* pops it with null, which
  previously left the user in the task with a silently stopped timer and now
  resumes correctly. A latent bug fixed in passing.

## Test Evidence
- `flutter analyze` (scope: whole project) → 1 issue, the same pre-existing
  `onReorder` deprecation in `daily_things_view.dart:1264` that was present at
  the baseline before any edit. No new issues.
- `flutter test --no-pub` (scope: whole suite, 95 tests, all pure-logic tests of
  calculators and helpers) → all pass, identical to baseline. **This suite does
  not exercise a single line of this change** — a full revert would leave all 95
  green. It proves no regression elsewhere, nothing about this feature.
- `coderabbit review --agent --uncommitted --dir lib` → 0 findings, run twice:
  once before the review fixes and once after. Scoped to `lib/` to exclude the
  unrelated analysis options change and the untracked thread files.
- Independent agent review with its own context (it re-ran both commands itself
  and reproduced the same output).
- Phase 2 device run: the user reported working through the whole Phase 2 list on
  a real device and confirming the behaviour. Recorded from their report, not
  observed by an agent.

## Not Verified
- No automated test covers the dialog, the cancel branch, or the resume. The
  project has no widget tests for this view at all; this is a known, documented
  project-wide gap, not something this thread introduced.
- The two re-entrancy scenarios in finding 4 are reasoned from the code and
  Flutter's route-pop timing; neither reviewer could reproduce them.
- The `isOvertime` dialog variant remains unreachable and untested — unchanged by
  this thread.
- Whether `_restoreScreenBrightness`'s platform call has any real effect; nothing
  in this view sets application brightness, so it appears to be a no-op, but that
  cannot be tested headlessly.

## Verdict
PASSED
- Review date: 2026-09-15
- Reviewer: independent agent (own context) + CodeRabbit CLI, fixes applied and
  re-verified by the implementing session.
