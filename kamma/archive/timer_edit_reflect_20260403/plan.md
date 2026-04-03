## Phase 1: Fix timer state reinitialization after edit

- [ ] In `timer_view.dart` `_editItem()`, after receiving a non-null `updatedItem`, call `TimerStateHelper.initializeTimerState()` with the updated item and update all timer state variables: `_currentItem`, `_todaysTargetMinutes`, `_remainingSeconds`, `_overtimeSeconds`, `_isOvertime`, `_hasStarted`, `_completedSubdivisions`, and reset precision tracking vars (`_preciseElapsedSeconds`, `_preciseSubdivisionInterval`, `_lastTriggeredSubdivision`). Set `_isPaused = true`.
- [ ] PHASE COMPLETE: verify all tasks done and no regressions introduced
