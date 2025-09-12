# TimerView Refactoring Specification

## 1. Overview

The `TimerView` widget in `lib/src/views/timer_view.dart` is currently 1818 lines long and contains multiple responsibilities that should be separated into smaller, more manageable widgets and functions. This specification outlines the refactoring plan to improve code organization, maintainability, and readability while preserving all existing functionality.

## 2. Current Issues

1. **File Size**: The file is excessively long (1818 lines) making it difficult to navigate and understand
2. **Multiple Responsibilities**: The widget handles timer logic, UI rendering, note view mode, dimming functionality, minimalist mode, and more
3. **Complex State Management**: Many state variables are managed in a single class
4. **Tight Coupling**: UI components are tightly coupled with business logic

## 3. Refactoring Goals

1. **Separation of Concerns**: Split the widget into smaller, focused widgets
2. **Improved Readability**: Reduce file size and improve code organization
3. **Maintainability**: Make the code easier to maintain and extend
4. **Preserve Functionality**: Ensure all existing features work exactly as before
5. **Follow Flutter Best Practices**: Use proper widget composition and state management

## 4. Behavioral Definitions

### 4.1. Timer State Management

#### 4.1.1. Timer Initialization (`initState`)
- **Behavior**: Initialize timer with today's target value from `widget.item.todayValue`
- **Behavior**: Set `_initialTargetSeconds` to `_todaysTargetMinutes * 60`
- **Behavior**: Set `_currentItem` to `widget.item`
- **Behavior**: Set `_minimalistMode` to `widget.initialMinimalistMode`
- **Behavior**: If `widget.startInOvertime` is true, set `_isOvertime = true`, `_isPaused = true`, `_hasStarted = true`
- **Behavior**: Load dim screen and minimalist mode preferences from shared preferences
- **Behavior**: If `widget.nextTaskName` is provided, set `_nextTaskName` and `_showNextTaskName = true` and start a timer to fade it out after 8 seconds, fully hidden by 10 seconds
- **Behavior**: Search for today's history entry and initialize timer state based on it:
  - If entry exists with comment, load comment into `_commentController`
  - If entry exists and represents completed time (>= target or within epsilon), initialize overtime mode
  - If entry exists with partial time, set `_remainingSeconds` accordingly
  - If no entry exists, set `_remainingSeconds` to `_initialTargetSeconds`
- **Behavior**: Calculate subdivision state based on history entry or default to 0

#### 4.1.2. Timer Controls (`_toggleTimer`)
- **Behavior**: Toggle `_isPaused` state
- **Behavior**: When starting (paused -> running):
  - Set `_hasStarted = true`
  - Enable wakelock
  - If `_dimScreenMode` is enabled, start dimming process
  - If `_minimalistMode` is enabled, start fade UI timer
  - If timer is finished and not in overtime, start overtime mode
  - If already in overtime, run overtime timer
  - Otherwise, run countdown timer
- **Behavior**: When pausing (running -> paused):
  - Cancel timer
  - Disable wakelock
  - Make UI visible (cancel fade)
  - Cancel fade UI timer

#### 4.1.3. Countdown Timer (`_runCountdown`)
- **Behavior**: Create periodic timer that ticks every 100ms
- **Behavior**: When paused, cancel the timer
- **Behavior**: When running:
  - Decrease `_remainingSeconds` by 0.1 (100ms)
  - Update `_preciseElapsedSeconds` for subdivision tracking
  - If `_remainingSeconds` <= 0, call `_onTimerComplete()`
  - If subdivisions are enabled, check for subdivision boundaries and play bell when crossed

#### 4.1.4. Overtime Timer (`_runOvertime`)
- **Behavior**: Create periodic timer that ticks every 100ms
- **Behavior**: When paused, cancel the timer
- **Behavior**: When running:
  - Increase `_overtimeSeconds` by 0.1 (100ms)
  - Update `_preciseElapsedSeconds` for subdivision tracking
  - If subdivisions are enabled, check for subdivision boundaries and play bell when crossed

