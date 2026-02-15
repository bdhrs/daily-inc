# Overview of Daily Inc App

This document provides essential context for any AI Coding Agent to understand the **Daily Inc Timer** Flutter project, enabling effective assistance with development tasks.

**Daily Inc** is a Flutter application designed to help users build and maintain daily habits through incremental progress. It allows users to track four types of activities:
- **MINUTES**: Activities tracked with a countdown timer (e.g., meditation for 10 minutes).
- **REPS**: Activities tracked by repetitions, with a target that increases over time (e.g., push-ups, starting at 5 reps).
- **CHECK**: Simple daily tasks that are either completed or not (e.g., drink water).
- **PERCENTAGE**: Activities tracked by percentage completion (0-100%), with no start/end values or duration (e.g., project progress).

The core concept is that targets for REPS and MINUTES tasks adjust automatically based on rules defined when the task is created (start value, end value, duration in days) and the user's history (whether they completed the task on previous days). Missing days might pause progress or apply a penalty, while consistent completion leads to increments.

The application features:
- A main list view of daily tasks.
- Full-screen timer for MINUTES tasks.
- Input dialogs for REPS tasks.
- Toggle for CHECK tasks.
- Graphs to visualize progress over time.
- Import/export of data to/from JSON.
- Cross-platform support (Linux, Android, iOS, macOS, Web, Windows).

# Technology Stack

- **Language:** Dart
- **Framework:** Flutter
- **State Management:** The project appears to use a combination of `setState` and potentially the `Get` package (indicated in `pubspec.yaml`), though much of the state management seems custom or widget-based.
- **Local Data Storage:** Custom logic using `shared_preferences` for settings and simple data, and likely file I/O (`path_provider`) for the main JSON data file.
- **UI:** Flutter's Material Design widgets.
- **Architecture:** A structured MVC-like approach with `lib/src` containing `core`, `data`, `models`, `services`, `theme`, `views`, and `widgets` subdirectories.

# Project Map

Always read docs/AGENTS.md and docs/project_map.md to understand the context of the project.

This document provides a map of the project, listing the location of all functions, classes, and important variables. Each entry also includes a simple one-line description in plain English.

## lib/main.dart
- `main()` [`lib/main.dart:11`](lib/main.dart:11): Starts the app, sets up logging, loads saved data, and launches the UI.
- `MyApp` class [`lib/main.dart:53`](lib/main.dart:53): The root app widget managing global focus and theming.
  - `build(BuildContext context)` method [`lib/main.dart:70`](lib/main.dart:70): Builds the MaterialApp with themes and the home screen.
  - Keyboard shortcut Ctrl/Cmd+Q: quits the app on desktop or pops on mobile [`lib/main.dart:75`](lib/main.dart:75): Handy quick-exit key handler.

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
- `DataManager` class [`lib/src/data/data_manager.dart:18`](lib/src/data/data_manager.dart:18): Loads, saves, and manages items and metadata on disk.
  - `loadFromFile()` [`lib/src/data/data_manager.dart:21`](lib/src/data/data_manager.dart:21): Lets you pick a JSON file and imports items, fixing missing fields if needed.
  - `_getFilePath()` [`lib/src/data/data_manager.dart:89`](lib/src/data/data_manager.dart:89): Finds the app's data file location.
  - `_readRawStore()` [`lib/src/data/data_manager.dart:94`](lib/src/data/data_manager.dart:94): Reads raw JSON data from storage.
  - `_writeRawStore(Map<String, dynamic> data)` [`lib/src/data/data_manager.dart:116`](lib/src/data/data_manager.dart:116): Writes raw JSON data to storage.
  - `loadData()` [`lib/src/data/data_manager.dart:126`](lib/src/data/data_manager.dart:126): Loads the list of items from the app's data file.
  - `saveData(List<DailyThing> items)` [`lib/src/data/data_manager.dart:142`](lib/src/data/data_manager.dart:142): Saves all items back to the data file.
  - `addDailyThing(DailyThing newItem)` [`lib/src/data/data_manager.dart:167`](lib/src/data/data_manager.dart:167): Adds a new item and saves.
  - `deleteDailyThing(DailyThing itemToDelete)` [`lib/src/data/data_manager.dart:175`](lib/src/data/data_manager.dart:175): Removes an item and saves.
  - `updateDailyThing(DailyThing updatedItem)` [`lib/src/data/data_manager.dart:183`](lib/src/data/data_manager.dart:183): Updates an existing item and saves.
  - `resetAllData()` [`lib/src/data/data_manager.dart:197`](lib/src/data/data_manager.dart:197): Deletes the stored data file to start fresh.
  - `archiveDailyThing(DailyThing item)` [`lib/src/data/data_manager.dart:221`](lib/src/data/data_manager.dart:221): Archives a daily thing item.
  - `unarchiveDailyThing(DailyThing item)` [`lib/src/data/data_manager.dart:228`](lib/src/data/data_manager.dart:228): Unarchives a daily thing item.
  - `saveTemplateToFile()` [`lib/src/data/data_manager.dart:235`](lib/src/data/data_manager.dart:235): Exports all current data without history to a JSON template file via a save dialog.
  - `saveTemplateToBackupLocation()` [`lib/src/data/data_manager.dart:251`](lib/src/data/data_manager.dart:251): Automatically saves all items as a template to the backup location.
  - `getUniqueCategories()` [`lib/src/data/data_manager.dart:268`](lib/src/data/data_manager.dart:268): Lists all unique categories (except "None").
  - `getUniqueCategoriesForType(ItemType type)` [`lib/src/data/data_manager.dart:285`](lib/src/data/data_manager.dart:285): Lists unique categories only for the given type.
  - `getLastMotivationShownDate()` [`lib/src/data/data_manager.dart:303`](lib/src/data/data_manager.dart:303): Reads the date when the motivation dialog was last shown.
  - `setLastMotivationShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:313`](lib/src/data/data_manager.dart:313): Stores today's date as the last shown motivation.
  - `getLastCompletionShownDate()` [`lib/src/data/data_manager.dart:328`](lib/src/data/data_manager.dart:328): Reads the date when the completion dialog was last shown.
  - `setLastCompletionShownDate(String yyyymmdd)` [`lib/src/data/data_manager.dart:338`](lib/src/data/data_manager.dart:338): Stores today's date as the last shown completion message.

