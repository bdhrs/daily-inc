# Note View Feature Specification

## 1. Overview

The Note View is a new full-screen display for `MINUTES` type tasks that integrates the timer functionality with a rich note-taking and viewing area. It will replace the current "Display Notes" menu item, providing a more immersive and functional experience for users who rely on notes during their timed activities.

The Note View is a specialized Timer View, and is triggered from the Timer View menu.

The user interface is based on the provided sketch:



## 2. UI Components

The screen is divided into three main areas:

### 2.1. Top Information Bar

This bar provides real-time timer status.

*   **Left Side: Timer Control Button**
    *   Displays "Start", "Pause", and "Continue" icons/text.
    *   The state of this button must be perfectly synchronized with the main timer logic in `TimerView`.
    *   It will call the same functions that the existing timer's main button uses.

*   **Center: Time Display**
    *   Shows `current_time_left` / `total_time`.
    *   Example: `15:31 / 30:00`.
    *   When the timer goes into overtime, the display should mimic the overtime display in the `TimerView` (e.g., `30:00 +05:31 `).

*   **Right Side: Subdivision Display**
    *   Shows `current_subdivision` / `total_subdivisions`.
    *   Example: `8 / 15`.
    *   This is only visible if the `DailyThing` has subdivisions enabled.

### 2.2. Main Notes Display

This is the central area of the view.

*   It will display the notes associated with the `DailyThing`. The notes are stored in the `notes` field of the `DailyThing`.
*   The notes will be rendered using a Markdown renderer. This will support formatted text (headings, lists, bold, etc.) and will also display plain text correctly. The `flutter_markdown` package will be used for this.

### 2.3. Bottom Action Buttons

*   **Edit Note Button:**
    *   This button will open a text editing view (or dialog) to allow the user to modify the notes for item.
    *   After saving, the main notes display should update to reflect the changes.

*   **Close Button:**
    *   This button will close the `NoteView` and return the user to the main timer screen.

## 3. Functional Requirements

*   **Integration with Timer Logic:** The `NoteView` must not create its own timer logic. It must hook into the existing timer state from `TimerView`. When the timer is started, paused, or reset in `NoteView`, the state should be reflected in the main app and vice-versa if the user navigates away and back.
*   **State Management:** The view must correctly manage its state, especially the timer's state and the note content.
*   **Navigation:** The `NoteView` will be launched from the `DailyThingItem` for `MINUTES` tasks, replacing the existing "Display Notes" option.

## 4. Non-Functional Requirements

*   **Performance:** The view should be responsive and not introduce any lag, especially with the timer running.
*   **UI Consistency:** The design should match the existing application's theme and style (`AppTheme`, `ColorPalette`).
*   **Readability:** The notes display should be clear and easy to read, with appropriate font sizes and padding.

## 5. Implementation Plan

This section details the step-by-step plan for implementing the Note View feature by adding a new mode to the existing `TimerView` widget, rather than creating a separate widget. This approach minimizes code duplication and complexity.

### 5.1. Add State Management for Note View Mode

**Problem:** We need a way to track whether the TimerView is in normal mode or note view mode.

**Solution:** 
1. Add a new boolean state variable `_isNoteViewMode` to `_TimerViewState` class, initialized to `false`.
2. Add a method `_toggleNoteViewMode()` that toggles this state and calls `setState()`.

**Progress:**
- [x] Add `_isNoteViewMode` state variable
- [x] Add `_toggleNoteViewMode()` method

### 5.2. Modify TimerView UI to Support Note View Mode

**Problem:** The existing `TimerView` UI needs to be conditionally replaced with the Note View UI when in note view mode.

**Solution:**
1. In the `build()` method of `TimerView`, wrap the existing UI structure with a conditional check for `_isNoteViewMode`.
2. When `_isNoteViewMode` is `false`, render the existing UI unchanged.
3. When `_isNoteViewMode` is `true`, render the new Note View UI structure.

**Progress:**
- [x] Modify `build()` method to conditionally render UI based on `_isNoteViewMode`

### 5.3. Implement Note View UI Components

#### 5.3.1. Top Information Bar

**Problem:** We need to create a horizontal top bar that displays timer information in note view mode.

**Solution:**
1. Create a new widget or layout structure for the top information bar.
2. Display the timer control button (reusing existing `_getButtonText()` and `_toggleTimer()`).
3. Display the time information (reusing existing time calculation and formatting logic).
4. Display the subdivision information if applicable (reusing existing subdivision logic).

**Progress:**
- [x] Implement Top Information Bar widget/layout
- [x] Integrate timer control button
- [x] Integrate time display
- [x] Integrate subdivision display

#### 5.3.2. Main Notes Display

**Problem:** We need to display the notes from `DailyThing` with Markdown rendering in the center of the screen.

**Solution:**
1. Use the `flutter_markdown` package to render the notes.
2. Access the notes from `widget.item.notes`.
3. Handle the case where notes might be null or empty.
4. Ensure the Markdown display is scrollable for long notes.

**Progress:**
- [x] Implement Main Notes Display using `MarkdownBody`
- [x] Handle null/empty notes case
- [x] Make notes display scrollable

#### 5.3.3. Bottom Action Buttons

**Problem:** We need to create buttons at the bottom for editing notes and closing the note view.

**Solution:**
1. Create a row of buttons at the bottom of the screen.
2. Implement "Edit Note" button that opens the note editing dialog.
3. Implement "Close" button that switches back to normal timer mode.

**Progress:**
- [x] Implement Bottom Action Buttons row
- [x] Implement "Edit Note" button functionality
- [x] Implement "Close" button functionality

### 5.4. Integrate with TimerView Menu

**Problem:** The current menu has a "View Note" option that opens a dialog. We need to replace this with an option to enter note view mode.

**Solution:**
1. Locate the popup menu in `TimerView` that contains the "View Note" option.
2. Replace "View Note" with "Show Note View".
3. Make the "Show Note View" option call `_toggleNoteViewMode()` to switch to note view mode.
4. Only show this option when the item has notes.

**Progress:**
- [x] Modify popup menu to replace "View Note" with "Show Note View"
- [x] Implement menu action to call `_toggleNoteViewMode()`

### 5.5. Handle Navigation and Exit

**Problem:** We need to ensure users can exit note view mode and return to normal timer mode.

**Solution:**
1. The "Close" button in the bottom action bar should call `_toggleNoteViewMode()` to switch back to normal mode.
2. The system back button should also exit note view mode when in note view mode.
3. Handle any necessary state updates when switching modes.

**Progress:**
- [x] Implement "Close" button navigation
- [x] Implement system back button handling for note view mode

### 5.6. Verification and Testing

**Problem:** We need to ensure the implementation meets all requirements and doesn't introduce bugs.

**Solution:**
1. Test switching between normal mode and note view mode.
2. Verify that timer state is preserved when switching modes.
3. Test that the note display correctly renders Markdown.
4. Test note editing functionality.
5. Verify that the UI matches the application's theme and style.
6. Test performance to ensure no lag is introduced.

**Progress:**
- [ ] Test mode switching
- [ ] Verify timer state preservation
- [ ] Test note display and editing
- [ ] Verify UI consistency
- [ ] Test performance