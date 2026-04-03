# Weekly Review Auto-Open

## Overview
Add a weekly review feature that opens on a scheduled day and time, defaulting to Sunday at 7:00 PM. It opens the existing Progress by Category screen with the 1 Week range selected by default. Users can enable or disable the feature, change the scheduled day and time, and control whether the review also opens on app startup.

## What It Should Do
- Add a weekly review schedule setting stored in local preferences.
- Default the weekly review setting to:
  - enabled = true
  - weekday = Sunday
  - time = 7:00 PM
- Open the existing Progress by Category screen with the 1 Week range selected by default.
- Allow the user to switch to other graph time ranges after the screen opens.
- Open the weekly review automatically when the app is active and the scheduled review time arrives.
- If the app is not active at the scheduled time, schedule a local notification for the weekly review and open the review screen when the user taps that notification.
- Ensure the review opens only once per scheduled occurrence, not repeatedly on every rebuild/resume.
- Add Settings controls to:
  - turn weekly review automation on/off
  - choose weekday
  - choose time
  - turn show-on-startup on/off
- Keep the feature on by default for new and existing installs that do not already have a saved value.

## Constraints
- Stay within the current Flutter app architecture:
  - `SharedPreferences` for settings/state
  - existing `NotificationService` for scheduled notifications
  - existing navigator-based screen opening
- Do not attempt to force the operating system to foreground the app when it is closed/backgrounded; mobile platforms do not reliably allow that. In that case, the supported path is a scheduled notification that opens the review when tapped.
- Follow existing graph styling and settings patterns.
- Keep the change focused; avoid refactoring unrelated graph or notification code.

## How We'll Know It's Done
- A fresh app install defaults to weekly review enabled for Sunday 7:00 PM.
- Settings show weekly review controls and persist changes.
- The existing Progress by Category screen opens with the 1 Week range selected by default.
- Scheduling logic correctly computes the next occurrence from the configured weekday/time.
- The app opens the review automatically when active at the scheduled time.
- A scheduled weekly review notification is created, and tapping it opens the review screen.
- The same review occurrence is not shown multiple times.
- Startup opening is controlled by its own setting and is independent of the scheduled-occurrence guard.
- Automated tests cover schedule calculation and one-time-occurrence behavior.

## What's Not Included
- No background data sync or server-driven scheduling.
- No monthly or custom-range review modes.
- No redesign of the existing graph system beyond what is needed to open the existing category graph screen with a 1-week default.
- No forced app launch without user interaction when the app is not active.
