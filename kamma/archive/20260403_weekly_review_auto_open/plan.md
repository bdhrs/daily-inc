## Phase 1: Specify Review Schedule State
- [x] Define weekly review preference keys and default values for enabled, weekday, time, and last-shown occurrence
- [x] Add focused tests for schedule calculation and once-per-occurrence behavior
- [x] Implement a small weekly review scheduling/helper layer to read preferences and compute the current or next review occurrence
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 2: Build Weekly Review UI
- [x] Reuse the existing category graph screen and open it with a 1-week default range
- [x] Preserve the time-range selector so users can switch periods after opening
- [x] Add navigation support so the app can open the category graph screen directly
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 3: Integrate Scheduling and Notifications
- [x] Extend notification handling to support a weekly review notification with a dedicated payload
- [x] Open the weekly review automatically when the app is active and a scheduled occurrence becomes due
- [x] Ensure background/closed-app behavior uses notification tap to open the review screen
- [x] Persist the shown occurrence so one scheduled review is not reopened repeatedly
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 4: Add Settings Controls
- [x] Add weekly review toggle, weekday picker, and time picker to Settings
- [x] Save settings changes and reschedule the weekly review notification when needed
- [x] Keep defaults enabled for users with no saved weekly review settings
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 5: Verify End-to-End Behavior
- [x] Run the relevant automated tests and fix failures
- [x] Manually verify settings persistence, due-time behavior, notification tap navigation, and weekly graph display
- [x] Update Kamma thread artifacts and review the implementation against the spec
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
