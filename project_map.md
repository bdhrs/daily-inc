# Project Map

This document provides a map of the project, listing the location of all functions, classes, and important variables. Each entry also includes a simple one-line description in plain English.

## lib/main.dart
- `main()` [`lib/main.dart:10`](lib/main.dart:10): Starts the app, sets up logging, loads saved data, and launches the UI.
- `MyApp` class [`lib/main.dart:48`](lib/main.dart:48): The root app widget managing global focus and theming.
  - `build(BuildContext context)` method [`lib/main.dart:65`](lib/main.dart:65): Builds the MaterialApp with themes and the home screen.
  - Keyboard shortcut Ctrl/Cmd+Q: quits the app on desktop or pops on mobile [`lib/main.dart:69`](lib/main.dart:69): Handy quick-exit key handler.

## lib/src/core/increment_calculator.dart
- `IncrementCalculator` class [`lib/src/core/increment_calculator.dart:9`](lib/src/core/increment_calculator.dart:9): Calculates targets, display values, and status for daily items.
  - Static variable `_gracePeriodDays` [`lib/src/core/increment_calculator.dart:10`](lib/src/core/increment_calculator.dart:10): Stores the configurable grace period.
  - `setGracePeriod(int days)` [`lib/src/core/increment_calculator.dart:13`](lib/src/core/increment_calculator.dart:13): Sets the grace period.
  - `getGracePeriod()` [`lib/src/core/increment_calculator.dart:18`](lib/src/core/increment_calculator.dart:18): Gets the current grace period.
  - `calculateIncrement(DailyThing item)` [`lib/src/core/increment_calculator.dart:22`](lib/src/core/increment_calculator.dart:22): Finds the per-day change from start to end over the duration.
  - `getLastCompletedDate(List<HistoryEntry> history)` [`lib/src/core/increment_calculator.dart:28`](lib/src/core/increment_calculator.dart:28): Gets the most recent day you marked the task as done.
  - `getLastEntryDate(List<HistoryEntry> history)` [`lib/src/core/increment_calculator.dart:41`](lib/src/core/increment_calculator.dart:41): Finds the date of the latest history record.
  - `calculateDaysMissed(DateTime lastEntryDate, DateTime todayDate)` [`lib/src/core/increment_calculator.dart:50`](lib/src/core/increment_calculator.dart:50): Counts how many days were skipped since the last entry.
  - `calculateTodayValue(DailyThing item)` [`lib/src/core/increment_calculator.dart:98`](lib/src/core/increment_calculator.dart:98): Computes today’s target based on progress rules and gaps.
  - `calculateDisplayValue(DailyThing item)` [`lib/src/core/increment_calculator.dart:188`](lib/src/core/increment_calculator.dart:188): Chooses what number to show today (target or actual) depending on type.
  - `isDone(DailyThing item, double currentValue)` [`lib/src/core/increment_calculator.dart:250`](lib/src/core/increment_calculator.dart:250): Tells if today’s goal is met for the item.
  - `determineStatus(DailyThing item, double currentValue)` [`lib/src/core/increment_calculator.dart:271`](lib/src/core/increment_calculator.dart:271): Returns green or red status based on today’s target.

- `Status` enum [`lib/src/core/increment_calculator.dart:244`](lib/src/core/increment_calculator.dart:244): Simple green or red state for display.

