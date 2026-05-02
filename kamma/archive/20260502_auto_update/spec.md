# Auto-update in the background (port from dpd-flutter-app)

## GitHub issue
None.

## Overview
The current update flow checks GitHub Releases at startup but only **sets a flag** that shows a download icon in the app bar. The user must (a) tap the icon, (b) confirm permission, (c) watch a modal progress dialog, (d) confirm the Android installer prompt. The dpd-flutter-app's flow is fully automatic up to the OS install prompt — the APK downloads silently behind a foreground-service notification and the installer is auto-launched when the file is ready.

This thread ports that behaviour to `daily_inc_timer_flutter`. The user has chosen full parity with dpd: **no manual icon at all**.

## Reference implementation: dpd-flutter-app
- `lib/services/app_update_service.dart` — GitHub release fetch + APK download (Dio).
- `lib/providers/app_update_provider.dart` — Riverpod `StateNotifier` with `AppUpdateStatus { idle, checking, downloading, readyToInstall, error }`. Skips in `kDebugMode`. Optional Wi-Fi-only gate via `connectivity_plus`. Auto-runs `_downloadUpdate` when newer release detected. Sets `readyToInstall` on success.
- `lib/services/foreground_download_service.dart` — wraps `flutter_foreground_task` to show "Downloading app… NN%" notification while the APK downloads.
- `lib/app.dart` — at startup (after DB ready) calls `appUpdateProvider.checkForUpdates()`. A `ref.listen` fires `OpenFilex.open(apkPath)` when status flips to `readyToInstall`, plus a SnackBar "Installing app update vX.Y.Z…".

## Local app starting state
- `lib/src/services/update_service.dart` — already has `isUpdateAvailable`, `downloadUpdate`, `installUpdate` (uses `apk_install` package). Logic is sound.
- `lib/src/views/daily_things_view.dart:82` — calls `_updateService.isUpdateAvailable()` in `initState`, sets `_updateAvailable = true`.
- `lib/src/views/app_bar.dart` — renders the manual download `IconButton`, runs `_handleUpdate` → permission dialog → `_DownloadProgressDialog` modal → `installUpdate`. **All of this is being removed.**
- State management: plain `StatefulWidget` + `setState`. **No Riverpod** in repo.
- `pubspec.yaml` already has `dio`, `package_info_plus`, `pub_semver`, `permission_handler`, `path_provider`, `apk_install`.

## What it should do
1. At app startup, check GitHub Releases (already happens). Skip in `kDebugMode`.
2. If a newer version is detected, immediately request `requestInstallPackages` permission if not already granted.
3. Once permission granted, **start downloading the APK in the background** — no modal, no user tap, no app-bar icon.
4. Show a foreground-service notification with "Downloading update… NN%" while download proceeds.
5. When download finishes, show a non-blocking SnackBar ("Installing update vX.Y.Z…") and auto-launch the Android installer (`apk_install`). User then sees the standard system install prompt.
6. If permission is denied: silently give up for this session (next launch retries the permission request).
7. If download fails (network, etc.): silently revert to idle. Next launch will retry.
8. Add a "Wi-Fi only updates" toggle in settings (default **off**) — if on, skip auto-download on cellular.

## Assumptions & uncertainties
- **No fallback icon.** User explicitly chose full automation. The whole `_updateAvailable` flag, the app-bar icon, `_handleUpdate`, `_startAutomatedUpdate`, `_DownloadProgressDialog`, and the permission AlertDialog in `app_bar.dart` are deleted.
- **Permission UX:** instead of the bespoke AlertDialog, we call `Permission.requestInstallPackages.request()` directly. Android shows the system "Allow from this source" screen. If user declines, we silently abort.
- **State management:** plain `ChangeNotifier` (not Riverpod). Single `AppUpdateController` instance owned by `_DailyThingsViewState`.
- **Install package:** keep `apk_install` (already a dep) rather than swapping in `open_filex`.
- **Wi-Fi-only setting** persists via `SharedPreferences` like other settings in `settings_view.dart`. Default `false`.
- **Platform scope:** Auto-update is Android-only. iOS/desktop are no-ops (mirrors dpd's `Platform.isAndroid` guards).

## Constraints
- Must not introduce Riverpod.
- Foreground service requires `POST_NOTIFICATIONS` on Android 13+; `flutter_foreground_task` handles requesting.
- Android manifest changes for `flutter_foreground_task` are required (FOREGROUND_SERVICE permissions + service declaration).
- `kDebugMode` short-circuits the entire flow.

## How we'll know it's done
- On a real Android device with a stale install: launching the app triggers a system permission prompt (first time only), then a notification "Downloading update… NN%", and within ~30s the system install prompt appears with no taps required from the user.
- The download icon no longer appears in the app bar under any circumstance.
- In a debug build: nothing happens (no check, no download, no notification).
- Wi-Fi-only on + cellular: no download. Wi-Fi-only on + Wi-Fi: download proceeds.
- `flutter analyze` passes; existing tests pass.

## What's not included
- No "What's new" dialog (dpd has it; can be a follow-up thread).
- No release-notes prefetch.
- No iOS/desktop update flow.
- No new automated tests for the orchestration (existing UpdateService has none; matching that bar). Verification is manual on an Android device.
