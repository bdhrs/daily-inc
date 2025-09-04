# Project Map

This document provides a map of the project, listing the location of all functions, classes, and important variables. Each entry also includes a simple one-line description in plain English.

## lib/main.dart
- `main()` [`lib/main.dart:10`](lib/main.dart:10): Starts the app, sets up logging, loads saved data, and launches the UI.
- `MyApp` class [`lib/main.dart:48`](lib/main.dart:48): The root app widget managing global focus and theming.
  - `build(BuildContext context)` method [`lib/main.dart:65`](lib/main.dart:65): Builds the MaterialApp with themes and the home screen.
  - Keyboard shortcut Ctrl/Cmd+Q: quits the app on desktop or pops on mobile [`lib/main.dart:69`](lib/main.dart:69): Handy quick-exit key handler.

## lib/src/core/time_converter.dart
- `TimeConverter` class [`lib/src/core/time_converter.dart:1`](lib/src/core/time_converter.dart:1): Handles conversions between decimal minutes and minutes/seconds components.
  - `fromDecimalMinutes(double decimalMinutes)` [`lib/src/core/time_converter.dart:7`](lib/src/core/time_converter.dart:7): Converts decimal minutes to TimeComponents object.
  - `toDecimalMinutes(int minutes, int seconds)` [`lib/src/core/time_converter.dart:32`](lib/src/core/time_converter.dart:32): Converts minutes and seconds to decimal format.
  - `toMmSsString(double decimalMinutes, {bool padZeroes = false})` [`lib/src/core/time_converter.dart:42`](lib/src/core/time_converter.dart:42): Formats decimal minutes as MM:SS string.
  - `toSmartString(double decimalMinutes)` [`lib/src/core/time_converter.dart:47`](lib/src/core/time_converter.dart:47): Smart formatting (5m for whole, 5:30 for fractional).
  - `toTotalSeconds(double decimalMinutes)` [`lib/src/core/time_converter.dart:57`](lib/src/core/time_converter.dart:57): Converts decimal minutes to total seconds.
  - `fromTotalSeconds(int totalSeconds)` [`lib/src/core/time_converter.dart:62`](lib/src/core/time_converter.dart:62): Converts total seconds to decimal minutes.
  - `validateMinutes(int minutes)` [`lib/src/core/time_converter.dart:67`](lib/src/core/time_converter.dart:67): Validates minutes value.
  - `validateSeconds(int seconds)` [`lib/src/core/time_converter.dart:72`](lib/src/core/time_converter.dart:72): Validates seconds value (0-59).

- `TimeComponents` class [`lib/src/core/time_converter.dart:77`](lib/src/core/time_converter.dart:77): Data class representing minutes and seconds components.
  - `toString({bool padZeroes = false})` [`lib/src/core/time_converter.dart:85`](lib/src/core/time_converter.dart:85): Returns formatted string.
  - `toDecimal()` [`lib/src/core/time_converter.dart:94`](lib/src/core/time_converter.dart:94): Converts to decimal minutes.
  - `toTotalSeconds()` [`lib/src/core/time_converter.dart:99`](lib/src/core/time_converter.dart:99): Converts to total seconds.

## lib/src/core/value_converter.dart
- `ValueConverter` class [`lib/src/core/value_converter.dart:4`](lib/src/core/value_converter.dart:4): Handles conversions between different item types when changing task types.
  - `convert(DailyThing original, ItemType newType)` [`lib/src/core/value_converter.dart:5`](lib/src/core/value_converter.dart:5): Converts a DailyThing from one type to another, handling value conversions appropriately. Now includes PERCENTAGE and TREND type conversions.