## lib/src/data/data_manager.dart
- `DataManager` class [`lib/src/data/data_manager.dart:10`](lib/src/data/data_manager.dart:10): Loads, saves, and manages items and metadata on disk.
  - `loadFromFile()` [`lib/src/data/data_manager.dart:14`](lib/src/data/data_manager.dart:14): Lets you pick a JSON file and imports items, fixing missing fields if needed.
  - `_getFilePath()` [`lib/src/data/data_manager.dart:82`](lib/src/data/data_manager.dart:82): Finds the app’s data file location.
  - `_readRawStore()` [`lib/src/data/data_manager.dart:87`](lib/src/data/data_manager.dart:87): Reads raw JSON data from storage.
  - `_writeRawStore(Map<String, dynamic> data)` [`lib/src/data/data_manager.dart:109`](lib/src/data/data_manager.dart:109): Writes raw JSON data to storage.
  - `loadData()` [`lib/src/data/data_manager.dart:119`](lib/src/data/data_manager.dart:119): Loads the list of items from the app’s data file.
  - `saveData(List<DailyThing> items)` [`lib/src/data/data_manager.dart:135`](lib/src/data/data_manager.dart:135): Saves all items back to the data file.
  - `addDailyThing(DailyThing newItem)` [`lib/src/data/data_manager.dart:148`](lib/src/data/data_manager.dart:148): Adds a new item and saves.
  - `deleteDailyThing(DailyThing itemToDelete)` [`lib/src/data/data_manager.dart:156`](lib/src/data/data_manager.dart:156): Removes an item and saves.
  - `updateDailyThing(DailyThing updatedItem)` [`lib/src/data/data_manager.dart:164`](lib/src/data/data_manager.dart:164): Updates an existing item and saves.
  - `resetAllData()` [`lib/src/data/data_manager.dart:178`](lib/src/data/data_manager.dart:178): Deletes the stored data file to start fresh.
  - `saveHistoryToFile()` [`lib/src/data/data_manager.dart:194`](lib/src/data/data_manager.dart:194): Exports all current data to a JSON file via a save dialog.
  - `getUniqueCategories()` [`lib/src/data/data_manager.dart:227`](lib/src/data/data_manager.dart:227): Lists all unique categories (except “None”).
  - `getUniqueCategoriesForType(ItemType type)` [`lib/src/data/data_manager.dart:244`](lib/src/data/data_manager.dart:244): Lists unique categories only for the given type.
  - `getLastMotivationShownDate()` [`lib/src/data/data_manager.dart:262`](lib/src/data/data_manager.dart:262): Reads the date when the motivation dialog was last shown.
  - `setLastMotivationShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:272`](lib/src/data/data_manager.dart:272): Stores today's date as the last shown motivation.
  - `getLastCompletionShownDate()` [`lib/src/data/data_manager.dart:287`](lib/src/data/data_manager.dart:287): Reads the date when the completion dialog was last shown.
  - `setLastCompletionShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:297`](lib/src/data/data_manager.dart:297): Stores today's date as the last shown completion message.

## lib/src/data/history_manager.dart
- `HistoryManager` class [`lib/src/data/history_manager.dart:6`](lib/src/data/history_manager.dart:6): Safely updates future targets when plan settings change without altering past records.
  - `updateHistoryEntriesWithNewParameters({...})` [`lib/src/data/history_manager.dart:13`](lib/src/data/history_manager.dart:13): Recomputes targets for today and future based on new plan while keeping history intact.

## lib/src/models/daily_thing.dart
- `_logger` variable [`lib/src/models/daily_thing.dart:7`](lib/src/models/daily_thing.dart:7): Logs messages for this model.
- `DailyThing` class [`lib/src/models/daily_thing.dart:9`](lib/src/models/daily_thing.dart:9): Represents a daily task with rules, history, and settings.
  - Fields like `id`, `icon`, `name`, `itemType`, `startDate`, `startValue`, `duration`, `endValue`, `history`, `nagTime`, `nagMessage`, `frequencyInDays`, `category`, `isPaused` [`lib/src/models/daily_thing.dart:10`](lib/src/models/daily_thing.dart:10): Store the task’s basic info and behavior.
  - `increment` getter [`lib/src/models/daily_thing.dart:43`](lib/src/models/daily_thing.dart:43): Gives the per-day change for this task.
  - `todayValue` getter [`lib/src/models/daily_thing.dart:47`](lib/src/models/daily_thing.dart:47): Gives today’s target for this task.
  - `displayValue` getter [`lib/src/models/daily_thing.dart:51`](lib/src/models/daily_thing.dart:51): Gives what to show in the UI today.
  - `determineStatus(double currentValue)` [`lib/src/models/daily_thing.dart:55`](lib/src/models/daily_thing.dart:55): Returns green/red status for the current value.
  - `isDone(double currentValue)` [`lib/src/models/daily_thing.dart:59`](lib/src/models/daily_thing.dart:59): Tells if today is completed for this task.
  - `lastCompletedDate` getter [`lib/src/models/daily_thing.dart:63`](lib/src/models/daily_thing.dart:63): Finds when you last finished this task.
  - `isDueToday` getter [`lib/src/models/daily_thing.dart:67`](lib/src/models/daily_thing.dart:67): Says if the task needs doing today based on its frequency.
  - `completedForToday` getter [`lib/src/models/daily_thing.dart:81`](lib/src/models/daily_thing.dart:81): Says if today counts as done for this task.
  - `hasBeenDoneLiterallyToday` getter [`lib/src/models/daily_thing.dart:88`](lib/src/models/daily_thing.dart:88): Checks if today’s history entry is marked as done.
  - `shouldShowInList` getter [`lib/src/models/daily_thing.dart:154`](lib/src/models/daily_thing.dart:154): Determines if this item should be shown in the list based on due status and completion.
  - `toJson()` [`lib/src/models/daily_thing.dart:112`](lib/src/models/daily_thing.dart:112): Converts this item to a JSON map.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/daily_thing.dart:131`](lib/src/models/daily_thing.dart:131): Builds the item from a JSON map.

## lib/src/models/history_entry.dart
- `_logger` variable [`lib/src/models/history_entry.dart:3`](lib/src/models/history_entry.dart:3): Logs parsing warnings for history.
- `HistoryEntry` class [`lib/src/models/history_entry.dart:5`](lib/src/models/history_entry.dart:5): A single day’s record of target and actual progress.
  - `toJson()` [`lib/src/models/history_entry.dart:18`](lib/src/models/history_entry.dart:18): Converts the entry to a JSON map.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/history_entry.dart:27`](lib/src/models/history_entry.dart:27): Parses a JSON map into an entry with safe fallbacks.

