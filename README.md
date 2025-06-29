# Daily Inc

A simple Flutter app for doing things DAILY and with INCREMENTAL improvement over time. 

## Run on Linux

```bash
flutter run -d linux
```

## Build AppImage

Build the Linux version and create an AppImage from it.

```bash
flutter build linux
./android/appimagetool.AppImage daily_inc_timer.AppDir
```

The resulting AppImage will be created in the current directory.

## Debug Android

```bash
adb logcat | grep -i flutter
```
