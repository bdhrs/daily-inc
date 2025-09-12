# TimerView Test Specification

## 1. Overview

This document specifies the comprehensive test suite that needs to be created for the TimerView widget before refactoring. These tests will enshrine the current behavior to ensure no regressions are introduced during the refactoring process.

## 2. Test Categories

### 2.1. Timer Functionality Tests

#### 2.1.1. Basic Timer Operations
- Timer starts when "Start" button is pressed
- Timer pauses when "Pause" button is pressed during countdown
- Timer resumes when "Continue" button is pressed after pausing
- Timer button text changes correctly (Start → Pause → Continue)

#### 2.1.2. Countdown Completion
- Timer transitions to overtime mode when countdown reaches zero
- Overtime timer starts automatically after countdown completion
- Timer completion bell sound plays when countdown finishes
- "Continue" button appears after timer completion

#### 2.1.3. Overtime Functionality
- Overtime timer increments correctly
- Overtime timer can be paused and resumed
- Overtime timer displays time as "target + overtime"

#### 2.1.4. Time Calculations
- Elapsed time calculation is accurate
- Remaining time calculation is accurate
- Time formatting displays correctly (MM:SS format)
- Subdivision time calculations are accurate

### 2.2. Subdivision Tests

#### 2.2.1. Subdivision Display
- Subdivision count displays correctly (current/total)
- Subdivision display updates as timer progresses
- Subdivision display is hidden when subdivisions = 1
- Subdivision display shows in both countdown and overtime modes

#### 2.2.2. Subdivision Bell Triggering
- Subdivision bell sounds play at correct intervals
- Bell plays for each completed subdivision
- Bell does not play at timer start (0% completion)
- Bell plays at timer completion (100% completion)

### 2.3. UI State Tests

#### 2.3.1. Button States
- Start button is enabled when timer is initialized
- Pause button is enabled when timer is running
- Continue button is enabled when timer is paused
- Exit button is always enabled

#### 2.3.2. Time Display
- Countdown time displays as "remaining / target"
- Overtime time displays as "target + overtime"
- Time display updates every 100ms during timer operation
- Time display shows correct formatting (MM:SS)

#### 2.3.3. Comment Field
- Comment field is visible during normal operation
- Comment field accepts text input
- Comment field preserves entered text
- Comment field scrolls when text overflows

### 2.4. Special Modes Tests

#### 2.4.1. Note View Mode
- Note view mode can be entered from menu
- Note view mode displays item notes correctly
- Note view mode preserves timer state
- Note view mode can be exited to return to timer view
- Edit note functionality works in note view mode

#### 2.4.2. Minimalist Mode
- Minimalist mode can be toggled on/off
- UI elements fade out when timer is running in minimalist mode
- UI elements fade in when timer is paused in minimalist mode
- Back button is visible in minimalist mode when timer is running

#### 2.4.3. Screen Dimming
- Screen dimming can be enabled/disabled
- Screen dimming overlay appears after specified time
- Screen dimming overlay can be dismissed by tapping
- Screen brightness restores to normal when dimming is disabled

### 2.5. Navigation Tests

#### 2.5.1. Next Task Navigation
- Next task arrow appears when timer completes
- Next task arrow pulses for attention
- Clicking next task arrow navigates to next undone task
- Next task arrow disappears when clicked

#### 2.5.2. Exit Behavior
- Exit button saves progress correctly
- System back button saves progress correctly
- Partial progress is saved when exiting during countdown
- Overtime progress is saved when exiting during overtime
- Exit confirmation dialog appears for partial progress

### 2.6. Data Persistence Tests

#### 2.6.1. History Saving
- Timer progress is saved to history when completed
- Comment is saved to history when provided
- History entry includes correct target value
- History entry includes correct actual value

#### 2.6.2. State Restoration
- Timer state restores correctly when reopening item
- Partial progress restores correctly
- Overtime state restores correctly
- Comment text restores correctly

### 2.7. Edge Case Tests

#### 2.7.1. Timer Initialization
- Timer initializes with correct target time
- Timer initializes with correct remaining time
- Timer initializes with correct overtime state
- Timer handles items with 0 subdivisions correctly

#### 2.7.2. Error Conditions
- Timer handles missing bell sounds gracefully
- Timer handles audio playback errors gracefully
- Timer handles negative time values gracefully
- Timer handles very large time values correctly

## 3. Test Implementation Plan

### 3.1. Test File Structure
```
test/timer_view/
├── timer_functionality_test.dart
├── subdivision_test.dart
├── ui_state_test.dart
├── special_modes_test.dart
├── navigation_test.dart
├── data_persistence_test.dart
└── edge_cases_test.dart
```

### 3.2. Test Dependencies
- Mock DataManager for history saving
- Mock AudioPlayer for bell sounds
- Mock ScreenBrightness for dimming
- Mock WakelockPlus for wakelock management

### 3.3. Test Data Setup
- Create test DailyThing items with various configurations
- Create test HistoryEntry data for state restoration
- Create test timer configurations (with/without subdivisions)
- Create test notes data for note view mode

## 4. Success Criteria

1. All timer functionality tests pass
2. All UI state tests pass
3. All special modes tests pass
4. All navigation tests pass
5. All data persistence tests pass
6. All edge case tests pass
7. Test coverage includes 100% of TimerView features
8. Tests run successfully in both normal and headless modes
9. Tests execute quickly (under 30 seconds total)
10. Tests provide clear failure messages for debugging

## 5. Test Execution Requirements

1. Tests must run in the same environment as existing tests
2. Tests must not require external hardware (screen, speakers, etc.)
3. Tests must mock all external dependencies
4. Tests must be deterministic (same input always produces same output)
5. Tests must clean up after themselves (no test data pollution)
6. Tests must be runnable individually or as a suite
7. Tests must provide meaningful error messages
8. Tests must be maintainable and readable