## lib/src/core/increment_calculator.dart
- `IncrementCalculator` class [`lib/src/core/increment_calculator.dart:7`](lib/src/core/increment_calculator.dart:7): Calculates targets, display values, and status for daily items.
  - `setGracePeriod(int days)` [`lib/src/core/increment_calculator.dart:10`](lib/src/core/increment_calculator.dart:10): Sets the grace period.
  - `getGracePeriod()` [`lib/src/core/increment_calculator.dart:15`](lib/src/core/increment_calculator.dart:15): Gets the current grace period.
  - `calculateIncrement(DailyThing item)` [`lib/src/core/increment_calculator.dart:20`](lib/src/core/increment_calculator.dart:20): Finds the per-day change from start to end over the duration.
  - `getLastCompletedDate(List<HistoryEntry> history)` [`lib/src/core/increment_calculator.dart:32`](lib/src/core/increment_calculator.dart:32): Gets the most recent day you marked the task as done.
  - `getLastEntryDate(List<HistoryEntry> history)` [`lib/src/core/increment_calculator.dart:45`](lib/src/core/increment_calculator.dart:45): Finds the date of the latest history record.
  - `calculateDaysMissed(DateTime lastEntryDate, DateTime todayDate)` [`lib/src/core/increment_calculator.dart:54`](lib/src/core/increment_calculator.dart:54): Counts how many days were skipped since the last entry.
  - `isDue(DailyThing item, DateTime date)` [`lib/src/core/increment_calculator.dart:59`](lib/src/core/increment_calculator.dart:59): Determines if a task is due on a given date.
  - `calculateTodayValue(DailyThing item)` [`lib/src/core/increment_calculator.dart:120`](lib/src/core/increment_calculator.dart:120): Computes today's target based on progress rules and gaps.
  - `calculateDisplayValue(DailyThing item)` [`lib/src/core/increment_calculator.dart:210`](lib/src/core/increment_calculator.dart:210): Chooses what number to show today (target or actual) depending on type.
  - `isDone(DailyThing item, double currentValue)` [`lib/src/core/increment_calculator.dart:280`](lib/src/core/increment_calculator.dart:280): Tells if today's goal is met for the item.
  - `determineStatus(DailyThing item, double currentValue)` [`lib/src/core/increment_calculator.dart:301`](lib/src/core/increment_calculator.dart:301): Returns green or red status based on today's target.

## lib/src/data/data_manager.dart
- `DataManager` class [`lib/src/data/data_manager.dart:11`](lib/src/data/data_manager.dart:11): Loads, saves, and manages items and metadata on disk.
  - `loadFromFile()` [`lib/src/data/data_manager.dart:14`](lib/src/data/data_manager.dart:14): Lets you pick a JSON file and imports items, fixing missing fields if needed. Now includes platform-specific file picker handling for Linux.
  - `_getFilePath()` [`lib/src/data/data_manager.dart:82`](lib/src/data/data_manager.dart:82): Finds the app's data file location.
  - `_readRawStore()` [`lib/src/data/data_manager.dart:87`](lib/src/data/data_manager.dart:87): Reads raw JSON data from storage.
  - `_writeRawStore(Map<String, dynamic> data)` [`lib/src/data/data_manager.dart:109`](lib/src/data/data_manager.dart:109): Writes raw JSON data to storage.
  - `loadData()` [`lib/src/data/data_manager.dart:119`](lib/src/data/data_manager.dart:119): Loads the list of items from the app's data file.
  - `saveData(List<DailyThing> items)` [`lib/src/data/data_manager.dart:135`](lib/src/data/data_manager.dart:135): Saves all items back to the data file.
  - `addDailyThing(DailyThing newItem)` [`lib/src/data/data_manager.dart:148`](lib/src/data/data_manager.dart:148): Adds a new item and saves.
  - `deleteDailyThing(DailyThing itemToDelete)` [`lib/src/data/data_manager.dart:156`](lib/src/data/data_manager.dart:156): Removes an item and saves.
  - `updateDailyThing(DailyThing updatedItem)` [`lib/src/data/data_manager.dart:164`](lib/src/data/data_manager.dart:164): Updates an existing item and saves.
  - `resetAllData()` [`lib/src/data/data_manager.dart:178`](lib/src/data/data_manager.dart:178): Deletes the stored data file to start fresh.
  - `archiveDailyThing(DailyThing item)` [`lib/src/data/data_manager.dart:202`](lib/src/data/data_manager.dart:202): Archives a daily thing item.
  - `unarchiveDailyThing(DailyThing item)` [`lib/src/data/data_manager.dart:209`](lib/src/data/data_manager.dart:209): Unarchives a daily thing item.
  - `saveHistoryToFile()` [`lib/src/data/data_manager.dart:194`](lib/src/data/data_manager.dart:194): Exports all current data to a JSON file via a save dialog. Now includes platform-specific file picker handling for Linux.
  - `saveTemplateToFile()` [`lib/src/data/data_manager.dart:215`](lib/src/data/data_manager.dart:215): Exports all current data without history to a JSON template file via a save dialog. Now includes platform-specific file picker handling for Linux.
  - `getUniqueCategories()` [`lib/src/data/data_manager.dart:245`](lib/src/data/data_manager.dart:245): Lists all unique categories (except "None").
  - `getUniqueCategoriesForType(ItemType type)` [`lib/src/data/data_manager.dart:262`](lib/src/data/data_manager.dart:262): Lists unique categories only for the given type.
  - `getLastMotivationShownDate()` [`lib/src/data/data_manager.dart:280`](lib/src/data/data_manager.dart:280): Reads the date when the motivation dialog was last shown.
  - `setLastMotivationShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:290`](lib/src/data/data_manager.dart:290): Stores today's date as the last shown motivation.
  - `getLastCompletionShownDate()` [`lib/src/data/data_manager.dart:305`](lib/src/data/data_manager.dart:305): Reads the date when the completion dialog was last shown.
  - `setLastCompletionShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:315`](lib/src/data/data_manager.dart:315): Stores today's date as the last shown completion message.

