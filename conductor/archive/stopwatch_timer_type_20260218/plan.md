# Implementation Plan: Stopwatch Timer Type

## Phase 1: Model & Type Definition

- [x] Task: Add stopwatch to ItemType enum
    - [x] Add `stopwatch` value to `ItemType` enum in `lib/src/models/item_type.dart`
    - [x] Update any switch statements or type checks that exhaustively list ItemTypes

- [x] Task: Update IncrementCalculator for stopwatch type
    - [x] Add handling in `determineStatus()` for stopwatch type (show green if time logged today)
    - [x] Add handling in `isDone()` for stopwatch type (done if any time logged)
    - [x] Ensure no progression calculations apply to stopwatch

- [x] Task: Conductor - User Manual Verification 'Phase 1: Model & Type Definition' (Protocol in workflow.md)

## Phase 2: Stopwatch View Implementation

- [x] Task: Create StopwatchView widget
    - [x] Create `lib/src/views/stopwatch_view.dart` following TimerView pattern
    - [x] Implement state: `_elapsedSeconds`, `_isRunning`, `_isPaused`
    - [x] Implement `_toggleStopwatch()` for start/stop control
    - [x] Implement `_runStopwatch()` with 100ms periodic timer incrementing elapsed seconds

- [x] Task: Integrate shared timer components
    - [x] Reuse `TimerDisplayWidget` for circular display (adapt for count-up display)
    - [x] Reuse `TimerControlsWidget` for start/pause/exit buttons
    - [x] Reuse `SubdivisionDisplayWidget` for subdivision progress
    - [x] Reuse `CommentInputWidget` for optional comment

- [x] Task: Implement subdivision bell support
    - [x] Track elapsed time for subdivision triggers
    - [x] Call `AudioHelper.playSubdivisionBell()` at intervals
    - [x] Reuse `TimerLogicHelper.calculateCompletedSubdivisions()` logic

- [x] Task: Implement exit and save logic
    - [x] On exit, save total elapsed time to history automatically
    - [x] Convert seconds to minutes for `HistoryEntry.actualValue`
    - [x] Create/update `HistoryEntry` with `doneToday = true`

- [x] Task: Conductor - User Manual Verification 'Phase 2: Stopwatch View Implementation' (Protocol in workflow.md)

## Phase 3: Integration

- [x] Task: Wire up tap handler in DailyThingItem
    - [x] Add case for `ItemType.stopwatch` in `onTap` handler
    - [x] Call `showFullscreenStopwatch()` method (new or adapt existing)

- [x] Task: Implement list display for stopwatch items
    - [x] Show total time logged today in `MM:SS` or `HH:MM:SS` format
    - [x] Use `IncrementCalculator` to get today's accumulated time from history

- [x] Task: Update Add/Edit item view
    - [x] Add "Stopwatch" option to type selector
    - [x] Show subdivision settings for stopwatch type
    - [x] Hide target/duration fields (not applicable)

- [x] Task: Update DailyThingsView navigation
    - [x] Add `showFullscreenStopwatch()` callback method
    - [x] Navigate to StopwatchView when stopwatch item tapped

- [x] Task: Conductor - User Manual Verification 'Phase 3: Integration' (Protocol in workflow.md)

## Phase 4: Testing & Verification

- [x] Task: Write unit tests
    - [x] Test `IncrementCalculator` behavior for stopwatch type
    - [x] Test time formatting utilities for stopwatch display

- [x] Task: Run tests and analysis
    - [x] Run `flutter test`
    - [x] Run `flutter analyze`
    - [x] Fix any issues

- [x] Task: Manual testing
    - [x] Create new stopwatch item
    - [x] Start/stop/resume cycles
    - [x] Verify subdivision bells
    - [x] Verify save on exit (automatic, no dialog)
    - [x] Verify list display shows correct time
    - [x] Verify history is editable

- [x] Task: Conductor - User Manual Verification 'Phase 4: Testing & Verification' (Protocol in workflow.md)