## lib/src/models/interval_type.dart
- `IntervalType` enum [`lib/src/models/interval_type.dart:1`](lib/src/models/interval_type.dart:1): Defines whether an item repeats by a number of days or on specific weekdays.

## lib/src/models/item_type.dart
- `ItemType` enum [`lib/src/models/item_type.dart:1`](lib/src/models/item_type.dart:1): The type of task: minutes, reps, or check.

## lib/src/services/update_service.dart
- `UpdateService` class [`lib/src/services/update_service.dart:14`](lib/src/services/update_service.dart:14): Handles app update checks, downloads, and installation.
  - `getLatestRelease()` [`lib/src/services/update_service.dart:11`](lib/src/services/update_service.dart:11): Fetches release details from the GitHub API.
  - `getCurrentAppVersion()` [`lib/src/services/update_service.dart:28`](lib/src/services/update_service.dart:28): Retrieves the current installed app version.
  - `isUpdateAvailable()` [`lib/src/services/update_service.dart:33`](lib/src/services/update_service.dart:33): Checks if a newer version is available on GitHub.
  - `getDownloadUrl()` [`lib/src/services/update_service.dart:61`](lib/src/services/update_service.dart:61): Figures out the correct asset download URL for the platform.
  - `downloadUpdate()` [`lib/src/services/update_service.dart:78`](lib/src/services/update_service.dart:78): Returns release URL but does not actually download the update (not implemented).
  - `installUpdate()` [`lib/src/services/update_service.dart:93`](lib/src/services/update_service.dart:93): Stub method that does not actually install updates (not implemented).

## lib/src/theme/app_theme.dart
- `AppTheme` class [`lib/src/theme/app_theme.dart:5`](lib/src/theme/app_theme.dart:5): Central place for the app’s dark theme look and feel.
  - `darkTheme` getter [`lib/src/theme/app_theme.dart:6`](lib/src/theme/app_theme.dart:6): Provides colors, fonts, and styles for dark mode.
    - Uses `ColorPalette` tokens for consistent colors, customizes AppBar, Cards, Buttons, Inputs, SnackBars, Dialogs, Switches, ExpansionTiles, TimePicker, and Scrollbar.

## lib/src/theme/color_palette.dart
- `ColorPalette` class [`lib/src/theme/color_palette.dart:3`](lib/src/theme/color_palette.dart:3): Defines the app colors used across the UI.
  - Constants like `primaryBlue`, `darkBackground`, `cardBackground`, `inputBackground`, `lightText`, `blackText`, `secondaryText`, `warningOrange`, `partialYellow`, `onPartialYellow`, `scrollbarThumb` [`lib/src/theme/color_palette.dart:4`](lib/src/theme/color_palette.dart:4): Named colors for consistent styling.
  - Notes: `warningOrange` is used for undone/error, `partialYellow` with `onPartialYellow` highlights partial progress.