## lib/src/data/history_manager.dart
- `HistoryManager` class [`lib/src/data/history_manager.dart:6`](lib/src/data/history_manager.dart:6): Safely updates future targets when plan settings change without altering past records.
  - `updateHistoryEntriesWithNewParameters({...})` [`lib/src/data/history_manager.dart:13`](lib/src/data/history_manager.dart:13): Recomputes targets for today and future based on new plan while keeping history intact.

## lib/src/models/daily_thing.dart
- `_logger` variable [`lib/src/models/daily_thing.dart:8`](lib/src/models/daily_thing.dart:8): Logs messages for this model.
- `DailyThing` class [`lib/src/models/daily_thing.dart:10`](lib/src/models/daily_thing.dart:10): Represents a daily task with rules, history, and settings.
  - `increment` getter [`lib/src/models/daily_thing.dart:45`](lib/src/models/daily_thing.dart:45): Gives the per-day change for this task.
  - `todayValue` getter [`lib/src/models/daily_thing.dart:49`](lib/src/models/daily_thing.dart:49): Gives today's target for this task.
  - `displayValue` getter [`lib/src/models/daily_thing.dart:53`](lib/src/models/daily_thing.dart:53): Gives what to show in the UI today.
  - `determineStatus(double currentValue)` [`lib/src/models/daily_thing.dart:57`](lib/src/models/daily_thing.dart:57): Returns green/red status for the current value.
  - `isDone(double currentValue)` [`lib/src/models/daily_thing.dart:61`](lib/src/models/daily_thing.dart:61): Tells if today is completed for this task.
  - `lastCompletedDate` getter [`lib/src/models/daily_thing.dart:65`](lib/src/models/daily_thing.dart:65): Finds when you last finished this task.
  - `todayHistoryEntry` getter [`lib/src/models/daily_thing.dart:69`](lib/src/models/daily_thing.dart:69): Gets the history entry for today, if it exists.
  - `isSnoozedForToday` getter [`lib/src/models/daily_thing.dart:77`](lib/src/models/daily_thing.dart:77): Checks if the task has been marked as snoozed for today.
  - `isDueToday` getter [`lib/src/models/daily_thing.dart:81`](lib/src/models/daily_thing.dart:81): Says if the task needs doing today based on its frequency.
  - `completedForToday` getter [`lib/src/models/daily_thing.dart:128`](lib/src/models/daily_thing.dart:128): Says if today counts as done (if not due, it's considered done).
  - `hasBeenDoneLiterallyToday` getter [`lib/src/models/daily_thing.dart:145`](lib/src/models/daily_thing.dart:145): Checks if today's history entry is explicitly marked as done.
  - `shouldShowInList` getter [`lib/src/models/daily_thing.dart:156`](lib/src/models/daily_thing.dart:156): Determines if this item should be shown in the list based on due status and completion.
  - `toJson()` [`lib/src/models/daily_thing.dart:168`](lib/src/models/daily_thing.dart:168): Converts this item to a JSON map.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/daily_thing.dart:190`](lib/src/models/daily_thing.dart:190): Builds the item from a JSON map.
  - `copyWith({...})` [`lib/src/models/daily_thing.dart:232`](lib/src/models/daily_thing.dart:232): Creates a copy of the item with specified fields updated.
  - `isArchived` field [`lib/src/models/daily_thing.dart:33`](lib/src/models/daily_thing.dart:33): Indicates whether the item is archived (hidden from main view).

## lib/src/models/history_entry.dart
- `_logger` variable [`lib/src/models/history_entry.dart:3`](lib/src/models/history_entry.dart:3): Logs parsing warnings for history.
- `HistoryEntry` class [`lib/src/models/history_entry.dart:5`](lib/src/models/history_entry.dart:5): A single day's record of target/actual progress, with optional comment and snoozed status.
  - `toJson()` [`lib/src/models/history_entry.dart:18`](lib/src/models/history_entry.dart:18): Converts the entry to a JSON map.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/history_entry.dart:27`](lib/src/models/history_entry.dart:27): Parses a JSON map into an entry with safe fallbacks.
  - `copyWith({...})` [`lib/src/models/history_entry.dart:72`](lib/src/models/history_entry.dart:72): Creates a copy of the entry with specified fields updated.
  - `comment` field [`lib/src/models/history_entry.dart:7`](lib/src/models/history_entry.dart:7): Stores an optional comment for the history entry.