#### 4.1.5. Timer Completion (`_onTimerComplete`)
- **Behavior**: If `_dimScreenMode` is enabled, restore screen brightness
- **Behavior**: Play timer completion notification sound
- **Behavior**: Update UI state:
  - Set `_isPaused = true`
  - Set `_shouldFadeUI = false`
  - If subdivisions are enabled, set `_completedSubdivisions` to max value
  - Set `_showNextTaskArrow = true`
- **Behavior**: Cancel fade UI timer
- **Behavior**: Disable wakelock
- **Behavior**: Save progress asynchronously

### 4.2. UI Components

#### 4.2.1. Main Display (`build`)
- **Behavior**: If `_isNoteViewMode` is true, render `_buildNoteView()`
- **Behavior**: Otherwise, render main timer UI with:
  - AppBar with dynamic title (next task name or item name)
  - Time information display that changes based on mode (normal/overtime/minimalist)
  - Main timer display (countdown or overtime view)
  - Comment field with visibility logic
  - Control buttons (Start/Pause/Continue and Exit)
  - Dimming overlay
  - Next task arrow button

#### 4.2.2. Time Information Display
- **Behavior**: In normal mode:
  - If overtime and subdivisions enabled: Show three-part display (target+overtime, completed/total subdivisions, current subdivision time)
  - If overtime and no subdivisions: Show target+overtime
  - If countdown and subdivisions enabled: Show three-part display (elapsed/target, completed/total subdivisions, current subdivision time)
  - If countdown and no subdivisions: Show elapsed/target
- **Behavior**: In minimalist mode: Hide time information display

#### 4.2.3. Main Timer Display
- **Behavior**: Use `TimerPainter` to draw circular timer visualization
- **Behavior**: Show time text that updates every 100ms:
  - In countdown: Show remaining time
  - In overtime: Show total elapsed time
- **Behavior**: Tap gesture on timer to toggle timer state

#### 4.2.4. Comment Field (`_buildCommentField`)
- **Behavior**: Visibility controlled by complex logic:
  - In normal mode: Always visible
  - In minimalist mode:
    - When timer running in overtime: Hidden
    - When timer paused in overtime: Visible
    - When timer finished (0 seconds) but not in overtime: Visible
- **Behavior**: In minimalist mode when timer running: Fade out like other UI elements
- **Behavior**: Tap gesture focuses the text field
- **Behavior**: Visual styling changes based on focus/content state

#### 4.2.5. Note View Mode
- **Behavior**: When `_isNoteViewMode` is true, render specialized note view UI:
  - Top information bar with timer controls
  - Main notes display using Markdown rendering
  - Bottom action buttons (Edit Note, Close)
- **Behavior**: Back button toggles back to normal timer mode
- **Behavior**: Close button in app bar toggles back to normal timer mode

#### 4.2.6. Dimming Overlay
- **Behavior**: Visible when `_dimScreenMode` is true and `_dimOpacity` > 0.0
- **Behavior**: Gradually increases opacity over 10 seconds when timer running
- **Behavior**: Tap gesture resets opacity to 0 and restarts dimming after 3 seconds
- **Behavior**: Automatically hidden when timer paused or completes

#### 4.2.7. Next Task Arrow
- **Behavior**: Visible when `_showNextTaskArrow` is true
- **Behavior**: Pulsing animation to draw attention
- **Behavior**: Tap navigates to next undone task or exits to main UI

### 4.3. Special Modes

#### 4.3.1. Minimalist Mode (`_toggleMinimalistMode`)
- **Behavior**: Toggle `_minimalistMode` state
- **Behavior**: Cancel fade UI timer when toggling
- **Behavior**: If turning off, make UI visible again
- **Behavior**: Save preference to shared preferences

#### 4.3.2. Dim Screen Mode (`_toggleDimScreenMode`)
- **Behavior**: Toggle `_dimScreenMode` state
- **Behavior**: If timer running and enabling dim mode, start dimming process
- **Behavior**: If disabling dim mode, restore screen brightness
- **Behavior**: Save preference to shared preferences

