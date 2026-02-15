# Tech Stack - Daily Inc

## Core Framework
- **Language:** Dart
- **Framework:** Flutter (Cross-platform: Android, iOS, Linux, macOS, Web, Windows)

## Data & Storage
- **Local Storage:** `shared_preferences` for app settings and simple key-value data.
- **File System:** JSON-based persistent storage using `path_provider` for habit data and history.
- **Data Portability:** Manual JSON import/export functionality.

## State Management
- **Hybrid Approach:** Utilizes `Get` for some reactive state and dependency injection, alongside standard `StatefulWidget` (`setState`) for local UI state.

## Notifications & Scheduling
- **Engine:** `flutter_local_notifications` for cross-platform local alerts.
- **Timezone Support:** `timezone` and `flutter_timezone` for accurate local-time scheduling.
- **Permissions:** `permission_handler` for managing system-level notification and alarm permissions.

## UI & User Experience
- **Typography:** `google_fonts` for consistent branding.
- **Data Visualization:** `fl_chart` for category-based progress graphs.
- **Screen Control:** `wakelock_plus` to prevent screen dimming during active timer sessions.
- **Formatting:** `intl` for localized date and time representation.

## Networking & System
- **HTTP Client:** `dio` for update checks and potential external API interactions.
- **App Metadata:** `package_info_plus` and `url_launcher`.