## lib/src/models/interval_type.dart
- `IntervalType` enum [`lib/src/models/interval_type.dart:1`](lib/src/models/interval_type.dart:1): Defines whether an item repeats by a number of days or on specific weekdays.

## lib/src/models/item_type.dart
- `ItemType` enum [`lib/src/models/item_type.dart:1`](lib/src/models/item_type.dart:1): The type of task: minutes, reps, check, percentage, or trend.

## lib/src/models/status.dart
- `Status` enum [`lib/src/models/status.dart:1`](lib/src/models/status.dart:1): Simple green or red state for display.

## lib/src/services/backup_service.dart
- `BackupService` class [`lib/src/services/backup_service.dart:9`](lib/src/services/backup_service.dart:9): Handles automatic backups with user-configurable settings.
  - `isBackupEnabled()` [`lib/src/services/backup_service.dart:22`](lib/src/services/backup_service.dart:22): Checks if automatic backups are enabled.
  - `setBackupEnabled(bool enabled)` [`lib/src/services/backup_service.dart:28`](lib/src/services/backup_service.dart:28): Enables or disables automatic backups.
  - `getBackupLocation()` [`lib/src/services/backup_service.dart:35`](lib/src/services/backup_service.dart:35): Gets the backup directory path.
  - `setBackupLocation(String path)` [`lib/src/services/backup_service.dart:41`](lib/src/services/backup_service.dart:41): Sets the backup directory path.
  - `getBackupRetentionDays()` [`lib/src/services/backup_service.dart:48`](lib/src/services/backup_service.dart:48): Gets backup retention days setting.
  - `setBackupRetentionDays(int days)` [`lib/src/services/backup_service.dart:55`](lib/src/services/backup_service.dart:55): Sets backup retention days.
  - `shouldShowBackupPrompt()` [`lib/src/services/backup_service.dart:90`](lib/src/services/backup_service.dart:90): Checks if backup prompt should be shown (after 1 day of first use, but not if backups are already enabled).
  - `createBackup(List<DailyThing> items)` [`lib/src/services/backup_service.dart:77`](lib/src/services/backup_service.dart:77): Creates timestamped backup and always keeps a "_latest" version.
  - `_cleanupOldBackups(Directory backupDir)` [`lib/src/services/backup_service.dart:129`](lib/src/services/backup_service.dart:129): Cleans up old backups while preserving the latest file.
  - `getAvailableBackups()` [`lib/src/services/backup_service.dart:158`](lib/src/services/backup_service.dart:158): Gets list of available backups.
  - `restoreFromBackup(File backupFile)` [`lib/src/services/backup_service.dart:176`](lib/src/services/backup_service.dart:176): Restores from a specific backup file.
  - `getDefaultBackupDirectory()` [`lib/src/services/backup_service.dart:196`](lib/src/services/backup_service.dart:196): Gets default backup directory.