## lib/src/views/add_edit_daily_item_view.dart
- `AddEditDailyItemView` class [`lib/src/views/add_edit_daily_item_view.dart:10`](lib/src/views/add_edit_daily_item_view.dart:10): Screen to create or edit a daily task.
- `_AddEditDailyItemViewState` class [`lib/src/views/add_edit_daily_item_view.dart:26`](lib/src/views/add_edit_daily_item_view.dart:26): Handles form state and input controllers.
  - Form controller fields: `_iconController`, `_nameController`, `_startDateController`, `_startValueController`, `_durationController`, `_endValueController`, `_frequencyController`, `_nagTimeController`, `_nagMessageController`, `_categoryController`, `_incrementController`, `_bellSoundController`, `_subdivisionsController`, `_subdivisionBellSoundController` [`lib/src/views/add_edit_daily_item_view.dart:27`](lib/src/views/add_edit_daily_item_view.dart:27): Store user inputs.
  - Selections: `_selectedItemType`, `_selectedNagTime`, `_uniqueCategories`, `_selectedBellSoundPath`, `_selectedSubdivisionBellSoundPath` [`lib/src/views/add_edit_daily_item_view.dart:39`](lib/src/views/add_edit_daily_item_view.dart:39): Track current type/time, category options, and bell sounds.
  - Lifecycle `initState()` [`lib/src/views/add_edit_daily_item_view.dart:47`](lib/src/views/add_edit_daily_item_view.dart:47): Initializes controllers and pre-fills values, including automatic bell3 assignment for new items with subdivisions > 1.
  - `didChangeDependencies()` [`lib/src/views/add_edit_daily_item_view.dart:108`](lib/src/views/add_edit_daily_item_view.dart:108): Formats the time field when context is ready.
  - `dispose()` [`lib/src/views/add_edit_daily_item_view.dart:120`](lib/src/views/add_edit_daily_item_view.dart:120): Disposes controllers to avoid leaks.
  - `_calculateIncrement()` [`lib/src/views/add_edit_daily_item_view.dart:139`](lib/src/views/add_edit_daily_item_view.dart:139): Computes daily increment from inputs.
  - `_updateIncrementField()` [`lib/src/views/add_edit_daily_item_view.dart:154`](lib/src/views/add_edit_daily_item_view.dart:154): Updates increment when duration changes.
  - `_updateDurationFromIncrement()` [`lib/src/views/add_edit_daily_item_view.dart:160`](lib/src/views/add_edit_daily_item_view.dart:160): Updates duration when increment changes.
  - `_loadUniqueCategoriesForSelectedType()` [`lib/src/views/add_edit_daily_item_view.dart:164`](lib/src/views/add_edit_daily_item_view.dart:164): Fetches category suggestions for the selected type.
  - `_submitDailyItem()` [`lib/src/views/add_edit_daily_item_view.dart:179`](lib/src/views/add_edit_daily_item_view.dart:179): Validates, updates history for plan changes, and saves.
  - Subdivisions onChanged handler [`lib/src/views/add_edit_daily_item_view.dart:882`](lib/src/views/add_edit_daily_item_view.dart:882): Automatically sets bell3 as default subdivision bell when subdivisions > 1.
  - `build(BuildContext context)` [`lib/src/views/add_edit_daily_item_view.dart:295`](lib/src/views/add_edit_daily_item_view.dart:295): Renders the item form UI.

## lib/src/views/category_graph_view.dart
- `CategoryGraphView` class [`lib/src/views/category_graph_view.dart:10`](lib/src/views/category_graph_view.dart:10): Shows graphs of progress for each category with time range filtering.

## lib/src/views/daily_thing_item.dart
- `DailyThingItem` class [`lib/src/views/daily_thing_item.dart:9`](lib/src/views/daily_thing_item.dart:9): A single task row with controls and quick actions.
  - Props `item`, `dataManager`, `onEdit`, `onDelete`, `onDuplicate`, `showFullscreenTimer`, `showRepsInputDialog`, `checkAndShowCompletionSnackbar`, `isExpanded`, `onExpansionChanged`, `allTasksCompleted`, `onItemChanged` [`lib/src/views/daily_thing_item.dart:10`](lib/src/views/daily_thing_item.dart:10): Inputs and callbacks for the row behavior.
- `_DailyThingItemState` class [`lib/src/views/daily_thing_item.dart:43`](lib/src/views/daily_thing_item.dart:43): Manages expansion and tap actions for the item.
  - `initState()`, `didUpdateWidget(...)` [`lib/src/views/daily_thing_item.dart:47`](lib/src/views/daily_thing_item.dart:47): Syncs expansion state with parent.
  - `_formatValue(double value, ItemType itemType)` [`lib/src/views/daily_thing_item.dart:62`](lib/src/views/daily_thing_item.dart:62): Formats minutes, reps, or check for display.
  - `_hasIncompleteProgress(DailyThing item)` [`lib/src/views/daily_thing_item.dart:78`](lib/src/views/daily_thing_item.dart:78): Detects if a timer was started but not finished today.
  - `build(BuildContext context)` [`lib/src/views/daily_thing_item.dart:101`](lib/src/views/daily_thing_item.dart:101): Draws the row UI and handles tap actions (timer/check/reps).

