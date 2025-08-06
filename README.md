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

## Build
Linux AppImage:
```bash
flutter build linux
cp -r build/linux/x64/release/bundle/* daily_inc.AppDir/
./android/appimagetool.AppImage daily_inc.AppDir
```

Android:
```bash
flutter build apk --release
```

iOS (on macOS with Xcode):
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