## lib/src/services/update_service.dart
- `UpdateService` class [`lib/src/services/update_service.dart:14`](lib/src/services/update_service.dart:14): Handles app update checks, downloads, and installation.
  - `getLatestRelease()` [`lib/src/services/update_service.dart:11`](lib/src/services/update_service.dart:11): Fetches release details from the GitHub API.
  - `getCurrentAppVersion()` [`lib/src/services/update_service.dart:28`](lib/src/services/update_service.dart:28): Retrieves the current installed app version.
  - `isUpdateAvailable()` [`lib/src/services/update_service.dart:33`](lib/src/services/update_service.dart:33): Checks if a newer version is available on GitHub.
  - `getDownloadUrl()` [`lib/src/services/update_service.dart:61`](lib/src/services/update_service.dart:61): Figures out the correct asset download URL for the platform.
  - `downloadUpdate()` [`lib/src/services/update_service.dart:78`](lib/src/services/update_service.dart:78): Returns release URL but does not actually download the update (not implemented).
  - `installUpdate()` [`lib/src/services/update_service.dart:93`](lib/src/services/update_service.dart:93): Stub method that does not actually install updates (not implemented).

## lib/src/theme/app_theme.dart
- `AppTheme` class [`lib/src/theme/app_theme.dart:5`](lib/src/theme/app_theme.dart:5): Central place for the app's dark theme look and feel.
  - `darkTheme` getter [`lib/src/theme/app_theme.dart:6`](lib/src/theme/app_theme.dart:6): Provides colors, fonts, and styles for dark mode.
    - Uses `ColorPalette` tokens for consistent colors, customizes AppBar, Cards, Buttons, Inputs, SnackBars, Dialogs, Switches, ExpansionTiles, TimePicker, and Scrollbar.

## lib/src/theme/color_palette.dart
- `ColorPalette` class [`lib/src/theme/color_palette.dart:3`](lib/src/theme/color_palette.dart:3): Defines the app colors used across the UI.
  - Constants like `primaryBlue`, `darkBackground`, `cardBackground`, `inputBackground`, `lightText`, `blackText`, `secondaryText`, `warningOrange`, `partialYellow`, `onPartialYellow`, `scrollbarThumb` [`lib/src/theme/color_palette.dart:4`](lib/src/theme/color_palette.dart:4): Named colors for consistent styling.
  - Notes: `warningOrange` is used for undone/error states (including PERCENTAGE items with no entry), `primaryBlue` is used for completed/entered states (including PERCENTAGE items with values entered), `partialYellow` with `onPartialYellow` highlights partial progress.

## lib/src/views/add_edit_daily_item_view.dart
- `AddEditDailyItemView` class [`lib/src/views/add_edit_daily_item_view.dart:15`](lib/src/views/add_edit_daily_item_view.dart:15): Screen to create or edit a daily task.
- `_AddEditDailyItemViewState` class [`lib/src/views/add_edit_daily_item_view.dart:28`](lib/src/views/add_edit_daily_item_view.dart:28): Handles form state and input controllers.
  - `_submitDailyItem()` [`lib/src/views/add_edit_daily_item_view.dart:263`](lib/src/views/add_edit_daily_item_view.dart:263): Validates, updates history for plan changes, and saves.
  - `build(BuildContext context)` [`lib/src/views/add_edit_daily_item_view.dart:499`](lib/src/views/add_edit_daily_item_view.dart:499): Renders the item form UI.

## lib/src/views/category_graph_view.dart
- `CategoryGraphView` class [`lib/src/views/category_graph_view.dart:10`](lib/src/views/category_graph_view.dart:10): Shows graphs of progress for each category with time range filtering.

## lib/src/views/daily_thing_item.dart
- `DailyThingItem` class [`lib/src/views/daily_thing_item.dart:11`](lib/src/views/daily_thing_item.dart:11): A single task row with controls and quick actions.
- `_DailyThingItemState` class [`lib/src/views/daily_thing_item.dart:45`](lib/src/views/daily_thing_item.dart:45): Manages expansion and tap actions for the item.
  - `_formatValue(double value, ItemType itemType)` [`lib/src/views/daily_thing_item.dart:88`](lib/src/views/daily_thing_item.dart:8): Formats minutes, reps, percentage, trend, or check for display.
  - `build(BuildContext context)` [`lib/src/views/daily_thing_item.dart:107`](lib/src/views/daily_thing_item.dart:107): Draws the row UI and handles tap actions.
  - `_archiveItem(DailyThing item)` [`lib/src/views/daily_thing_item.dart:124`](lib/src/views/daily_thing_item.dart:124): Archives or unarchives an item.
  - `_buildActionButtons(DailyThing item)` [`lib/src/views/daily_thing_item.dart:350`](lib/src/views/daily_thing_item.dart:350): Builds the action buttons row with archive functionality.

