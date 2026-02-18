# Specification: Stopwatch Timer Type

## Overview
Add a new "Stopwatch" task type that functions as a count-up timer (opposite of the countdown timer). Users can start, stop, and accumulate time, with the total saved to history on exit. No progression calculations or daily targets.

## Functional Requirements

### FR1: New ItemType
- Add `stopwatch` to the `ItemType` enum
- Stopwatch items appear in the main list alongside other types

### FR2: Tap Behavior
- Tapping a stopwatch item opens a fullscreen stopwatch view
- Initial display shows `00:00`
- User can tap to start the timer

### FR3: Timer Controls
- **Start**: Begins counting upward from current elapsed time
- **Stop**: Pauses the timer, retains elapsed time
- **Resume**: Can start again to add more time (accumulates)
- **Exit**: Saves total elapsed time to history and exits view

### FR4: Subdivisions (Bells)
- Support optional subdivision bells at set time intervals
- Uses same subdivision mechanism as countdown timer
- Bell sounds at each interval while running

### FR5: History & Persistence
- Total elapsed time is logged to `HistoryEntry.actualValue` (in minutes)
- Time is saved when user exits the stopwatch view (back button or exit)
- History entries are editable
- Accumulates time if user starts/stops multiple times in one session

### FR6: List Display
- Main list shows total time logged today (e.g., "15:30 today")
- Visual format: `MM:SS` or `HH:MM:SS` depending on duration

### FR7: Add/Edit Item
- Stopwatch is available as a type option when creating/editing items
- Settings: name, category, subdivision interval, bell sound (no target/duration fields)

## Non-Functional Requirements

### NFR1: Code Reuse
- Recycle existing timer components: `TimerDisplayWidget`, `TimerPainter`, `TimerControlsWidget`, `SubdivisionDisplayWidget`, `CommentInputWidget`, `AudioHelper`
- Follow existing patterns for input dialogs and state management

### NFR2: Performance
- Timer must be accurate (same precision as countdown timer)
- Screen stays awake while timer is running (wakelock)

## Acceptance Criteria

1. User can create a new item with type "Stopwatch"
2. Tapping a stopwatch item opens fullscreen view showing `00:00`
3. User can start/stop the timer multiple times in one session
4. Elapsed time accumulates across start/stop cycles
5. Subdivision bells play at configured intervals
6. Exiting the view saves total time to history
7. Main list displays total time logged today
8. History entries can be edited
9. No progression calculations or daily targets apply

## Out of Scope

- Daily targets or progression logic
- Countdown functionality (use MINUTES type for that)
- Notifications/nags specific to stopwatch
- Export/import changes (handled by existing JSON system)