## lib/src/views/daily_things_view.dart
- `DailyThingsView` class [`lib/src/views/daily_things_view.dart:20`](lib/src/views/daily_things_view.dart:20): The home screen that lists all tasks and actions.
- `_DailyThingsViewState` class [`lib/src/views/daily_things_view.dart:27`](lib/src/views/daily_things_view.dart:27): Loads, filters, reorders, and manages dialogs/snackbars.
  - `_dataManager` [`lib/src/views/daily_things_view.dart:29`](lib/src/views/daily_things_view.dart:29): Handles loading and saving items.
  - `_dailyThings` [`lib/src/views/daily_things_view.dart:30`](lib/src/views/daily_things_view.dart:30): In-memory list of tasks.
  - `_isExpanded` / `_expansionTileKeys` [`lib/src/views/daily_things_view.dart:31`](lib/src/views/daily_things_view.dart:31): Tracks which rows are expanded.
  - `_hasShownCompletionSnackbar`, `_allTasksCompleted` [`lib/src/views/daily_things_view.dart:38`](lib/src/views/daily_things_view.dart:38): Status for daily completion celebration.
  - `_showOnlyDueItems`, `_hideWhenDone` [`lib/src/views/daily_things_view.dart:39`](lib/src/views/daily_things_view.dart:39): Controls filtering and hiding.
  - `_motivationCheckedThisBuild` [`lib/src/views/daily_things_view.dart:41`](lib/src/views/daily_things_view.dart:41): Ensures motivation dialog is shown once per day.
  - `_allExpanded` [`lib/src/views/daily_things_view.dart:42`](lib/src/views/daily_things_view.dart:42): Tracks expand/collapse all state.
  - `_updateAvailable` [`lib/src/views/daily_things_view.dart:43`](lib/src/views/daily_things_view.dart:43): Tracks if a new update is available.
  - State variables for motivational messages: `_showStartOfDayMessage`, `_startOfDayMessageText`, `_showCompletionMessage`, `_completionMessageText` [`lib/src/views/daily_things_view.dart:45`](lib/src/views/daily_things_view.dart:45): Controls for customizable motivational messages.
  - `initState()` / `dispose()` [`lib/src/views/daily_things_view.dart:52`](lib/src/views/daily_things_view.dart:52): Lifecycle to subscribe/unsubscribe, kick off loading, and check for updates.
  - `_loadHideWhenDoneSetting()` / `_refreshHideWhenDoneSetting()` [`lib/src/views/daily_things_view.dart:75`](lib/src/views/daily_things_view.dart:75): Reads and updates the "hide done" preference.
  - `_loadMotivationalMessageSettings()` [`lib/src/views/daily_things_view.dart:85`](lib/src/views/daily_things_view.dart:85): Loads motivational message settings from SharedPreferences.
  - `_loadData()` [`lib/src/views/daily_things_view.dart:113`](lib/src/views/daily_things_view.dart:113): Loads items and checks if everything is done.
  - `_refreshDisplay()` [`lib/src/views/daily_things_view.dart:131`](lib/src/views/daily_things_view.dart:131): Forces a rebuild and reloads items.
  - `_openAddDailyItemPopup()` [`lib/src/views/daily_things_view.dart:144`](lib/src/views/daily_things_view.dart:144): Opens the screen to add a new task.
  - `_editDailyThing(DailyThing item)` [`lib/src/views/daily_things_view.dart:160`](lib/src/views/daily_things_view.dart:160): Opens the edit screen and updates the list on return.
  - `_deleteDailyThing(DailyThing item)` [`lib/src/views/daily_things_view.dart:193`](lib/src/views/daily_things_view.dart:193): Confirms and deletes a task, then refreshes.
  - `_duplicateItem(DailyThing item)` [`lib/src/views/daily_things_view.dart:225`](lib/src/views/daily_things_view.dart:225): Creates a copy of a task and saves it.
  - `_showFullscreenTimer(DailyThing item)` [`lib/src/views/daily_things_view.dart:265`](lib/src/views/daily_things_view.dart:265): Opens the minutes timer in full screen.
  - `_showRepsInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:427`](lib/src/views/daily_things_view.dart:427): Prompts to enter reps and saves them.
  - `_saveHistoryToFile()` [`lib/src/views/daily_things_view.dart:439`](lib/src/views/daily_things_view.dart:439): Exports all items/history to JSON.
  - `_checkForUpdate()` [`lib/src/views/daily_things_view.dart:522`](lib/src/views/daily_things_view.dart:522): Checks for updates and shows a pulsing icon.
  - `_handleUpdate()` [`lib/src/views/daily_things_view.dart:538`](lib/src/views/daily_things_view.dart:538): Manages the multi-step update process with user feedback.
  - `_getNextUndoneIndex(List<DailyThing> items)` [`lib/src/views/daily_things_view.dart:463`](lib/src/views/daily_things_view.dart:463): Finds the next not-done item's index.
  - `_expandAllVisibleItems()` [`lib/src/views/daily_things_view.dart:467`](lib/src/views/daily_things_view.dart:467): Toggles expansion for filtered items.
  - `_checkAndShowCompletionSnackbar()` [`lib/src/views/daily_things_view.dart:486`](lib/src/views/daily_things_view.dart:486): Shows a message when all tasks are done.
  - `_maybeShowCompletionDialog()` [`lib/src/views/daily_things_view.dart:517`](lib/src/views/daily_things_view.dart:517): Shows customizable completion dialog once per day.
  - `_loadHistoryFromFile()` [`lib/src/views/daily_things_view.dart:550`](lib/src/views/daily_things_view.dart:550): Imports tasks from a JSON file and saves them.
  - `didChangeAppLifecycleState(...)` [`lib/src/views/daily_things_view.dart:592`](lib/src/views/daily_things_view.dart:592): Re-triggers motivation when app resumes.
  - `build(BuildContext context)` [`lib/src/views/daily_things_view.dart:599`](lib/src/views/daily_things_view.dart:599): Builds filters, menus, the reorderable task list, and uses the DailyThingsAppBar widget.