### 4.4. Navigation and Data Management

#### 4.4.1. Exit Timer Display (`_exitTimerDisplay`)
- **Behavior**: Pause the timer and update the UI before showing any dialogs
- **Behavior**: Cancel all timers (main, dim, fade)
- **Behavior**: Disable wakelock
- **Behavior**: Restore screen brightness if dimming enabled
- **Behavior**: Save progress based on state:
  - If in overtime: Save progress
  - If partial progress: Show save dialog and handle user choice
  - If completed: Save progress
  - Otherwise: Save comment only
- **Behavior**: Save minimalist mode preference
- **Behavior**: Call `widget.onExitCallback()` and pop navigator

#### 4.4.2. Next Task Navigation (`_navigateToNextTask`)
- **Behavior**: Find next undone task in list after current item
- **Behavior**: If no more tasks, exit to main UI
- **Behavior**: Cancel timers and disable wakelock
- **Behavior**: Save current progress
- **Behavior**: If next task is minutes type, navigate to new TimerView
- **Behavior**: Otherwise, exit to main UI

#### 4.4.3. Progress Saving (`_saveProgress`, `_saveCommentOnly`)
- **Behavior**: Create new history entry with current time, target value, completion status, and actual value
- **Behavior**: Remove any existing entry for today to prevent duplicates
- **Behavior**: Update item with new history and save via DataManager
- **Behavior**: For comment-only saving, only update comment without changing progress values

### 4.5. Audio Management

#### 4.5.1. Timer Completion Sound (`_playTimerCompleteNotification`)
- **Behavior**: Play bell sound from `_currentItem.bellSoundPath` or default
- **Behavior**: Handle errors gracefully

#### 4.5.2. Subdivision Bell Sound (`_playSubdivisionBell`)
- **Behavior**: Stop any currently playing subdivision bell to ensure the new one plays
- **Behavior**: Play bell sound from `_currentItem.subdivisionBellSoundPath` or default
- **Behavior**: Handle errors gracefully

## 5. Proposed Structure

### 5.1. Main TimerView Widget
The main `TimerView` widget will be simplified to coordinate between different sub-components:

### 5.2. New Widgets to Extract

1. **TimerDisplayWidget** - Handles the main timer display logic
2. **TimerControlsWidget** - Manages the timer control buttons
3. **NoteViewWidget** - Handles the note view mode UI (already partially implemented)
4. **TimerAppBarWidget** - Manages the app bar with its actions
5. **CommentInputWidget** - Handles the comment input field
6. **DimmingOverlayWidget** - Manages the screen dimming overlay
7. **NextTaskArrowWidget** - Handles the next task navigation arrow
8. **SubdivisionDisplayWidget** - Handles subdivision information display
9. **TimeInfoBarWidget** - Handles the top information bar in note view mode

### 5.3. Helper Classes/Functions

1. **TimerLogicHelper** - Contains pure functions for timer calculations
2. **TimerStateHelper** - Manages complex state transitions
3. **AudioHelper** - Handles audio playback functionality

## 6. Implementation Plan

### 6.1. Phase 1: Extract Helper Functions
- Move pure calculation functions to `TimerLogicHelper`
- Extract state management functions to `TimerStateHelper`
- Extract audio functions to `AudioHelper`

### 6.2. Phase 2: Extract UI Components
- Create `TimerDisplayWidget` for the main timer display
- Create `TimerControlsWidget` for control buttons
- Create `TimerAppBarWidget` for the app bar
- Create `CommentInputWidget` for the comment field

### 6.3. Phase 3: Extract Specialized Views
- Refactor `NoteViewWidget` into its own file
- Create `DimmingOverlayWidget` for the dimming functionality
- Create `NextTaskArrowWidget` for navigation arrow

### 6.4. Phase 4: Integrate and Verify
- Update main `TimerView` to use new components
- Ensure all functionality is preserved
- Verify behavior matches documented specifications

## 7. Testing Requirements

