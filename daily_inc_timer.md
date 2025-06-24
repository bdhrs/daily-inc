# Daily Inc Timer - Python Flet Project Breakdown

This document outlines the structure, components, data flow, and logic of the "Daily Inc Timer" application, originally built with Python and Flet. It's intended to assist in rebuilding the application as a Progressive Web App (PWA).

## 1. Project Overview

The "Daily Inc Timer" is a Progressive Web App (PWA) designed to help users track and manage daily incremental goals. It is accessible on both desktop and mobile browsers with offline capabilities. Users can define "Daily Things" they want to work on, specifying start/end values over a duration. The application calculates a daily target, allows users to log progress (especially for timed activities), and visually represents their status.

## 2. Core Data Models

These models are defined in `src/models.py`.

### `ItemType` (Enum)
Defines the type of item being tracked, influencing how values are interpreted and interacted with.
*   `MINUTES`: For time-based activities (e.g., meditation for X minutes).
*   `REPS`: For repetition-based activities (e.g., Y push-ups).
*   `CHECK`: For simple check-off tasks (done/not done).

### `HistoryEntry` (Dataclass)
Represents a record of progress for a `DailyThing` on a specific date.
*   `date: date`: The date of the entry.
*   `value: float`: The value achieved or logged on that date.
*   `to_dict()`: Converts to a JSON-serializable dictionary.
*   `from_dict()`: Creates an instance from a dictionary.

### `DailyThing` (Dataclass)
The central data model for an item being tracked.
*   **Attributes:**
    *   `name: str`: Name of the item.
    *   `item_type: ItemType`: The type of item.
    *   `start_date: date`: The date the tracking for this item begins.
    *   `start_value: float`: The initial value at the `start_date`.
    *   `duration: int`: The number of days over which the value progresses from `start_value` to `end_value`.
    *   `end_value: float`: The target value at the end of the `duration`.
    *   `history: list[HistoryEntry]`: A list of progress entries, initialized as an empty list.
