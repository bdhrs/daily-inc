# Daily Inc

A simple Flutter app for doing things DAILY and with INCREMENTAL improvement over time. 

## Building AppImage

1. First build the Linux version
2. Then create the AppImage

```bash
flutter build linux
./android/appimagetool.AppImage daily_inc_timer.AppDir
```

The resulting AppImage will be created in the current directory.

