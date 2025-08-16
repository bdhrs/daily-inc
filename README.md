# Daily Inc

A simple Flutter app for doing things DAILY with INCREMENTAL improvement over time.

Start small (e.g., 5 minutes) and build up steadily. Track three item types:
- MINUTES: run a countdown timer for time-based activities
- REPS: enter how many repetitions you did
- CHECK: mark done or not done

## Features (at a glance)
- Daily targets auto-adjust using simple rules
- Category graphs to see progress over time
- Import/export data to JSON
- Optional “hide when done” and “show only due” filters
- Dark theme with readable colors

See the full project map for where things live: [`project_map.md`](project_map.md)

## Quick start (Linux)
```bash
flutter run -d linux
```

## Build and Install on Android (Debug)
To automatically build and install the app on a connected Android device or emulator for debugging, run the following command. This will also enable hot-reloading.

```bash
flutter run
```

## Install Release APK on Android
After building the release APK using `flutter build apk --release`, you can install it on a connected device using the Android Debug Bridge (adb):

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Build
### Linux AppImage:
```bash
flutter build linux
cp -r build/linux/x64/release/bundle/* daily_inc.AppDir/
./android/appimagetool.AppImage daily_inc.AppDir
```


### Android Release APK:**
```bash
flutter build apk --release
# The release APK will be located at build/app/outputs/flutter-apk/app-release.apk
```

### iOS (on macOS with Xcode):
```bash
flutter build ios --release
open ios/Runner.xcworkspace
# Then Archive in Xcode and export
```

### iOS (on macOS with Xcode):
```bash
flutter build ios --release
open ios/Runner.xcworkspace
# Then Archive in Xcode and export
```

## Debug
Android logs:
```bash
adb logcat | grep -i flutter
```

## Update Icons
1) Edit `assets/icon/icon.svg`
2) Export `assets/icon/icon.png`
3) Generate:
```bash
flutter pub run flutter_launcher_icons
```

## Automated Release

1.  Navigate to the "Actions" tab in the GitHub repository.
2.  Under "Workflows", select the "Release" workflow.
3.  Click the "Run workflow" dropdown button.
4.  Choose the `Release Type`:
    *   `minor`: For new features. This will merge `dev` into `main` and create a new minor version (e.g., `1.2.x` -> `1.3.0`).
    *   `patch`: For hotfixes. This will release directly from the `main` branch and create a new patch version (e.g., `1.2.5` -> `1.2.6`).
5.  Click the "Run workflow" button.

The workflow will handle version bumping, building, and creating a GitHub Release with the APK and AppImage artifacts.