*   **Properties:**
    *   `increment -> float`: Calculates the daily change in value.
        *   Formula: `(end_value - start_value) / duration`.
        *   Returns `0.0` if `duration <= 0`.
    *   `today_value -> float`: Calculates the target or current value for today. This is the most complex piece of logic:
        1.  Retrieves today's date.
        2.  Filters history for entries up to and including today, sorted descending by date.
        3.  Determines a `current_value_base` and `last_recorded_date`:
            *   If history exists, these are taken from the latest entry.
            *   Otherwise, they default to `self.start_value` and `self.start_date`.
        4.  If the latest history entry is for today, its value is returned directly.
        5.  **"Did Yesterday" Logic:** If the latest entry was yesterday:
            *   It compares yesterday's actual recorded value (`yesterdays_actual_value`) with the target value for yesterday (`_get_target_value_for_date(yesterday)`).
            *   Completion is judged based on whether the goal is increasing (`>=`) or decreasing (`<=`).
            *   If yesterday's goal was met: `calculated_value = yesterdays_actual_value + self.increment`.
            *   If not met: `calculated_value = yesterdays_actual_value`.
        6.  **"Did Not Do Yesterday / No Recent History" Logic:**
            *   Calculates `days_since_last_doing` (from `today` to `last_recorded_date`).
            *   If `days_since_last_doing <= 1` (i.e., today is the `last_recorded_date` or the day after, or it's the `start_date`): `calculated_value = current_value_base`.
            *   If `days_since_last_doing == 2`: `calculated_value = current_value_base` (implies a 1-day grace period before penalty).
            *   If `days_since_last_doing > 2`: A penalty is applied: `calculated_value = current_value_base - (self.increment * (days_since_last_doing - 2))`.
        7.  The final `today_value` is `max(calculated_value, self.start_value)` to ensure it doesn't drop below the initial start value.
*   **Methods:**
    *   `_get_target_value_for_date(specific_date: date) -> float`: Calculates the linearly interpolated target value for any given date based on `start_date`, `start_value`, `end_value`, and `duration`.
        *   Returns `start_value` if `specific_date < start_date`.
        *   Returns `end_value` if `duration <= 0` (and `specific_date >= start_date`).
        *   Returns `end_value` if `specific_date` is beyond the `start_date + duration`.
    *   `to_dict()`: Converts to a JSON-serializable dictionary.
    *   `from_dict()`: Creates an instance from a dictionary.

## 3. Data Management (`DataManager`)

Located in `src/data.py`, this class handles all data persistence.

*   **Storage:** Data is stored in a JSON file at `data/inc_timer_data.json` relative to the current working directory.
*   **`load_data() -> list[DailyThing]`:**
    *   Reads the JSON file.
    *   Handles cases like file not found, empty file, JSON decoding errors, and data conversion errors.
    *   Converts the list of dictionaries from JSON into a list of `DailyThing` objects using `DailyThing.from_dict()`.
*   **`save_data(items: list[DailyThing])`:**
    *   Converts the list of `DailyThing` objects into dictionaries using `item.to_dict()`.
    *   Writes the data to the JSON file with pretty printing (indent 4).
*   **`add_daily_thing(new_item: DailyThing)`:**
    *   Loads existing data, appends the `new_item`, and saves the updated list.
*   **`delete_daily_thing(item_to_delete: DailyThing)`:**
    *   Loads existing data, filters out the `item_to_delete` (relies on `DailyThing`'s default dataclass equality), and saves.
*   **`update_daily_thing(updated_item: DailyThing)`:**
    *   Loads existing data.
    *   Finds the item to update by comparing `name` attributes (assumes `name` is a unique identifier).
    *   Replaces the old item with `updated_item` and saves.
    *   Prints a warning if the item to update is not found.

## 4. User Interface (UI) Components & Flow

The UI is primarily managed by `DailyThingsView` and `AddDailyItemPopup`.

### Main Application Window (`main.py`)
*   Sets up the Flet `Page`.
*   Adds an `AppBar` with the title "Daily Inc Timer".
*   The main content is provided by `DailyThingsView.build_display()`.

### `DailyThingsView` (`src/daily_things_view.py`)
This class builds and manages the main interface for displaying and interacting with daily items.

*   **Initialization:**
    *   Loads `DailyThing` items using `DataManager`.
    *   Initializes an `flet_audio.Audio` component for playing a bell sound (uses a remote URL: `https://www.soundjay.com/mechanical/sounds/clong-2.mp3`).
*   **Main Display (`build_display()`):**
    *   A `ft.ReorderableListView` displays all `DailyThing` items. Each item is rendered by `_build_item_row()`.
        *   `on_reorder`: Calls `_handle_reorder()` to update data order and save.
    *   An "Add" `ft.IconButton` (plus icon) at the bottom, which calls `_open_add_daily_item_popup()` when clicked.
*   **Item Row (`_build_item_row(item: DailyThing) -> ft.Control`):**
    *   Constructs the visual representation for a single `DailyThing`.
    *   **Value Formatting (`format_value` helper):**
        *   `MINUTES`: `Xm` (e.g., `10m`) or `X:SS` (e.g., `10:30`).
        *   `REPS`: `Xx` (e.g., `15x`) or `X.Yx` (e.g., `15.5x`).
        *   `CHECK`: `✅` (if value >= 1) or `❌`.
    *   **Layout:**
        *   Top part: Item `name` and `today_container`.
        *   Bottom part: `start_value`, an arrow icon, `end_value`, and Edit/Delete icon buttons.
    *   **`today_container`:**
        *   Displays the formatted `item.today_value`.
        *   Background color: `ft.Colors.GREEN_900` if a history entry exists for today (goal considered reached/logged), otherwise `ft.Colors.RED_900`.
        *   `on_click`: If `item.item_type == ItemType.MINUTES`, it calls `_show_fullscreen_timer(item)`.
    *   **Edit/Delete Buttons:**
        *   Edit `ft.IconButton`: Calls `_edit_daily_thing(item)`.
        *   Delete `ft.IconButton`: Calls `_delete_daily_thing(item)`.
*   **Refreshing Display (`refresh_display()`):**
    *   Reloads data from `DataManager`.
    *   Clears and rebuilds the controls in `reorderable_list_view`.
    *   Updates the page. This is called after add/edit/delete operations.
*   **`_toggle_check_item(item: DailyThing)`:**
    *   *Note: This method is defined but **not currently wired to any UI interaction** for `ItemType.CHECK` items.*
    *   Logic: If a history entry for today exists for a `CHECK` item, it's removed (uncheck). Otherwise, a new entry with `value=1.0` is added (check). Data is saved and display refreshed.

### `AddDailyItemPopup` (`src/add_daily_item_popup.py`)
A `ft.AlertDialog` for creating new `DailyThing` items or editing existing ones.

*   **Mode:** "New Daily Thing" or "Edit Daily Thing" title based on whether an existing `daily_thing` is passed to `__init__`.
*   **Fields (pre-filled in edit mode):**
    *   `name_field: ft.TextField` (Name)
    *   `item_type_dropdown: ft.Dropdown` (Type: MINUTES, REPS, CHECK)
    *   `start_date_field: ft.TextField` (Start YYYY-MM-DD, defaults to today for new items)
    *   `start_value_field: ft.TextField` (Start Value, numeric)
    *   `duration_field: ft.TextField` (Duration in days, numeric)
    *   `end_value_field: ft.TextField` (End Value, numeric)
*   **Actions:**
    *   "Cancel" button: Closes the dialog.
    *   "Add" / "Update" button: Calls `_submit_daily_item()`.
*   **Submission (`_submit_daily_item()`):**
    1.  **Validation:** Checks if all required fields have values. If not, sets `error_text` on the respective field and updates the UI.
    2.  **Data Parsing:** Converts string inputs from fields to their appropriate types (`str`, `ItemType`, `date`, `float`, `int`).
    3.  **History Preservation:** If in edit mode, the existing `history` of the item is preserved.
    4.  **Object Creation/Update:** A `DailyThing` object is created or updated with the form data.
    5.  **Data Persistence:** Calls `data_manager.add_daily_thing()` or `data_manager.update_daily_thing()`.
    6.  **UI Update:** Closes the dialog, updates the page, and calls the `on_submit_callback` (which is `DailyThingsView.refresh_display`).
    7.  **Error Handling:** Catches `ValueError` (e.g., bad date format, non-numeric input) and other `Exception`s, displaying an error message in a `ft.SnackBar`.

### Timer View (`_show_fullscreen_timer(item: DailyThing)` in `DailyThingsView`)
Displayed when the `today_container` of a `MINUTES` item is clicked.

*   **Setup:**
    *   Calculates `total_seconds` from `item.today_value` (which is in minutes).
    *   The current page content is cleared (`self.page.clean()`).
*   **UI Elements:**
    *   `timer_text: ft.Text`: Displays the remaining time (MM:SS format), large font.
    *   `start_pause_button: ft.ElevatedButton`: Text "Start" or "Pause". Calls `toggle_timer()`.
    *   `exit_button: ft.ElevatedButton`: Text "Exit". Calls `_exit_timer_display()`.
    *   These are centered on the page.
*   **Timer Logic (`toggle_timer` and `run_countdown` nested functions):**
    *   `is_paused` flag manages the timer state.
    *   `run_countdown()`:
        *   A `while` loop runs as long as `remaining_seconds >= 0` and `is_paused` is false.
        *   Inside the loop:
            *   Updates `timer_text.value`.
            *   Updates `self.page.update()`.
            *   `time.sleep(1)`: Pauses for one second.
            *   Decrements `remaining_seconds`.
        *   **Timer Completion (`remaining_seconds < 0`):**
            *   Plays the bell sound (`_play_bell_sound()`).
            *   Creates a `HistoryEntry` for today with `value = item.today_value` (the target minutes).
            *   Updates the `item.history`: if an entry for today already exists, its value is updated; otherwise, the new entry is appended.
            *   Saves data using `self.data_manager.save_data()`.
*   **Exiting Timer (`_exit_timer_display()`):**
    *   Clears the page (`self.page.clean()`).
    *   Rebuilds and adds the main `DailyThingsView` display back to the page.

## 5. Key Logic/Algorithms

*   **`DailyThing.today_value` Calculation:** See section 2 for the detailed breakdown. This is crucial for determining the daily dynamic target.
*   **`DailyThing.increment` Calculation:** Simple linear increment: `(end_value - start_value) / duration`.
*   **Timer Countdown and History Update:** As described in the Timer View section. The timer logs completion by adding/updating a `HistoryEntry` with the *target* minutes for that day, not the actual elapsed time if paused early (though the current UI doesn't allow exiting the timer early and logging partial progress).
*   **Reordering:** The `ft.ReorderableListView` handles UI reordering. The `_handle_reorder` callback updates the in-memory list (`self.daily_things`) and then calls `self.data_manager.save_data()` to persist the new order.

## 6. Assets

*   **Audio:** A bell sound is played upon timer completion. The code uses a URL: `https://www.soundjay.com/mechanical/sounds/clong-2.mp3`. An `assets_dir="assets"` is specified when running `ft.app`, implying local assets could also be used (e.g., a local `audio/bell.mp3` was mentioned in comments but the URL is used in practice).

## 7. Potential PWA Equivalents and Considerations

When rebuilding as a Progressive Web App (PWA), consider these equivalents and technologies:

*   **Core UI Structure:**
    *   Flet `Page` -> HTML structure with `<div>` or framework components (e.g., React components)
    *   Flet `AppBar` -> Custom header or navigation bar using HTML/CSS
    *   Flet `Column`, `Row` -> CSS Flexbox or Grid for layout
    *   Flet `Container` -> HTML `<div>` with CSS for styling, padding, and margin
    *   Flet `Text` -> HTML text elements like `<p>` or `<span>`
    *   Flet `IconButton`, `ElevatedButton` -> HTML `<button>` with CSS styling or framework components
*   **Input Fields:**
    *   Flet `TextField` -> HTML `<input>` or `<textarea>` with JavaScript for validation
    *   Flet `Dropdown` -> HTML `<select>` or custom dropdown components
*   **Lists:**
    *   Flet `ReorderableListView` -> HTML lists with drag-and-drop APIs or libraries like SortableJS
*   **Dialogs/Popups:**
    *   Flet `AlertDialog` -> HTML `<dialog>` element or custom modal components with CSS/JavaScript
*   **Navigation/Views:**
    *   Flet `page.clean()`, `page.add()` for view changes -> DOM manipulation with JavaScript or routing libraries (e.g., React Router)
*   **Data Persistence:**
    *   JSON serialization/deserialization: JavaScript's native `JSON.parse()` and `JSON.stringify()`
    *   Storage: Use `LocalStorage` for simple data or `IndexedDB` for more complex storage needs
*   **Audio:**
    *   `flet_audio` -> HTML5 `Audio` API or compatible libraries like Howler.js
*   **State Management:**
    *   Flet's model updates triggering UI refreshes -> Use frameworks like React with hooks for state management, or vanilla JavaScript for simpler apps
*   **Date/Time:**
    *   Python `datetime.date` -> JavaScript `Date` object with libraries like Moment.js or date-fns for formatting
*   **Async Operations & Timers:**
    *   Python `time.sleep(1)` in a loop (for timer) -> JavaScript `setInterval` or `requestAnimationFrame` for non-blocking updates

**Important Considerations for PWA Rebuild:**

*   **Responsive Design:** Ensure the UI adapts to various screen sizes using CSS media queries.
*   **Offline Capabilities:** Implement Service Workers for caching and offline functionality to allow the app to work without an internet connection.
*   **Installability:** Use a Web App Manifest to make the app installable on home screens, providing a native-like experience.
*   **State Management:** Decide on using a framework like React for complex state handling or vanilla JavaScript for simpler implementations.
*   **Uniqueness of `DailyThing.name`:** Maintain the assumption that `name` is unique for updates, or implement a different identifier strategy.
*   **`ItemType.CHECK` Interaction:** Enable direct interaction for `CHECK` items by binding click events to toggle their state.
*   **Error Handling:** Display errors using browser alerts, custom modals, or inline messages for user feedback.
*   **Timer Implementation:** Use JavaScript's non-blocking timer mechanisms like `setInterval` for countdowns.
*   **Browser Compatibility:** Test and ensure compatibility for critical APIs across major browsers.