## lib/src/data/history_manager.dart
- `HistoryManager` class [`lib/src/data/history_manager.dart:6`](lib/src/data/history_manager.dart:6): Safely updates future targets when plan settings change without altering past records.
  - `updateHistoryEntriesWithNewParameters({...})` [`lib/src/data/history_manager.dart:13`](lib/src/data/history_manager.dart:13): Recomputes targets for today and future based on new plan while keeping history intact.

## lib/src/models/daily_thing.dart
- `DailyThing` class [`lib/src/models/daily_thing.dart:11`](lib/src/models/daily_thing.dart:11): Represents a daily task with rules, history, and settings.
  - `increment` getter [`lib/src/models/daily_thing.dart:46`](lib/src/models/daily_thing.dart:46): Gives the per-day change for this task.
  - `todayValue` getter [`lib/src/models/daily_thing.dart:50`](lib/src/models/daily_thing.dart:50): Gives today's target for this task.
  - `displayValue` getter [`lib/src/models/daily_thing.dart:54`](lib/src/models/daily_thing.dart:54): Gives what to show in the UI today.
  - `determineStatus(double currentValue)` [`lib/src/models/daily_thing.dart:58`](lib/src/models/daily_thing.dart:58): Returns green/red status for the current value.
  - `isDone(double currentValue)` [`lib/src/models/daily_thing.dart:62`](lib/src/models/daily_thing.dart:62): Tells if today is completed for this task.
  - `lastCompletedDate` getter [`lib/src/models/daily_thing.dart:66`](lib/src/models/daily_thing.dart:66): Finds when you last finished this task.
  - `todayHistoryEntry` getter [`lib/src/models/daily_thing.dart:70`](lib/src/models/daily_thing.dart:70): Gets the history entry for today, if it exists.
  - `isSnoozedForToday` getter [`lib/src/models/daily_thing.dart:78`](lib/src/models/daily_thing.dart:78): Checks if the task has been marked as snoozed for today.
  - `isDueToday` getter [`lib/src/models/daily_thing.dart:82`](lib/src/models/daily_thing.dart:82): Says if the task needs doing today based on its frequency.
  - `completedForToday` getter [`lib/src/models/daily_thing.dart:129`](lib/src/models/daily_thing.dart:129): Says if today counts as done (if not due, it's considered done).
  - `hasBeenDoneLiterallyToday` getter [`lib/src/models/daily_thing.dart:146`](lib/src/models/daily_thing.dart:146): Checks if today's history entry is explicitly marked as done.
  - `shouldShowInList` getter [`lib/src/models/daily_thing.dart:157`](lib/src/models/daily_thing.dart:157): Determines if this item should be shown in the list based on due status and completion.
  - `toJson({bool includeHistory = true})` [`lib/src/models/daily_thing.dart:169`](lib/src/models/daily_thing.dart:169): Converts this item to a JSON map, optionally excluding history for templates.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/daily_thing.dart:191`](lib/src/models/daily_thing.dart:191): Builds the item from a JSON map.
  - `copyWith({...})` [`lib/src/models/daily_thing.dart:233`](lib/src/models/daily_thing.dart:233): Creates a copy of the item with specified fields updated.
  - `isArchived` field [`lib/src/models/daily_thing.dart:34`](lib/src/models/daily_thing.dart:34): Indicates whether the item is archived (hidden from main view).
  - `notificationEnabled` field [`lib/src/models/daily_thing.dart:35`](lib/src/models/daily_thing.dart:35): Enables nag notifications for the task.

## lib/src/services/notification_service.dart
- `NotificationService` class [`lib/src/services/notification_service.dart:13`](lib/src/services/notification_service.dart:13): Singleton service managing local notifications for daily tasks.
  - `initialize({GlobalKey<NavigatorState>? navigatorKey})` [`lib/src/services/notification_service.dart:67`](lib/src/services/notification_service.dart:67): Configures timezones and initializes the local notification plugin.
  - `requestPermissions()` [`lib/src/services/notification_service.dart:99`](lib/src/services/notification_service.dart:99): Requests required notification and alarm permissions from the user.
  - `scheduleNotification(DailyThing item)` [`lib/src/services/notification_service.dart:170`](lib/src/services/notification_service.dart:170): Schedules a recurring or one-time notification for a specific task.
  - `cancelNotification(String itemId)` [`lib/src/services/notification_service.dart:344`](lib/src/services/notification_service.dart:344): Cancels any scheduled notifications for the given task.
  - `cancelAllNotifications()` [`lib/src/services/notification_service.dart:353`](lib/src/services/notification_service.dart:353): Cancels all scheduled notifications for the app.
  - `rescheduleAllNotifications(List<DailyThing> items)` [`lib/src/services/notification_service.dart:362`](lib/src/services/notification_service.dart:362): Re-schedules notifications for all active and enabled tasks.
  - `onItemCompleted(DailyThing item)` [`lib/src/services/notification_service.dart:379`](lib/src/services/notification_service.dart:379): Re-schedules the notification when a task is completed for the day.
  - `testNotification(DailyThing item)` [`lib/src/services/notification_service.dart:394`](lib/src/services/notification_service.dart:394): Immediately schedules a test notification for verification.

## lib/src/models/history_entry.dart
- `HistoryEntry` class [`lib/src/models/history_entry.dart:6`](lib/src/models/history_entry.dart:6): A single day's record of target/actual progress, with optional comment and snoozed status.
  - `toJson()` [`lib/src/models/history_entry.dart:19`](lib/src/models/history_entry.dart:19): Converts the entry to a JSON map.
  - `fromJson(Map<String, dynamic> json)` [`lib/src/models/history_entry.dart:28`](lib/src/models/history_entry.dart:28): Parses a JSON map into an entry with safe fallbacks.
  - `copyWith({...})` [`lib/src/models/history_entry.dart:73`](lib/src/models/history_entry.dart:73): Creates a copy of the entry with specified fields updated.
  - `comment` field [`lib/src/models/history_entry.dart:8`](lib/src/models/history_entry.dart:8): Stores an optional comment for the history entry.

## lib/src/models/interval_type.dart
- `IntervalType` enum [`lib/src/models/interval_type.dart:1`](lib/src/models/interval_type.dart:1): Defines whether an item repeats by a number of days or on specific weekdays.

## lib/src/models/item_type.dart
- `ItemType` enum [`lib/src/models/item_type.dart:1`](lib/src/models/item_type.dart:1): The type of task: minutes, reps, check, percentage, or trend.

## lib/src/models/status.dart
- `Status` enum [`lib/src/models/status.dart:1`](lib/src/models/status.dart:1): Simple green or red state for display.

## lib/src/services/backup_service.dart
- `BackupType` enum [`lib/src/services/backup_service.dart:11`](lib/src/services/backup_service.dart:11): Defines the type of backup operation (full or template).
- `BackupService` class [`lib/src/services/backup_service.dart:13`](lib/src/services/backup_service.dart:13): Handles file system operations for creating and restoring backups and templates.
  - `_getPlatformSpecificBackupDir()` [`lib/src/services/backup_service.dart:29`](lib/src/services/backup_service.dart:29): Returns the root backup directory, using a `DailyIncBackups` subfolder on desktop.
  - `getBackupsDir()` [`lib/src/services/backup_service.dart:42`](lib/src/services/backup_service.dart:42): Gets the directory for storing full backups (`/backups`), nested within the platform-specific root.
  - `getTemplatesDir()` [`lib/src/services/backup_service.dart:51`](lib/src/services/backup_service.dart:51): Gets the directory for storing template backups (`/templates`), nested within the platform-specific root.
  - `writeBackup(String data)` [`lib/src/services/backup_service.dart:60`](lib/src/services/backup_service.dart:60): Writes a timestamped full backup file to the backups directory.
  - `writeTemplate(String data)` [`lib/src/services/backup_service.dart:69`](lib/src/services/backup_service.dart:69): Writes a timestamped template file to the templates directory.
  - `getBackupFiles()` [`lib/src/services/backup_service.dart:89`](lib/src/services/backup_service.dart:89): Gets a list of all available full backup files.
  - `getTemplateFiles()` [`lib/src/services/backup_service.dart:102`](lib/src/services/backup_service.dart:102): Gets a list of all available template files.
  - `restoreFromBackup(File backupFile)` [`lib/src/services/backup_service.dart:114`](lib/src/services/backup_service.dart:114): Restores a full backup from a given file.
  - `restoreFromTemplate(File templateFile)` [`lib/src/services/backup_service.dart:138`](lib/src/services/backup_service.dart:138): Restores a template from a given file.
  - `createBackup(List<DailyThing> items, BackupType type)` [`lib/src/services/backup_service.dart:187`](lib/src/services/backup_service.dart:187): Creates either a full or template backup based on the `BackupType`. Now uses a tiered retention policy for cleanup.
  - `_cleanupOldBackups()` [`lib/src/services/backup_service.dart:207`](lib/src/services/backup_service.dart:207): Implements a tiered retention policy to manage backup files.

## lib/src/services/update_service.dart
- `UpdateService` class [`lib/src/services/update_service.dart:10`](lib/src/services/update_service.dart:10): Handles app update checks, downloads, and installation.
  - `getLatestRelease()` [`lib/src/services/update_service.dart:13`](lib/src/services/update_service.dart:13): Fetches release details from the GitHub API.
  - `getCurrentAppVersion()` [`lib/src/services/update_service.dart:30`](lib/src/services/update_service.dart:30): Retrieves the current installed app version.
  - `isUpdateAvailable()` [`lib/src/services/update_service.dart:35`](lib/src/services/update_service.dart:35): Checks if a newer version is available on GitHub.
  - `getDownloadUrl()` [`lib/src/services/update_service.dart:63`](lib/src/services/update_service.dart:63): Figures out the correct asset download URL for the platform.
  - `downloadUpdate()` [`lib/src/services/update_service.dart:82`](lib/src/services/update_service.dart:82): Downloads the update APK file to external storage.
  - `installUpdate()` [`lib/src/services/update_service.dart:104`](lib/src/services/update_service.dart:104): Installs the downloaded APK update file.

## lib/src/theme/app_theme.dart
- `AppTheme` class [`lib/src/theme/app_theme.dart:5`](lib/src/theme/app_theme.dart:5): Central place for the app's dark theme look and feel.
  - `darkTheme` getter [`lib/src/theme/app_theme.dart:6`](lib/src/theme/app_theme.dart:6): Provides colors, fonts, and styles for dark mode.

## lib/src/theme/color_palette.dart
- `ColorPalette` class [`lib/src/theme/color_palette.dart:3`](lib/src/theme/color_palette.dart:3): Defines the app colors used across the UI.
  - Constants like `primaryBlue`, `darkBackground`, `cardBackground` [`lib/src/theme/color_palette.dart:4`](lib/src/theme/color_palette.dart:4): Named colors for consistent styling.

## lib/src/views/add_edit_daily_item_view.dart
- `AddEditDailyItemView` class [`lib/src/views/add_edit_daily_item_view.dart:20`](lib/src/views/add_edit_daily_item_view.dart:20): Screen to create or edit a daily task.
- `_AddEditDailyItemViewState` class [`lib/src/views/add_edit_daily_item_view.dart:33`](lib/src/views/add_edit_daily_item_view.dart:33): Handles form state and input controllers.
  - `_submitDailyItem()` [`lib/src/views/add_edit_daily_item_view.dart:286`](lib/src/views/add_edit_daily_item_view.dart:286): Validates, updates history for plan changes, saves, and automatically saves template to backup location if template parameters changed.
  - `_storeOriginalTemplate()` [`lib/src/views/add_edit_daily_item_view.dart:228`](lib/src/views/add_edit_daily_item_view.dart:228): Stores original template parameters for change detection.
  - `_haveTemplateParametersChanged()` [`lib/src/views/add_edit_daily_item_view.dart:250`](lib/src/views/add_edit_daily_item_view.dart:250): Checks if template parameters have changed compared to original.
  - `build(BuildContext context)` [`lib/src/views/add_edit_daily_item_view.dart:522`](lib/src/views/add_edit_daily_item_view.dart:522): Renders the item form UI.

## lib/src/views/category_graph_view.dart
- `CategoryGraphView` class [`lib/src/views/category_graph_view.dart:10`](lib/src/views/category_graph_view.dart:10): Shows graphs of progress for each category with time range filtering.

## lib/src/views/daily_thing_item.dart
- `DailyThingItem` class [`lib/src/views/daily_thing_item.dart:16`](lib/src/views/daily_thing_item.dart:16): A single task row with controls and quick actions.
- `_DailyThingItemState` class [`lib/src/views/daily_thing_item.dart:50`](lib/src/views/daily_thing_item.dart:50): Manages expansion and tap actions for the item.
  - `_formatValue(double value, ItemType itemType)` [`lib/src/views/daily_thing_item.dart:94`](lib/src/views/daily_thing_item.dart:94): Formats minutes, reps, percentage, trend, or check for display.
  - `build(BuildContext context)` [`lib/src/views/daily_thing_item.dart:113`](lib/src/views/daily_thing_item.dart:113): Draws the row UI and handles tap actions.
  - `_archiveItem(DailyThing item)` [`lib/src/views/daily_thing_item.dart:129`](lib/src/views/daily_thing_item.dart:129): Archives or unarchives an item.
  - `_buildActionButtons(DailyThing item)` [`lib/src/views/daily_thing_item.dart:356`](lib/src/views/daily_thing_item.dart:356): Builds the action buttons row with archive functionality.

## lib/src/views/daily_things_view.dart
- `DailyThingsView` class [`lib/src/views/daily_things_view.dart:28`](lib/src/views/daily_things_view.dart:28): The home screen that lists all tasks and actions.
- `_DailyThingsViewState` class [`lib/src/views/daily_things_view.dart:35`](lib/src/views/daily_things_view.dart:35): Loads, filters, reorders, and manages dialogs/snackbars.
  - `_showRepsInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:620`](lib/src/views/daily_things_view.dart:620): Prompts to enter reps and saves them.
  - `_showPercentageInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:631`](lib/src/views/daily_things_view.dart:631): Prompts to enter percentage (0-100%) via slider and saves them.
  - `_showTrendInputDialog(DailyThing item)` [`lib/src/views/daily_things_view.dart:642`](lib/src/views/daily_things_view.dart:642): Prompts to enter trend and saves it.
  - `_showFullscreenTimer(DailyThing item, {bool startInOvertime = false})` [`lib/src_views/daily_things_view.dart:359`](lib/src/views/daily_things_view.dart:359): Shows the fullscreen timer view with navigation context and manages immersive mode.
  - `build(BuildContext context)` [`lib/src/views/daily_things_view.dart:974`](lib/src/views/daily_things_view.dart:974): Builds filters, menus, the reorderable task list, and uses the DailyThingsAppBar widget.
  - `_toggleShowArchivedItems()` [`lib/src/views/daily_things_view.dart:67`](lib/src/views/daily_things_view.dart:67): Toggles between showing and hiding archived items.

## lib/src/views/help_view.dart
- `HelpView` class [`lib/src/views/help_view.dart:8`](lib/src/views/help_view.dart:8): A screen that explains how to use the app with an exact simulation of the appbar layout and detailed explanations of all UI elements.
  - `_createExampleHistory()` method [`lib/src/views/help_view.dart:507`](lib/src/views/help_view.dart:507): Creates realistic example history data for graph demonstrations.

## lib/src/views/reps_input_dialog.dart
- `RepsInputDialog` class [`lib/src/views/reps_input_dialog.dart:7`](lib/src/views/reps_input_dialog.dart:7): Dialog to enter how many reps you did today.

## lib/src/views/percentage_input_dialog.dart
- `PercentageInputDialog` class [`lib/src/views/percentage_input_dialog.dart:7`](lib/src/views/percentage_input_dialog.dart:7): Dialog to enter percentage completion (0-100%) for a task with slider and text input.

## lib/src/views/trend_input_dialog.dart
- `TrendInputDialog` class [`lib/src/views/trend_input_dialog.dart:6`](lib/src/views/trend_input_dialog.dart:6): Dialog to enter trend for the day with optional comment.

## lib/src/views/settings_view.dart
- `SettingsView` class [`lib/src/views/settings_view.dart:15`](lib/src/views/settings_view.dart:15): Settings screen for filters, data actions, and backup configuration.
- `_SettingsViewState` class [`lib/src/views/settings_view.dart:25`](lib/src/views/settings_view.dart:25): Loads preferences and handles save/reset.
  - `_isDesktop` getter [`lib/src/views/settings_view.dart:26`](lib/src/views/settings_view.dart:26): Checks if the current platform is desktop (Linux, macOS, or Windows).
  - `_isAndroid` getter [`lib/src/views/settings_view.dart:28`](lib/src/views/settings_view.dart:28): Checks if the current platform is Android.
  - `_formatBackupFilename(String filename)` [`lib/src/views/settings_view.dart:177`](lib/src/views/settings_view.dart:177): Converts timestamped backup/template filenames to user-friendly date/time format.
  - `_showRestoreDialog(BackupType backupType)` [`lib/src/views/settings_view.dart:191`](lib/src/views/settings_view.dart:191): Shows a dialog to select a backup or template file to restore, displaying user-friendly timestamps.
  - `_restoreBackup(File file, BackupType type)` [`lib/src/views/settings_view.dart:234`](lib/src/views/settings_view.dart:234): Handles the restoration process for both full backups and templates.
  - `_loadBackupPaths()` [`lib/src/views/settings_view.dart:110`](lib/src/views/settings_view.dart:110): Loads the backup and template directory paths for display.
  - `build(BuildContext context)` [`lib/src/views/settings_view.dart:328`](lib/src/views/settings_view.dart:328): Renders the settings UI, conditionally showing backup path info only on desktop platforms, explaining the new retention policy, and showing an Android uninstall warning.

## lib/src/views/history_view.dart
- `HistoryView` class [`lib/src/views/history_view.dart:8`](lib/src/views/history_view.dart:8): A screen to view and edit the history of a daily item.

## lib/src/views/timer_view.dart
- `TimerView` class [`lib/src/views/timer_view.dart:11`](lib/src/views/timer_view.dart:11): A full-screen, minimalist timer for 'Minutes' tasks with initialMinimalistMode parameter to preserve mode during navigation; AppBar title fades using _shouldFadeUI in minimalist mode.
- `_TimerViewState` class [`lib/src/views/timer_view.dart:27`](lib/src/views/timer_view.dart:27): Manages all timer states: countdown, paused, finished, and overtime; initializes _minimalistMode from initialMinimalistMode parameter before async preference load.
  - `_remainingSeconds` variable [`lib/src/views/timer_view.dart:28`](lib/src/views/timer_view.dart:28): Tracks the remaining time in seconds for the countdown timer.
  - `_isPaused` variable [`lib/src/views/timer_view.dart:29`](lib/src/views/timer_view.dart:29): Indicates whether the timer is currently paused.
  - `_hasStarted` variable [`lib/src/views/timer_view.dart:30`](lib/src/views/timer_view.dart:30): Tracks whether the timer has been started at least once.
  - `_isOvertime` variable [`lib/src/views/timer_view.dart:32`](lib/src/views/timer_view.dart:32): Indicates whether the timer is in overtime mode (after completing the target).
  - `_overtimeSeconds` variable [`lib/src/views/timer_view.dart:33`](lib/src/views/timer_view.dart:33): Tracks elapsed overtime in seconds.
  - `_completedSubdivisions` variable [`lib/src/views/timer_view.dart:34`](lib/src/views/timer_view.dart:34): Counts completed subdivisions for bell notifications.
  - `_todaysTargetMinutes` variable [`lib/src/views/timer_view.dart:46`](lib/src/views/timer_view.dart:46): Stores today's target time in minutes for the current task.
  - `_dimScreenMode` variable [`lib/src/views/timer_view.dart:53`](lib/src/views/timer_view.dart:53): Tracks whether dim screen mode is enabled.
  - `_minimalistMode` variable [`lib/src/views/timer_view.dart:57`](lib/src/views/timer_view.dart:57): Tracks whether minimalist mode is enabled.
  - `_shouldFadeUI` variable [`lib/src/views/timer_view.dart:60`](lib/src/views/timer_view.dart:60): Controls UI element fading in minimalist mode.
  - `_isNoteViewMode` variable [`lib/src/views/timer_view.dart:64`](lib/src/views/timer_view.dart:64): Tracks whether note view mode is active.
  - `_currentItem` variable [`lib/src/views/timer_view.dart:65`](lib/src/views/timer_view.dart:65): Reference to the current DailyThing item being timed.
  - `_currentElapsedTimeInMinutes` getter [`lib/src/views/timer_view.dart:67`](lib/src/views/timer_view.dart:67): Calculates and returns the current elapsed time in minutes.
  - `_formatMinutesToMmSs()` method [`lib/src/views/timer_view.dart:92`](lib/src/views/timer_view.dart:92): Formats minutes to MM:SS string representation.
  - `_loadDimScreenPreference()` method [`lib/src/views/timer_view.dart:96`](lib/src/views/timer_view.dart:96): Loads dim screen preference from shared preferences.
  - `_saveDimScreenPreference()` method [`lib/src/views/timer_view.dart:103`](lib/src/views/timer_view.dart:103): Saves dim screen preference to shared preferences.
  - `_loadMinimalistModePreference()` method [`lib/src/views/timer_view.dart:109`](lib/src/views/timer_view.dart:109): Loads minimalist mode preference from shared preferences.
  - `_saveMinimalistModePreference()` method [`lib/src/views/timer_view.dart:116`](lib/src/views/timer_view.dart:116): Saves minimalist mode preference to shared preferences.
  - `_showNoteDialogInEditMode()` method [`lib/src/views/timer_view.dart:124`](lib/src/views/timer_view.dart:124): Shows the note editing dialog in edit mode.
  - `_toggleDimScreenMode()` method [`lib/src/views/timer_view.dart:172`](lib/src/views/timer_view.dart:172): Toggles dim screen mode on/off.
  - `_toggleMinimalistMode()` method [`lib/src/views/timer_view.dart:187`](lib/src/views/timer_view.dart:187): Toggles minimalist mode on/off.
  - `_toggleNoteViewMode()` method [`lib/src/views/timer_view.dart:203`](lib/src/views/timer_view.dart:203): Toggles note view mode on/off.
  - `_startFadeUITimer()` method [`lib/src/views/timer_view.dart:210`](lib/src/views/timer_view.dart:210): Starts the UI fade timer in minimalist mode.
  - `_cancelFadeUITimer()` method [`lib/src/views/timer_view.dart:224`](lib/src/views/timer_view.dart:224): Cancels the UI fade timer.
  - `_buildNoteView()` method [`lib/src/views/timer_view.dart:239`](lib/src/views/timer_view.dart:239): Builds the complete note view UI.
  - `_buildNoteViewTopBar()` method [`lib/src/views/timer_view.dart:278`](lib/src/views/timer_view.dart:278): Builds the top information bar for the note view with fixed-width elements (120px for button, 80px for subdivisions) to prevent layout shifts when button text changes.
  - `_buildNoteViewNotesDisplay()` method [`lib/src/views/timer_view.dart:315`](lib/src/views/timer_view.dart:315): Builds the main notes display with increased font sizes (paragraph: 25, h1: 40, h2: 35, h3: 30) for better readability.
  - `_buildNoteViewBottomButtons()` method [`lib/src/views/timer_view.dart:354`](lib/src/views/timer_view.dart:354): Builds the bottom action buttons for the note view.
  - `_startDimmingProcess()` method [`lib/src/views/timer_view.dart:373`](lib/src/views/timer_view.dart:373): Starts the screen dimming process.
  - `_restoreScreenBrightness()` method [`lib/src/views/timer_view.dart:402`](lib/src/views/timer_view.dart:402): Restores screen brightness to normal.
  - `initState()` method [`lib/src/views/timer_view.dart:413`](lib/src/views/timer_view.dart:413): Initializes the timer state, loads preferences, and sets up initial values.
  - `dispose()` method [`lib/src/views/timer_view.dart:496`](lib/src/views/timer_view.dart:496): Cleans up resources when the widget is disposed.
  - `_toggleTimer()` method [`lib/src/views/timer_view.dart:508`](lib/src/views/timer_view.dart:508): Toggles the timer between running and paused states.
  - `_runOvertime()` method [`lib/src/views/timer_view.dart:562`](lib/src/views/timer_view.dart:562): Runs the overtime timer with subdivision tracking.
  - `_runCountdown()` method [`lib/src/views/timer_view.dart:591`](lib/src/views/timer_view.dart:591): Runs the countdown timer with subdivision tracking.
  - `_onTimerComplete()` method [`lib/src/views/timer_view.dart:679`](lib/src/views/timer_view.dart:679): Handles timer completion, plays sound, and shows next task arrow.
  - `_exitTimerDisplay()` method [`lib/src/views/timer_view.dart:712`](lib/src/views/timer_view.dart:712): Handles exiting the timer display, saving progress if needed.
  - `_showSaveDialog()` method [`lib/src/views/timer_view.dart:772`](lib/src/views/timer_view.dart:772): Shows a dialog to confirm saving progress.
  - `_saveProgress()` method [`lib/src/views/timer_view.dart:797`](lib/src/views/timer_view.dart:797): Saves the current progress to the data manager.
  - `_saveCommentOnly()` method [`lib/src/views/timer_view.dart:835`](lib/src/views/timer_view.dart:835): Saves only the comment without changing progress values.
  - `_findNextUndoneTask()` method [`lib/src/views/timer_view.dart:894`](lib/src/views/timer_view.dart:894): Finds the next undone task in the list after the current item.
  - `_navigateToNextTask()` method [`lib/src/views/timer_view.dart:964`](lib/src/views/timer_view.dart:964): Navigates to the next undone task in the list or exits to main UI, passing current _minimalistMode as initialMinimalistMode for new instances.
  - `_createUpdatedItem()` method [`lib/src/views/timer_view.dart:1034`](lib/src/views/timer_view.dart:1034): Creates an updated DailyThing item with new history.
   - `build()` method [`lib/src/views/timer_view.dart:1064`](lib/src/views/timer_view.dart:1064): Builds the main timer UI or note view UI based on the current mode.
   - `_getButtonText()` method [`lib/src/views/timer_view.dart:1221`](lib/src/views/timer_view.dart:1221): Returns the appropriate text for the timer control button.
   - `_editItem()` method [`lib/src/views/timer_view.dart:1353`](lib/src/views/timer_view.dart:1353): Opens the item editing view.

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

## lib/src/views/widgets/pulse.dart
- `Pulse` class [`lib/src/views/widgets/pulse.dart:4`](lib/src/views/widgets/pulse.dart:4): A widget that creates a pulsing effect around its child.

## lib/src/views/widgets/reorder_helpers.dart
- `reorderDailyThings(...)` [`lib/src/views/widgets/reorder_helpers.dart:16`](lib/src/views/widgets/reorder_helpers.dart:16): Reorders the list of daily things.

## lib/src/views/widgets/add_history_entry_dialog.dart
- `AddHistoryEntryDialog` class [`lib/src/views/widgets/add_history_entry_dialog.dart:7`](lib/src/views/widgets/add_history_entry_dialog.dart:7): A dialog to add a new history entry (currently unused).

## lib/src/views/widgets/next_task_arrow.dart
- `NextTaskArrow` class [`lib/src/views/widgets/next_task_arrow.dart:6`](lib/src/views/widgets/next_task_arrow.dart:6): A pulsing arrow button that appears when a timer completes, with visibility logic based on timer state, animation behavior, and tap gesture handling for navigation.

## lib/src/views/widgets/visibility_and_expand_helpers.dart
- `toggleExpansionForVisibleItems(...)` [`lib/src/views/widgets/visibility_and_expand_helpers.dart:3`](lib/src/views/widgets/visibility_and_expand_helpers.dart:3): Toggles the expansion state of visible items.

## lib/src/views/widgets/filtering_helpers.dart
- `filterDisplayedItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:4`](lib/src/views/widgets/filtering_helpers.dart:4): Filters the list of daily things to be displayed based on showItemsDueToday and hideWhenDone rules.
- `calculateDueItems(...)` [`lib/src/views/widgets/filtering_helpers.dart:48`](lib/src/views/widgets/filtering_helpers.dart:48): Calculates the list of items that are due today for completion status calculation.

## lib/src/views/widgets/mini_graph_widget.dart
- `MiniGraphWidget` class [`lib/src/views/widgets/mini_graph_widget.dart:8`](lib/src/views/widgets/mini_graph_widget.dart:8): A simplified graph widget showing the last 14 days of data for a daily item directly in the expanded view.
  - `_buildSpots()` method [`lib/src/views/widgets/mini_graph_widget.dart:14`](lib/src/views/widgets/mini_graph_widget.dart:14): Extracts data points for the graph, handling trend items with accumulated values.
  - `_buildTrendSpots(List<DateTime> dates, Map<DateTime, dynamic> historyMap)` method [`lib/src/views/widgets/mini_graph_widget.dart:35`](lib/src/views/widgets/mini_graph_widget.dart:35): Builds spots for trend items with accumulated values (today's value = yesterday + today's trend).
  - `_calculateMaxY(List<FlSpot> spots)` method [`lib/src/views/widgets/mini_graph_widget.dart:60`](lib/src/views/widgets/mini_graph_widget.dart:60): Calculates the Y-axis range, allowing negative values for trend items.

## lib/src/views/widgets/timer_display.dart
- `TimerDisplayWidget` class [`lib/src/views/widgets/timer_display.dart:10`](lib/src/views/widgets/timer_display.dart:10): A widget that displays the timer with circular visualization and time text for both countdown and overtime modes.

## lib/src/views/widgets/comment_input.dart
- `CommentInputWidget` class [`lib/src/views/widgets/comment_input.dart:10`](lib/src/views/widgets/comment_input.dart:10): A widget that displays the comment input field with visibility logic based on timer state.

## lib/src/views/helpers/timer_logic.dart
- `TimerLogicHelper` class [`lib/src/views/helpers/timer_logic.dart:7`](lib/src/views/helpers/timer_logic.dart:7): Helper class containing pure functions for timer calculations.
  - `calculateCurrentElapsedTimeInMinutes` method [`lib/src/views/helpers/timer_logic.dart:10`](lib/src/views/helpers/timer_logic.dart:10): Calculates the current elapsed time in minutes based on timer state.
  - `formatMinutesToMmSs` method [`lib/src/views/helpers/timer_logic.dart:18`](lib/src/views/helpers/timer_logic.dart:18): Formats minutes to MM:SS string representation.
  - `calculateElapsedMinutesInCurrentSubdivision` method [`lib/src/views/helpers/timer_logic.dart:23`](lib/src/views/helpers/timer_logic.dart:23): Calculates elapsed minutes in current subdivision.
  - `calculateTotalMinutesInCurrentSubdivision` method [`lib/src/views/helpers/timer_logic.dart:32`](lib/src/views/helpers/timer_logic.dart:32): Calculates total minutes in current subdivision.
  - `calculateOvertimeMinutesInCurrentSubdivision` method [`lib/src/views/helpers/timer_logic.dart:40`](lib/src/views/helpers/timer_logic.dart:40): Calculates overtime minutes in current subdivision.
  - `findTodaysEntry` method [`lib/src/views/helpers/timer_logic.dart:48`](lib/src/views/helpers/timer_logic.dart:48): Finds today's history entry for the current item.
  - `calculateCompletedSubdivisions` method [`lib/src/views/helpers/timer_logic.dart:64`](lib/src/views/helpers/timer_logic.dart:64): Calculates completed subdivisions based on elapsed time and target.
  - `calculatePreciseSubdivisionInterval` method [`lib/src/views/helpers/timer_logic.dart:74`](lib/src/views/helpers/timer_logic.dart:74): Calculates precise subdivision interval.
  - `calculateLastTriggeredSubdivision` method [`lib/src/views/helpers/timer_logic.dart:82`](lib/src/views/helpers/timer_logic.dart:82): Calculates last triggered subdivision.

## lib/src/views/helpers/timer_state.dart
- `TimerStateHelper` class [`lib/src/views/helpers/timer_state.dart:7`](lib/src/views/helpers/timer_state.dart:7): Helper class for managing complex state transitions in the timer.
 - `initializeTimerState` method [`lib/src/views/helpers/timer_state.dart:10`](lib/src/views/helpers/timer_state.dart:10): Initializes timer state based on today's history entry.
  - `updateStateOnTimerComplete` method [`lib/src/views/helpers/timer_state.dart:25`](lib/src/views/helpers/timer_state.dart:25): Updates timer state when timer completes.
  - `updateStateOnExitTimerDisplay` method [`lib/src/views/helpers/timer_state.dart:37`](lib/src/views/helpers/timer_state.dart:37): Updates timer state when exiting timer display.
  - `updateStateOnToggleTimer` method [`lib/src/views/helpers/timer_state.dart:47`](lib/src/views/helpers/timer_state.dart:47): Updates timer state when toggling timer.
  - `updateStateOnRunCountdown` method [`lib/src/views/helpers/timer_state.dart:58`](lib/src/views/helpers/timer_state.dart:58): Updates timer state when running countdown.
  - `updateStateOnRunOvertime` method [`lib/src/views/helpers/timer_state.dart:67`](lib/src/views/helpers/timer_state.dart:67): Updates timer state when running overtime.
  - `findNextUndoneTask` method [`lib/src/views/helpers/timer_state.dart:76`](lib/src/views/helpers/timer_state.dart:76): Finds the next undone task in the list.

## lib/src/views/helpers/audio_helper.dart
- `AudioHelper` class [`lib/src/views/helpers/audio_helper.dart:7`](lib/src/views/helpers/audio_helper.dart:7): Helper class for handling audio playback functionality.
  - `playTimerCompleteNotification` method [`lib/src/views/helpers/audio_helper.dart:13`](lib/src/views/helpers/audio_helper.dart:13): Plays the timer completion notification sound.
  - `playSubdivisionBell` method [`lib/src/views/helpers/audio_helper.dart:25`](lib/src/views/helpers/audio_helper.dart:25): Plays the subdivision bell sound.
  - `dispose` method [`lib/src/views/helpers/audio_helper.dart:44`](lib/src/views/helpers/audio_helper.dart:44): Disposes of the audio players to free up resources.

## lib/src/views/widgets/note_view.dart
- `NoteViewWidget` class [`lib/src/views/widgets/note_view.dart:7`](lib/src/views/widgets/note_view.dart:7): A widget that displays the note view UI for a DailyThing item with timer controls and Markdown rendering.
  - `build(BuildContext context)` method [`lib/src/views/widgets/note_view.dart:17`](lib/src/views/widgets/note_view.dart:17): Builds the complete note view UI with top bar, notes display, and bottom buttons.
  - `_buildNoteViewTopBar()` method [`lib/src/views/widgets/note_view.dart:60`](lib/src/views/widgets/note_view.dart:60): Builds the top information bar for the note view with fixed-width elements (120px for button, 80px for subdivisions) to prevent layout shifts when button text changes.
  - `_buildNoteViewNotesDisplay()` method [`lib/src/views/widgets/note_view.dart:97`](lib/src/views/widgets/note_view.dart:97): Builds the main notes display with increased font sizes (paragraph: 25, h1: 40, h2: 35, h3: 30) for better readability.
  - `_buildNoteViewBottomButtons()` method [`lib/src/views/widgets/note_view.dart:136`](lib/src/views/widgets/note_view.dart:136): Builds the bottom action buttons for the note view.
  - `_formatMinutesToMmSs()` method [`lib/src/views/widgets/note_view.dart:154`](lib/src/views/widgets/note_view.dart:154): Formats minutes to MM:SS string representation.

## lib/src/views/widgets/timer_app_bar.dart
- `TimerAppBarWidget` class [`lib/src/views/widgets/timer_app_bar.dart:7`](lib/src/views/widgets/timer_app_bar.dart:7): A widget that displays the app bar with its actions for the timer view.

## lib/src/views/widgets/timer_controls.dart
- `TimerControlsWidget` class [`lib/src/views/widgets/timer_controls.dart:10`](lib/src/views/widgets/timer_controls.dart:10): A widget that displays the timer control buttons (Start/Pause/Continue and Exit) with dynamic button text based on timer state.

## lib/src/views/widgets/subdivision_display.dart
- `SubdivisionDisplayWidget` class [`lib/src/views/widgets/subdivision_display.dart:12`](lib/src/views/widgets/subdivision_display.dart:12): A widget that displays subdivision information for the timer in different modes (normal/overtime) with proper formatting and visibility logic.

## lib/src/views/widgets/dimming_overlay.dart
- `DimmingOverlayWidget` class [`lib/src/views/widgets/dimming_overlay.dart:6`](lib/src/views/widgets/dimming_overlay.dart:6): A widget that displays the screen dimming overlay for the timer view with tap gesture handling to temporarily restore visibility.

## lib/src/views/graph_view.dart
- `GraphView` class [`lib/src/views/graph_view.dart:11`](lib/src/views/graph_view.dart:11): A full-screen graph view for individual daily items with time range selection and trend line display.
  - `_buildSpots()` method [`lib/src/views/graph_view.dart:137`](lib/src/views/graph_view.dart:137): Builds data points for the graph, handling trend items with accumulated values.
  - `_buildTrendSpots(List<DateTime> dates, Map<DateTime, dynamic> historyMap)` method [`lib/src/views/graph_view.dart:149`](lib/src/views/graph_view.dart:149): Builds spots for trend items with accumulated values (today's value = yesterday + today's trend).
  - `_calculateRanges()` method [`lib/src/views/graph_view.dart:59`](lib/src/views/graph_view.dart:59): Calculates graph Y-axis ranges, allowing negative values for trend items.

## lib/src/views/category_graph_view.dart

- `CategoryGraphView` class [`lib/src/views/category_graph_view.dart:12`](lib/src/views/category_graph_view.dart:12): Shows graphs of progress for each category with time range filtering.

  - `_processCategoryData()` method [`lib/src/views/category_graph_view.dart:58`](lib/src/views/category_graph_view.dart:58): Processes category data, handling trend items with accumulated values.

  - `_getTrendAccumulatedValue(DailyThing thing, DateTime targetDate)` method [`lib/src/views/category_graph_view.dart:395`](lib/src/views/category_graph_view.dart:395): Calculates the accumulated value for a trend item up to the specified date.

  - `_categoryHasTrendItems(String category)` method [`lib/src/views/category_graph_view.dart:412`](lib/src/views/category_graph_view.dart:412): Checks if a category contains any trend items.



# Conductor Tracks







- [Android Update Process Simplification (android_update_fix_20260215)](../conductor/archive/android_update_fix_20260215/index.md): Fixes and simplifies the update process for Android.