## lib/src/views/graph_view.dart
- `GraphView` class [`lib/src/views/graph_view.dart:10`](lib/src/views/graph_view.dart:10): Shows a step line chart for one task’s daily progress with time range filtering.
  - `dailyThing` property [`lib/src/views/graph_view.dart:11`](lib/src/views/graph_view.dart:11): The item whose history is graphed.
- `_GraphViewState` class [`lib/src/views/graph_view.dart:18`](lib/src/views/graph_view.dart:18): Calculates ranges and builds data points.
  - `_minY` / `_maxY` [`lib/src/views/graph_view.dart:19`](lib/src/views/graph_view.dart:19): Y-axis bounds for the chart.
  - `initState()` [`lib/src/views/graph_view.dart:24`](lib/src/views/graph_view.dart:24): Initializes and computes ranges.
  - `_calculateRanges()` [`lib/src/views/graph_view.dart:30`](lib/src/views/graph_view.dart:30): Sets up chart limits depending on type and data.
  - `build(BuildContext context)` [`lib/src/views/graph_view.dart:45`](lib/src/views/graph_view.dart:45): Renders the line chart with axes, grid, and tooltips.
  - `_buildSpots()` [`lib/src/views/graph_view.dart:191`](lib/src/views/graph_view.dart:191): Produces a point per day from history for plotting.
  - `_getAllDatesFromStartToToday()` [`lib/src/views/graph_view.dart:227`](lib/src/views/graph_view.dart:227): Builds the full date range shown.
  - `_generateDateRange(DateTime start, DateTime end)` [`lib/src/views/graph_view.dart:250`](lib/src/views/graph_view.dart:250): Helper to create consecutive dates for the chart.

## lib/src/views/app_bar.dart
- `DailyThingsAppBar` class [`lib/src/views/app_bar.dart:12`](lib/src/views/app_bar.dart:12): A custom AppBar widget that manages the app's main actions and overflow menu.
  - Props `updateAvailable`, `onOpenAddDailyItemPopup`, `onRefreshHideWhenDoneSetting`, `onRefreshDisplay`, `onExpandAllVisibleItems`, `onLoadHistoryFromFile`, `onSaveHistoryToFile`, `dailyThings`, `hideWhenDone`, `allExpanded`, `showOnlyDueItems`, `onShowAboutDialog`, `onToggleShowOnlyDueItems`, `log` [`lib/src/views/app_bar.dart:13`](lib/src/views/app_bar.dart:13): Inputs and callbacks for the AppBar behavior.
- `_DailyThingsAppBarState` class [`lib/src/views/app_bar.dart:53`](lib/src/views/app_bar.dart:53): Manages the state and rendering of the AppBar.
  - `build(BuildContext context)` [`lib/src/views/app_bar.dart:55`](lib/src/views/app_bar.dart:55): Renders the AppBar with actions and overflow menu.

## lib/src/views/help_view.dart
- `HelpView` class [`lib/src/views/help_view.dart:8`](lib/src/views/help_view.dart:8): A screen that explains how to use the app.

