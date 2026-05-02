## Thread
- **ID:** 20260502_auto_update
- **Objective:** Port dpd-flutter-app's silent background auto-update flow to daily_inc_timer_flutter

## Files Changed
- `pubspec.yaml` — added `flutter_foreground_task: ^9.2.1`, `connectivity_plus: ^6.1.4`
- `android/app/src/main/AndroidManifest.xml` — added FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC permissions + ForegroundService declaration
- `lib/main.dart` — added `ForegroundDownloadService.initialize()` on startup
- `lib/src/services/foreground_download_service.dart` — new: foreground notification service for download progress
- `lib/src/services/app_update_controller.dart` — new: ChangeNotifier orchestrating check → wifi gate → permission → download → readyToInstall
- `lib/src/views/daily_things_view.dart` — replaced manual update flag with controller + auto-install listener
- `lib/src/views/app_bar.dart` — removed updateAvailable param, download icon, _handleUpdate, _startAutomatedUpdate, _openReleasePage, _DownloadProgressDialog
- `lib/src/views/settings_view.dart` — added Wi-Fi only updates toggle (key: wifiOnlyUpdates, default false)

## Findings
No findings.

## Fixes Applied
- Removed unused `color_palette.dart` import from app_bar.dart (caught by analyzer).

## Test Evidence
- `flutter analyze` → no issues
- Orphan grep for removed symbols → clean (only UpdateService.isUpdateAvailable definition + controller call-site remain)

## Verdict
PASSED
- Review date: 2026-05-02
- Reviewer: kamma (inline)
