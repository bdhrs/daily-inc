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

### Test and Analyze
```bash
flutter test && flutter analyze
```

### Android APK
```bash
flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk
```
 
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

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.

[![CC BY-NC-SA 4.0](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en)

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made.
- **NonCommercial** — You may not use the material for commercial purposes.
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

For the full license text, see: https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
