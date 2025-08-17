# Daily Inc

A Flutter app to **do the important things daily**, and **increase incrementally** over time.

Track three types of activities:
- MINUTES: run a countdown timer for time-based activities
- REPS: gradually increase your repetitions
- CHECK: mark when done

## Features (at a glance)
- Daily targets auto-adjust using simple rules
- Category graphs to see progress over time
- Import/export data to JSON

## Project Map
See the full project map for where things live: [`project_map.md`](project_map.md)

## Debug

### Linux
```bash
flutter run -d linux
```

### Android
```bash
flutter run
```

### Android logs
```bash
adb logcat | grep -i flutter
```

## Build

### Update Icons
1) Edit `assets/icon/icon.svg`
2) Export `assets/icon/icon.png`
3) Generate:
```bash
flutter pub run flutter_launcher_icons
```

### Android APK
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```
The release APK is located at `build/app/outputs/flutter-apk/app-release.apk`

### Linux AppImage:
```bash
flutter build linux
cp -r build/linux/x64/release/bundle/* daily_inc.AppDir/
./android/appimagetool.AppImage daily_inc.AppDir
```

### iOS (on macOS with Xcode):
```bash
flutter build ios --release
open ios/Runner.xcworkspace
# Then Archive in Xcode and export
```

### GitHub Automated Release 

1.  Navigate to the "Actions" tab in the GitHub repository.
2.  Under "Workflows", select the "Release" workflow.
3.  Click the "Run workflow" dropdown button.
4.  Choose the `Release Type`:
    *   `minor`: For new features. This will merge `dev` into `main` and create a new minor version (e.g., `1.2.x` -> `1.3.0`).
    *   `patch`: For hotfixes. This will release directly from the `main` branch and create a new patch version (e.g., `1.2.5` -> `1.2.6`).
5.  Click the "Run workflow" button.

The workflow will handle version bumping, building, and creating a GitHub Release with the APK and AppImage artifacts.