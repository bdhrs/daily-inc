# Implementation Plan: Stopwatch Timer Type

## Phase 1: Model & Type Definition

- [ ] Task: Add stopwatch to ItemType enum
    - [ ] Add `stopwatch` value to `ItemType` enum in `lib/src/models/item_type.dart`
    - [ ] Update any switch statements or type checks that exhaustively list ItemTypes

- [ ] Task: Update IncrementCalculator for stopwatch type
    - [ ] Add handling in `determineStatus()` for stopwatch type (show green if time logged today)
    - [ ] Add handling in `isDone()` for stopwatch type (done if any time logged)
    - [ ] Ensure no progression calculations apply to stopwatch

- [ ] Task: Conductor - User Manual Verification 'Phase 1: Model & Type Definition' (Protocol in workflow.md)

## Phase 2: Stopwatch View Implementation

- [ ] Task: Create StopwatchView widget
    - [ ] Create `lib/src/views/stopwatch_view.dart` following TimerView pattern
    - [ ] Implement state: `_elapsedSeconds`, `_isRunning`, `_isPaused`
    - [ ] Implement `_toggleStopwatch()` for start/stop control
    - [ ] Implement `_runStopwatch()` with 100ms periodic timer incrementing elapsed seconds

- [ ] Task: Integrate shared timer components
    - [ ] Reuse `TimerDisplayWidget` for circular display (adapt for count-up display)
    - [ ] Reuse `TimerControlsWidget` for start/pause/exit buttons
    - [ ] Reuse `SubdivisionDisplayWidget` for subdivision progress
    - [ ] Reuse `CommentInputWidget` for optional comment

- [ ] Task: Implement subdivision bell support
    - [ ] Track elapsed time for subdivision triggers
    - [ ] Call `AudioHelper.playSubdivisionBell()` at intervals
    - [ ] Reuse `TimerLogicHelper.calculateCompletedSubdivisions()` logic

- [ ] Task: Implement exit and save logic
    - [ ] On exit, save total elapsed time to history
    - [ ] Convert seconds to minutes for `HistoryEntry.actualValue`
    - [ ] Create/update `HistoryEntry` with `doneToday = true`

- [ ] Task: Conductor - User Manual Verification 'Phase 2: Stopwatch View Implementation' (Protocol in workflow.md)

## Phase 3: Integration

- [ ] Task: Wire up tap handler in DailyThingItem
    - [ ] Add case for `ItemType.stopwatch` in `onTap` handler
    - [ ] Call `showFullscreenStopwatch()` method (new or adapt existing)

- [ ] Task: Implement list display for stopwatch items
    - [ ] Show total time logged today in `MM:SS` or `HH:MM:SS` format
    - [ ] Use `IncrementCalculator` to get today's accumulated time from history

- [ ] Task: Update Add/Edit item view
    - [ ] Add "Stopwatch" option to type selector
    - [ ] Show subdivision settings for stopwatch type
    - [ ] Hide target/duration fields (not applicable)

- [ ] Task: Update DailyThingsView navigation
    - [ ] Add `showFullscreenStopwatch()` callback method
    - [ ] Navigate to StopwatchView when stopwatch item tapped

- [ ] Task: Conductor - User Manual Verification 'Phase 3: Integration' (Protocol in workflow.md)

## Phase 4: Testing & Verification

- [ ] Task: Write unit tests
    - [ ] Test `IncrementCalculator` behavior for stopwatch type
    - [ ] Test time formatting utilities for stopwatch display

- [ ] Task: Run tests and analysis
    - [ ] Run `flutter test`
    - [ ] Run `flutter analyze`
    - [ ] Fix any issues

- [ ] Task: Manual testing
    - [ ] Create new stopwatch item
    - [ ] Start/stop/resume cycles
    - [ ] Verify subdivision bells
    - [ ] Verify save on exit
    - [ ] Verify list display shows correct time
    - [ ] Verify history is editable

- [ ] Task: Conductor - User Manual Verification 'Phase 4: Testing & Verification' (Protocol in workflow.md)