## lib/src/views/reps_input_dialog.dart
- `RepsInputDialog` class [`lib/src/views/reps_input_dialog.dart:7`](lib/src/views/reps_input_dialog.dart:7): Dialog to enter how many reps you did today.
  - `item`/`dataManager`/`onSuccess` [`lib/src/views/reps_input_dialog.dart:8`](lib/src/views/reps_input_dialog.dart:8): Inputs for saving today’s reps and updating UI.
  - `build(BuildContext context)` [`lib/src/views/reps_input_dialog.dart:21`](lib/src/views/reps_input_dialog.dart:21): Renders the input field and buttons.
  - `_handleSubmit(BuildContext, String, VoidCallback)` [`lib/src/views/reps_input_dialog.dart:61`](lib/src/views/reps_input_dialog.dart:61): Validates and saves reps for today, then calls success.

## lib/src/views/settings_view.dart
- `SettingsView` class [`lib/src/views/settings_view.dart:8`](lib/src/views/settings_view.dart:8): Settings screen for filters and data actions.
- `_SettingsViewState` class [`lib/src/views/settings_view.dart:14`](lib/src/views/settings_view.dart:14): Loads preferences and handles save/reset.
  - State variables for motivational messages: `_showStartOfDayMessage`, `_startOfDayMessageText`, `_showCompletionMessage`, `_completionMessageText` [`lib/src/views/settings_view.dart:19`](lib/src/views/settings_view.dart:19): Controls for customizable motivational messages.
  - State variable for grace period: `_gracePeriodDays` [`lib/src/views/settings_view.dart:26`](lib/src/views/settings_view.dart:26): Controls the number of days before penalties are applied.
  - `initState()` / `_loadSettings()` [`lib/src/views/settings_view.dart:31`](lib/src/views/settings_view.dart:31): Initializes and fetches stored values.
  - `_saveSettings()` [`lib/src/views/settings_view.dart:49`](lib/src/views/settings_view.dart:49): Persists motivational message settings and grace period.
  - `_resetAllData()` [`lib/src/views/settings_view.dart:63`](lib/src/views/settings_view.dart:63): Clears stored data and confirms.
- `build(BuildContext context)` [`lib/src/views/settings_view.dart:123`](lib/src/views/settings_view.dart:123): Renders the settings UI with motivational message controls, grace period slider, and warning icon on reset button.

## lib/src/views/history_view.dart
- `HistoryView` class [`lib/src/views/history_view.dart:8`](lib/src/views/history_view.dart:8): A screen to view and edit the history of a daily item.
- `_HistoryViewState` class [`lib/src/views/history_view.dart:15`](lib/src/views/history_view.dart:15): Manages the state for the history view.
  - `_history` [`lib/src/views/history_view.dart:16`](lib/src/views/history_view.dart:16): Local copy of the history entries.
  - `_dataManager` [`lib/src/views/history_view.dart:17`](lib/src/views/history_view.dart:17): Handles data saving.
  - `initState()` [`lib/src/views/history_view.dart:20`](lib/src/views/history_view.dart:20): Initializes the local history list.
  - `_saveChanges()` [`lib/src/views/history_view.dart:26`](lib/src/views/history_view.dart:26): Shows a confirmation dialog and saves changes.
  - `_startAddingEntry()` [`lib/src/views/history_view.dart:90`](lib/src/views/history_view.dart:90): Starts the process of adding a new entry.
  - `_saveNewEntry()` [`lib/src/views/history_view.dart:103`](lib/src/views/history_view.dart:103): Validates and saves a new entry.
  - `_cancelAddingEntry()` [`lib/src/views/history_view.dart:133`](lib/src/views/history_view.dart:133): Cancels the process of adding a new entry.
  - `build(BuildContext context)` [`lib/src/views/history_view.dart:55`](lib/src/views/history_view.dart:55): Renders the history list with editable fields.


## lib/src/views/timer_view.dart
- `TimerView` class [`lib/src/views/timer_view.dart:11`](lib/src/views/timer_view.dart:11): A full-screen, minimalist timer for 'Minutes' tasks.
  - `item`/`dataManager`/`onExitCallback` [`lib/src/views/timer_view.dart:12`](lib/src/views/timer_view.dart:12): Inputs for running and saving timer progress.
