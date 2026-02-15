android:
    flutter run

linux:
    flutter run -d linux

debug:
    adb logcat | grep -i flutter

build-install:
    flutter build apk --release
    adb install build/app/outputs/flutter-apk/app-release.apk