## lib/src/views/daily_things_view.dart
- `DailyThingsView` class [`lib/src/views/daily_things_view.dart:25`](lib/src/views/daily_things_view.dart:25): The home screen that lists all tasks and actions.
- `_DailyThingsViewState` class [`lib/src/views/daily_things_view.dart:32`](lib/src/views/daily_things_view.dart:32): Loads, filters, reorders, and manages dialogs/snackbars.
  - `_showRepsInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:629`](lib/src/views/daily_things_view.dart:629): Prompts to enter reps and saves them.
  - `_showPercentageInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:640`](lib/src/views/daily_things_view.dart:640): Prompts to enter percentage (0-100%) via slider and saves them.
  - `_showTrendInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:651`](lib/src/views/daily_things_view.dart:651): Prompts to enter trend and saves it.
  - `_showFullscreenTimer(DailyThing item, {bool startInOvertime = false})` [`lib/src/views/daily_things_view.dart:700`](lib/src/views/daily_things_view.dart:700): Shows the fullscreen timer view with navigation context.
  - `build(BuildContext context)` [`lib/src/views/daily_things_view.dart:1047`](lib/src/views/daily_things_view.dart:1047): Builds filters, menus, the reorderable task list, and uses the DailyThingsAppBar widget.
  - `_toggleShowArchivedItems()` [`lib/src/views/daily_things_view.dart:65`](lib/src/views/daily_things_view.dart:65): Toggles between showing and hiding archived items.
  - `_filterDisplayedItems(List<DailyThing> allItems)` [`lib/src/views/daily_things_view.dart:950`](lib/src/views/daily_things_view.dart:950): Filters items based on archived status and other criteria.

## lib/src/views/help_view.dart
- `HelpView` class [`lib/src/views/help_view.dart:8`](lib/src/views/help_view.dart:8): A screen that explains how to use the app.

## lib/src/views/reps_input_dialog.dart
- `RepsInputDialog` class [`lib/src/views/reps_input_dialog.dart:7`](lib/src/views/reps_input_dialog.dart:7): Dialog to enter how many reps you did today.
  - `item`/`dataManager`/`onSuccess` [`lib/src/views/reps_input_dialog.dart:8`](lib/src/views/reps_input_dialog.dart:8): Inputs for saving today's reps and updating UI.
  - `build(BuildContext context)` [`lib/src/views/reps_input_dialog.dart:21`](lib/src/views/reps_input_dialog.dart:21): Renders the input field and buttons.
  - `_handleSubmit(BuildContext, String, VoidCallback)` [`lib/src/views/reps_input_dialog.dart:61`](lib/src/views/reps_input_dialog.dart:61): Validates and saves reps for today, then calls success.

## lib/src/views/percentage_input_dialog.dart
- `PercentageInputDialog` class [`lib/src/views/percentage_input_dialog.dart:7`](lib/src/views/percentage_input_dialog.dart:7): Dialog to enter percentage completion (0-100%) for a task with slider and text input.
  - `item`/`dataManager`/`onSuccess` [`lib/src/views/percentage_input_dialog.dart:8`](lib/src/views/percentage_input_dialog.dart:8): Inputs for saving today's percentage and updating UI.
  - `build(BuildContext context)` [`lib/src/views/percentage_input_dialog.dart:36`](lib/src/views/percentage_input_dialog.dart:36): Renders a comprehensive percentage input UI with slider, numeric input field, visual feedback, and action buttons. Uses theme colors (orange when not entered, blue when entered).
  - `_handleSubmit(BuildContext, String, VoidCallback)` [`lib/src/views/percentage_input_dialog.dart:86`](lib/src/views/percentage_input_dialog.dart:86): Validates and saves percentage (0-100) for today, then calls success. Handles both slider and text input validation.