- `_TimerViewState` class [`lib/src/views/timer_view.dart:27`](lib/src/views/timer_view.dart:27): Manages all timer states: countdown, paused, finished, and overtime.
  - `_currentElapsedTimeInMinutes` getter [`lib/src/views/timer_view.dart:43`](lib/src/views/timer_view.dart:43): Calculates the total time elapsed, including persisted history and the current session.
  - `_toggleTimer()` [`lib/src/views/timer_view.dart:150`](lib/src/views/timer_view.dart:150): Starts, pauses, or continues the timer. Starts overtime mode when 'Continue' is pressed after timer finishes.
  - `_runCountdown()` / `_runOvertime()` [`lib/src/views/timer_view.dart:189`](lib/src/views/timer_view.dart:189): Main timer loops for countdown and overtime, run by `_toggleTimer`.
  - `_onTimerComplete()` [`lib/src/views/timer_view.dart:206`](lib/src/views/timer_view.dart:206): Plays a sound, pauses the timer, and automatically saves the completed progress.
  - `_exitTimerDisplay()` [`lib/src/views/timer_view.dart:218`](lib/src/views/timer_view.dart:218): Handles exiting the screen, showing a dialog for partial progress or updating the final overtime value.
  - `_saveProgress()` [`lib/src/views/timer_view.dart:281`](lib/src/views/timer_view.dart:281): A unified method to save or update today's history entry, preventing duplicates.
  - `initState()` [`lib/src/views/timer_view.dart:83`](lib/src/views/timer_view.dart:83): Initializes the timer state and enables fullscreen mode.
  - `dispose()` [`lib/src/views/timer_view.dart:146`](lib/src/views/timer_view.dart:146): Cleans up resources and disables fullscreen mode.
  - `build(BuildContext context)` [`lib/src/views/timer_view.dart:368`](lib/src/views/timer_view.dart:368): Renders the main UI with a responsive timer, info text, comment field, and controls.
  - `_buildCountdownView()` / `_buildOvertimeView()` [`lib/src/views/timer_view.dart:444`](lib/src/views/timer_view.dart:444): Builds the main timer display using Roboto Mono monospace font, LayoutBuilder and FittedBox to maximize its size.
  - `_buildCommentField()` [`lib/src/views/timer_view.dart:490`](lib/src/views/timer_view.dart:490): Displays a clickable 'add a comment' text that transforms into a `TextField` on focus.
  - `_getButtonText()` [`lib/src/views/timer_view.dart:434`](lib/src/views/timer_view.dart:434): Determines the label for the main action button ('Start', 'Pause', or 'Continue').

## lib/src/views/widgets/daily_things_helpers.dart
- `getNextUndoneIndex(List<DailyThing> items)` [`lib/src/views/widgets/daily_things_helpers.dart:10`](lib/src/views/widgets/daily_things_helpers.dart:10): Finds the index of the next undone item in a list.
- `showThemedSnackBar(...)` [`lib/src/views/widgets/daily_things_helpers.dart:36`](lib/src/views/widgets/daily_things_helpers.dart:36): Shows a themed snackbar.
- `confirmDeleteDialog(BuildContext context, String name)` [`lib/src/views/widgets/daily_things_helpers.dart:52`](lib/src/views/widgets/daily_things_helpers.dart:52): Shows a confirmation dialog before deleting an item.
- `saveJsonToFile(...)` [`lib/src/views/widgets/daily_things_helpers.dart:83`](lib/src/views/widgets/daily_things_helpers.dart:83): Saves a JSON file to disk.

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

## lib/src/views/widgets/visibility_and_expand_helpers.dart
- `toggleExpansionForVisibleItems(...)` [`lib/src/views/widgets/visibility_and_expand_helpers.dart:3`](lib/src/views/widgets/visibility_and_expand_helpers.dart:3): Toggles the expansion state of visible items.

## lib/src/views/widgets/filtering_helpers.dart
- `filterDisplayedItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:4`](lib/src/views/widgets/filtering_helpers.dart:4): Filters the list of daily things to be displayed based on showItemsDueToday and hideWhenDone rules.
- `calculateDueItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:48`](lib/src/views/widgets/filtering_helpers.dart:48): Calculates the list of items that are due today for completion status calculation.

## .github/workflows/release.yml
- Release workflow [`/.github/workflows/release.yml`](/.github/workflows/release.yml): GitHub Actions workflow for building and releasing the application with different versioning options.
  - "minor-from-main" option: Increments the MINOR version number for releases from the main branch (fixed to properly increment minor instead of patch)
  - "patch-from-main" option: Increments the PATCH version number for releases from the main branch
  - "major-from-dev" option: Increments the MAJOR version number for releases from the dev branch
  - "minor-from-dev" option: Increments the MINOR version number for releases from the dev branch