# Plan — auto-update in the background

## Architecture decisions
- **State holder:** new `AppUpdateController extends ChangeNotifier` in `lib/src/services/app_update_controller.dart`. Mirrors dpd's `AppUpdateNotifier` shape but in vanilla Flutter. Single instance owned by `_DailyThingsViewState`.
- **Status enum:** `AppUpdateStatus { idle, checking, downloading, readyToInstall, error }` — same as dpd.
- **Foreground service:** add `flutter_foreground_task`; create `lib/src/services/foreground_download_service.dart` ported almost verbatim from dpd (drop the DB-download method, keep app-download).
- **Wi-Fi gate:** add `connectivity_plus`. Toggle stored in `SharedPreferences` key `wifiOnlyUpdates`, default `false`.
- **Install path:** keep `apk_install` (already a dep). `UpdateService.installUpdate` already exists.
- **No fallback icon.** Full automation. Manual update UI in `app_bar.dart` is deleted.
- **Debug skip:** wrap entry point with `if (kDebugMode) return;` like dpd.
- **Permission UX:** direct system prompt via `permission_handler`, not a custom AlertDialog.

## Phases

### Phase 1 — Add deps and Android manifest plumbing
- [ ] Add `flutter_foreground_task: ^9.2.1` and `connectivity_plus: ^6.1.4` to `pubspec.yaml`; run `flutter pub get`.
  → verify: `flutter pub get` exits 0; `pubspec.lock` updated.
- [ ] Update `android/app/src/main/AndroidManifest.xml` per `flutter_foreground_task` README — add `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS` permissions and the service declaration with `foregroundServiceType="dataSync"`.
  → verify: `flutter build apk --debug` succeeds.
- [ ] Phase verify: `flutter analyze` passes.

### Phase 2 — Foreground download service
- [ ] Create `lib/src/services/foreground_download_service.dart` with `initialize()`, `startAppDownload()`, `updateProgress(double)`, `stop()`. No-op on non-Android. Channel id `daily_inc_update`, channel name "App update".
  → verify: file compiles; `flutter analyze` clean.
- [ ] Call `ForegroundDownloadService.initialize()` once in `main.dart` after `WidgetsFlutterBinding.ensureInitialized()`.
  → verify: app launches in debug without runtime errors on Android.
- [ ] Phase verify: build a debug APK, launch — no crash on cold start.

### Phase 3 — Update controller
- [ ] Create `lib/src/services/app_update_controller.dart` with `AppUpdateStatus` enum, `AppUpdateState` class (status, progress, apkPath, latestTag), and `AppUpdateController extends ChangeNotifier`.
- [ ] Implement `checkAndMaybeDownload({required bool wifiOnly})`:
  1. If `kDebugMode` → return.
  2. status=checking; `UpdateService.isUpdateAvailable()`.
  3. Not newer / null → status=idle.
  4. `wifiOnly` && not on Wi-Fi → status=idle.
  5. Request `Permission.requestInstallPackages` if not granted; if denied → status=idle.
  6. status=downloading; `ForegroundDownloadService.startAppDownload()`; `UpdateService.downloadUpdate(onProgress)` updating both `state.progress` and the foreground notification.
  7. On success → status=readyToInstall, apkPath set; `ForegroundDownloadService.stop()`.
  8. On error → status=error then idle (silent), `ForegroundDownloadService.stop()`.
  → verify: `flutter analyze` clean.

### Phase 4 — Wire into UI + Wi-Fi setting + remove manual icon
- [ ] In `_DailyThingsViewState.initState` (`daily_things_view.dart`), replace the `_updateService.isUpdateAvailable().then(...)` block with: instantiate `AppUpdateController`, add a listener that on `readyToInstall` shows a SnackBar "Installing update v<tag>…" and calls `UpdateService.installUpdate(File(state.apkPath))`. Kick off `controller.checkAndMaybeDownload(wifiOnly: prefs.getBool('wifiOnlyUpdates') ?? false)`.
- [ ] Remove `_updateAvailable` field, `_updateService` field, related state in `_DailyThingsViewState` that only existed to drive the icon.
- [ ] In `lib/src/views/app_bar.dart`, **delete**: `updateAvailable` parameter, the conditional `IconButton` rendering it, `_handleUpdate`, `_startAutomatedUpdate`, `_openReleasePage`, `_downloadWithProgress`, the `_DownloadProgressDialog` widget, the `_updateService` field, and any now-orphan imports (`apk_install`, `permission_handler`, `url_launcher`, `update_service`, `dart:io`).
  → verify: `grep -n "update" lib/src/views/app_bar.dart` shows no update-related references.
- [ ] Update the `DailyThingsAppBar` constructor call site in `daily_things_view.dart` to remove the `updateAvailable` arg.
- [ ] Add a Wi-Fi-only toggle to `settings_view.dart` (mirror existing `hideWhenDone` pattern), persisted to `SharedPreferences` key `wifiOnlyUpdates`. Default `false`.
  → verify: toggle persists across restart.
- [ ] Phase verify: full manual run-through on a physical Android device covering the "How we'll know it's done" matrix from the spec.

### Phase 5 — Cleanup
- [ ] `flutter analyze`; fix anything new.
- [ ] `grep -rn "isUpdateAvailable\|_updateAvailable\|updateAvailable" lib/` — should only show the controller and `UpdateService`.
- [ ] `grep -rn "DownloadProgressDialog\|_handleUpdate\|_openReleasePage" lib/` — should be empty.
  → verify: greps clean; analyze clean.
