# Daily Inc Timer Flutter - Project Context

This document provides essential context for any AI Coding Agent to understand the **Daily Inc Timer** Flutter project, enabling effective assistance with development tasks.

# Project Map
- A map of the project can be found in `project_map.md`. 
- Read the project map to see where things are.
- Keep this file updated as changes get made

# Project Overview

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

# Building and Running

The project uses standard Flutter commands for development and building, as detailed in the `README.md`:

### Debugging
- **Linux:** `flutter run -d linux`
- **Android:** `flutter run`
- **Android logs:** `adb logcat | grep -i flutter`

### Testing and Analysis
- **Test & Analyze:** `flutter test && flutter analyze` (Uses built-in `lints` package).

### Building
- **Icons:** Generated via `flutter pub run flutter_launcher_icons` after editing `assets/icon/icon.svg/png`.
- **Android APK:** `flutter build apk --release`
- **Linux AppImage:** `flutter build linux` followed by copying the bundle and using `AppImageTool`.
- **iOS:** `flutter build ios --release` then archiving via Xcode.

# Key Concepts and Logic

1.  **Increment Logic (`lib/src/core/increment_calculator.dart`):
    - The target value for a task (`todayValue`) is calculated daily by `IncrementCalculator.calculateTodayValue`.
    - It considers the task's defined increment (`(endValue - startValue) / duration`), the last date the task was completed (`doneToday: true` in history), and a configurable grace period.
    - If done yesterday, the target increments.
    - If missed within the grace period, the target stays the same.
    - If missed beyond the grace period, a penalty is applied (target decreases).
    - This logic is central to the app's 'incremental' nature.

2.  **Display Value (`lib/src/core/increment_calculator.dart`):
    - What is shown in the main list (`displayValue`) differs from the `todayValue` for MINUTES and REPS.
    - For MINUTES: Shows the `todayValue` if the timer hasn't started, or the actual elapsed minutes if the timer has been started/completed.
    - For REPS: Shows the `actualValue` entered for today if it exists, otherwise shows the `todayValue`.
    - For CHECK: Shows the `todayValue` (0.0 for not done, 1.0 for done).

3.  **Timer Logic (`lib/src/views/timer_view.dart`):
    - The `TimerView` manages a countdown timer for MINUTES tasks.
    - It integrates with the `IncrementCalculator` to get the `todayValue` as the starting time.
    - It loads/saves progress (`actualValue`) to the item's history for the current day.
    - Supports an 'overtime' mode after the initial target is met, allowing users to continue the timer and record time beyond the goal.

4.  **Data Persistence (`lib/src/data/data_manager.dart`):
    - Data (the list of `DailyThing` objects) is serialized to and deserialized from JSON.
    - The `DataManager` handles reading from and writing to a file, typically in the app's local storage directory.
    - History for each item is stored within the `DailyThing` object itself.

# Development Conventions

- **Naming:** Files and classes generally follow descriptive names related to their function (e.g., `AddEditDailyItemView`, `DailyThing`).
- **Structure:** Code is organized into logical `lib/src` subdirectories.
- **Widgets:** Complex UI elements are broken down into dedicated widgets in `lib/src/views` and `lib/src/views/widgets`.
- **State Management:** Local widget state is managed with `StatefulWidget` and `setState`. Data state is managed by the `DataManager`.
- **Logging:** Uses the `logging` package for debugging (`Logger` instances).
- **Linting:** Uses the standard `lints` package for code quality (`analysis_options.yaml`).
- **Dependencies:** Managed via `pubspec.yaml`.

# Important Notes for AI Coding Tools

- **NEVER run Flutter commands**: The user is already running the app in the background, so do not execute any `flutter` commands like `flutter run`, `flutter build`. 
- You can run `flutter analyze` to find problems in the code. 
- Always follow the existing code style and conventions when making changes.
- When adding UI elements, follow Material Design principles and existing app styling.

# Edits
- If the edit fails, try to **EDIT THE WHOLE CODE BLOCK**. Edits within code blocks frequently fail.
- If the edit fails again, **REWRITE THE WHOLE FILE**.

# Code Style Guidelines
- Use `flutter_lints` recommended rules from analysis_options.yaml
- Import order: dart, flutter, package, local (src/)
- Use const constructors where possible
- Prefer single quotes for strings
- Use null safety features consistently
- Logging: Use `logging` package with Logger instances
- Error handling: Use try-catch with logging for async operations
- Naming: camelCase for variables/functions, PascalCase for classes/types


# Completion
- After completing any task, give a one line, lowercase, simple git commit message. DO NOT perform any git operations (e.g., git add, git commit) unless explicitly instructed by the user. Only provide the commit message.


# Important Notes for Roocode

### `apply_diff` Tool Rules

1.  **Read First, Then Write**: Before every `apply_diff` attempt, I **must** use the `<read_file>` tool to get the most up-to-date and exact content of the target file.
2.  **`start_line` is gospel**: The `<start_line>` number must correspond to the exact line number in the file where the `SEARCH` block begins.
3.  **The `content` block is sacred**:
    *   The `<content>` parameter must **only** contain the text inside the `<![CDATA[...]]>` wrapper.
    *   This text must start with `<<<<<<< SEARCH`, have one `=======` separator, and end with `>>>>>>> REPLACE`.
    *   No other text, parameters, or comments should be inside the `CDATA` block.
4.  **Whitespace is Everything**: The text in the `SEARCH` block must match the file content character-for-character, including spaces, tabs, and newlines.

# Important Notes for Gemini CLI
If today is Sunday, run `npm install -g @google/gemini-cli@latest` to update to the latest version.