## lib/src/views/trend_input_dialog.dart
- `TrendInputDialog` class [`lib/src/views/trend_input_dialog.dart:6`](lib/src/views/trend_input_dialog.dart:6): Dialog to enter trend for the day with optional comment.
- `_TrendInputDialogState` class [`lib/src/views/trend_input_dialog.dart:22`](lib/src/views/trend_input_dialog.dart:22): Manages the state for the trend input dialog, including comment handling.
  - `build(BuildContext context)` [`lib/src/views/trend_input_dialog.dart:46`](lib/src/views/trend_input_dialog.dart:46): Renders the trend input dialog with comment field.
  - `_buildTrendButton(BuildContext context, String text, double value)` [`lib/src/views/trend_input_dialog.dart:65`](lib/src/views/trend_input_dialog.dart:65): Renders a button for a trend option.
  - `_buildCommentField()` [`lib/src/views/trend_input_dialog.dart:75`](lib/src/views/trend_input_dialog.dart:75): Renders the comment input field.
  - `_handleSubmit(BuildContext context, double selectedValue)` [`lib/src/views/trend_input_dialog.dart:89`](lib/src/views/trend_input_dialog.dart:89): Saves the selected trend value with optional comment.
  - `_loadExistingComment()` [`lib/src/views/trend_input_dialog.dart:39`](lib/src/views/trend_input_dialog.dart:39): Loads existing comment from today's history entry.

## lib/src/views/settings_view.dart
- `SettingsView` class [`lib/src/views/settings_view.dart:8`](lib/src/views/settings_view.dart:8): Settings screen for filters, data actions, and backup configuration.
- `_SettingsViewState` class [`lib/src/views/settings_view.dart:15`](lib/src/views/settings_view.dart:15): Loads preferences and handles save/reset.
  - `build(BuildContext context)` [`lib/src/views/settings_view.dart:224`](lib/src/views/settings_view.dart:224): Renders the settings UI with motivational message controls, grace period slider, screen dimmer toggle, backup configuration section, and warning icon on reset button.

## lib/src/views/history_view.dart
- `HistoryView` class [`lib/src/views/history_view.dart:8`](lib/src/views/history_view.dart:8): A screen to view and edit the history of a daily item.
- `_HistoryViewState` class [`lib/src/views/history_view.dart:15`](lib/src/views/history_view.dart:15): Manages the state for the history view.
  - `build(BuildContext context)` [`lib/src/views/history_view.dart:55`](lib/src/views/history_view.dart:55): Renders the history list with editable fields.

## lib/src/views/timer_view.dart
- `TimerView` class [`lib/src/views/timer_view.dart:11`](lib/src/views/timer_view.dart:11): A full-screen, minimalist timer for 'Minutes' tasks.
- `_TimerViewState` class [`lib/src/views/timer_view.dart:27`](lib/src/views/timer_view.dart:27): Manages all timer states: countdown, paused, finished, and overtime.
  - `build(BuildContext context)` method [`lib/src/views/timer_view.dart:395`](lib/src/views/timer_view.dart:395): Renders the main UI with a responsive timer, info text, comment field, and controls. Includes the screen dimmer overlay.
  - `_navigateToNextTask()` method [`lib/src/views/timer_view.dart:550`](lib/src/views/timer_view.dart:550): Navigates to the next undone task in the list or exits to main UI.
  - `_findNextUndoneTask()` method [`lib/src/views/timer_view.dart:500`](lib/src/views/timer_view.dart:500): Finds the next undone task in the list after the current item.
## lib/src/views/widgets/next_task_arrow.dart
- `NextTaskArrow` class [`lib/src/views/widgets/next_task_arrow.dart:6`](lib/src/views/widgets/next_task_arrow.dart:6): A pulsing arrow button that appears when a timer completes.
  - `build(BuildContext context)` method [`lib/src/views/widgets/next_task_arrow.dart:45`](lib/src/views/widgets/next_task_arrow.dart:45): Renders a pulsing arrow icon positioned in the bottom right of the screen.

## lib/src/views/widgets/daily_things_helpers.dart
- `getNextUndoneIndex(List<DailyThing> items)` [`lib/src/views/widgets/daily_things_helpers.dart:10`](lib/src/views/widgets/daily_things_helpers.dart:10): Finds the index of the next undone item in a list.
- `showThemedSnackBar(...)` [`lib/src/views/widgets/daily_things_helpers.dart:36`](lib/src/views/widgets/daily_things_helpers.dart:36): Shows a themed snackbar.
- `confirmDeleteDialog(BuildContext context, String name)` [`lib/src/views/widgets/daily_things_helpers.dart:52`](lib/src/views/widgets/daily_things_helpers.dart:52): Shows a confirmation dialog before deleting an item.
- `saveJsonToFile(...)` [`lib/src/views/widgets/daily_things_helpers.dart:83`](lib/src/views/widgets/daily_things_helpers.dart:83): Saves a JSON file to disk. Now includes platform-specific file picker handling for Linux and improved success messaging.