1. **Functional Testing**: All existing timer functionality must work identically
2. **UI Testing**: All visual elements must appear and behave exactly as before
3. **Performance Testing**: No performance degradation should be introduced
4. **Navigation Testing**: All navigation paths must work correctly
5. **State Preservation**: Timer state must be preserved during mode switches

## 8. Success Criteria

1. Main `TimerView` file reduced to under 500 lines
2. All new widgets are under 200 lines each
3. All existing functionality preserved
4. Code is more readable and maintainable
5. No performance regressions
6. All tests pass

## 9. File Structure After Refactoring

```
lib/src/views/timer_view.dart              # Main TimerView widget (simplified)
lib/src/views/widgets/timer_display.dart   # TimerDisplayWidget
lib/src/views/widgets/timer_controls.dart  # TimerControlsWidget
lib/src/views/widgets/timer_app_bar.dart   # TimerAppBarWidget
lib/src/views/widgets/comment_input.dart   # CommentInputWidget
lib/src/views/widgets/note_view.dart       # NoteViewWidget
lib/src/views/widgets/dimming_overlay.dart # DimmingOverlayWidget
lib/src/views/widgets/next_task_arrow.dart # NextTaskArrowWidget
lib/src/views/widgets/subdivision_display.dart # SubdivisionDisplayWidget
lib/src/views/widgets/time_info_bar.dart   # TimeInfoBarWidget
lib/src/views/helpers/timer_logic.dart     # TimerLogicHelper
lib/src/views/helpers/timer_state.dart     # TimerStateHelper
lib/src/views/helpers/audio_helper.dart    # AudioHelper
```

## 10. Summary of Achievements and Remaining Work

### 10.1. What Has Been Achieved

1. **Specification Creation**: 
   - Created a comprehensive refactoring specification (`specs/timer_view_refactor.md`) detailing the current issues, goals, behavioral definitions, and proposed structure
   - Created a detailed test specification (`specs/timer_view_tests.md`) outlining what tests need to be written to enshrine current behavior

2. **Helper Class Development**:
   - Created `TimerLogicHelper` with pure functions for timer calculations
   - Created `TimerStateHelper` for managing complex state transitions
   - Created `AudioHelper` for handling audio playback functionality

3. **Widget Extraction**:
   - Created `TimerDisplayWidget` for the main timer display
   - Created `TimerControlsWidget` for control buttons
   - Created `CommentInputWidget` for the comment input field
   - Created `SubdivisionDisplayWidget` for subdivision information display

4. **Partial Implementation**:
   - Began refactoring the main `TimerView` file to use the new components
   - Added imports for the new widgets and helpers
   - Started implementing the new structure in the main file

### 10.2. What Still Needs to Be Done

1. **Complete Helper Implementation**:
   - Finish implementing all methods in `TimerLogicHelper`
   - Finish implementing all methods in `TimerStateHelper`
   - Finish implementing all methods in `AudioHelper`

2. **Complete Widget Implementation**:
   - Finish implementing `TimerAppBarWidget`
   - Finish implementing `NoteViewWidget`
   - Finish implementing `DimmingOverlayWidget`
   - Finish implementing `NextTaskArrowWidget`
   - Finish implementing `TimeInfoBarWidget`

3. **Refactor Main TimerView**:
   - Complete the refactoring of the main `TimerView` file to use all new components
   - Ensure all functionality is preserved
   - Reduce the file size to under 500 lines

4. **Create Comprehensive Tests**:
   - Write tests that capture all current TimerView behavior
   - Ensure all functionality works identically after refactoring
   - Verify no regressions are introduced

5. **Integration and Verification**:
   - Integrate all new components into the main `TimerView`
   - Verify that all existing functionality is preserved
   - Conduct thorough testing with the new test suite

6. **Documentation Updates**:
   - Update `project_map.md` to reflect the new file structure
   - Update any relevant documentation

### 10.3. Next Steps

1. Complete the implementation of all helper classes
2. Finish implementing all extracted widgets
3. Refactor the main TimerView to use the new components
4. Create comprehensive tests to ensure behavior preservation
5. Integrate and verify all components work together
6. Update documentation to reflect the new structure