## lib/src/views/widgets/graph_style_helpers.dart
- `GraphStyle` class [`lib/src/views/widgets/graph_style_helpers.dart:6`](lib/src/views/widgets/graph_style_helpers.dart:6): Provides styling constants for graphs.
- `GraphStyleHelpers` class [`lib/src/views/widgets/graph_style_helpers.dart:24`](lib/src/views/widgets/graph_style_helpers.dart:24): Provides helper functions for graph styling.

## lib/src/views/widgets/interval_selection_widget.dart
- `IntervalSelectionWidget` class [`lib/src/views/widgets/interval_selection_widget.dart:4`](lib/src/views/widgets/interval_selection_widget.dart:4): A unified widget for selecting intervals (by days or weekdays).
- `_IntervalSelectionWidgetState` class [`lib/src/views/widgets/interval_selection_widget.dart:19`](lib/src/views/widgets/interval_selection_widget.dart:19): Manages the state for the interval selection widget.

## lib/src/views/widgets/pulse.dart
- `Pulse` class [`lib/src/views/widgets/pulse.dart:4`](lib/src/views/widgets/pulse.dart:4): A widget that creates a pulsing effect around its child.

## lib/src/views/widgets/reorder_helpers.dart
- `reorderDailyThings(...)` [`lib/src/views/widgets/reorder_helpers.dart:16`](lib/src/views/widgets/reorder_helpers.dart:16): Reorders the list of daily things.

## lib/src/views/widgets/add_history_entry_dialog.dart
- `AddHistoryEntryDialog` class [`lib/src/views/widgets/add_history_entry_dialog.dart:7`](lib/src/views/widgets/add_history_entry_dialog.dart:7): A dialog to add a new history entry (currently unused).

## lib/src/views/widgets/next_task_arrow.dart
- `NextTaskArrow` class [`lib/src/views/widgets/next_task_arrow.dart:6`](lib/src/views/widgets/next_task_arrow.dart:6): A pulsing arrow button that appears when a timer completes.
  - `build(BuildContext context)` method [`lib/src/views/widgets/next_task_arrow.dart:45`](lib/src/views/widgets/next_task_arrow.dart:45): Renders a pulsing arrow icon positioned in the bottom right of the screen.

## lib/src/views/widgets/visibility_and_expand_helpers.dart
- `toggleExpansionForVisibleItems(...)` [`lib/src/views/widgets/visibility_and_expand_helpers.dart:3`](lib/src/views/widgets/visibility_and_expand_helpers.dart:3): Toggles the expansion state of visible items.

## lib/src/views/widgets/filtering_helpers.dart
- `filterDisplayedItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:4`](lib/src/views/widgets/filtering_helpers.dart:4): Filters the list of daily things to be displayed based on showItemsDueToday and hideWhenDone rules.
- `calculateDueItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:48`](lib/src/views/widgets/filtering_helpers.dart:48): Calculates the list of items that are due today for completion status calculation.

## lib/src/views/widgets/mini_graph_widget.dart
- `MiniGraphWidget` class [`lib/src/views/widgets/mini_graph_widget.dart:8`](lib/src/views/widgets/mini_graph_widget.dart:8): A simplified graph widget showing the last 14 days of data for a daily item directly in the expanded view.
  - `build(BuildContext context)` method [`lib/src/views/widgets/mini_graph_widget.dart:72`](lib/src/views/widgets/mini_graph_widget.dart:72): Renders a minimal FlChart-based graph with no labels, tooltips, or borders.
  - `_buildSpots()` method [`lib/src/views/widgets/mini_graph_widget.dart:14`](lib/src/views/widgets/mini_graph_widget.dart:14): Extracts the last 14 days of history data for all item types.
  - `_calculateMaxY(List<FlSpot> spots)` method [`lib/src/views/widgets/mini_graph_widget.dart:63`](lib/src/views/widgets/mini_graph_widget.dart:63): Calculates the Y-axis range for the graph based on data values.