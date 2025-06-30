# Daily Inc

A simple Flutter app for doing things DAILY and with INCREMENTAL improvement over time. 

Start with 5min and build up to an 60min over the next month or two. 

Can handle 
- MINUTES provides a timer for time based activities
- REPS for repetitions 
- CHECK for simple done or not done. 

## Run on Linux

```bash
flutter run -d linux
```

## Debug Android

```bash
adb logcat | grep -i flutter
```

## Update Icons

1. Edit `assets/icon/icon.svg`
2. Save to `assets/icon/icon.png`
3. Run flutter_launcher_icons

```
flutter pub run flutter_launcher_icons
```

## Build a Linux AppImage

Build the Linux version and create an AppImage from it. The resulting AppImage will be found in the root directory.

```bash
flutter build linux
cp -r build/linux/x64/release/bundle/* daily_inc.AppDir/
./android/appimagetool.AppImage daily_inc.AppDir
```


## Build for Android
```bash
flutter build apk --release
```


## Build for iOS

Building the iOS version of the app requires a macOS environment with Xcode installed.

1. **Ensure Prerequisites**: Make sure you have macOS with Xcode installed. You will also need to be enrolled in the Apple Developer Program for code signing certificates and provisioning profiles if you intend to deploy to a physical device or the App Store.

2. **Build IPA**: Run the following command to build the iOS app in release mode:
```bash
flutter build ios --release
```

3. **Open in Xcode**: Navigate to the iOS project folder and open it in Xcode for further configuration or to archive the app:
   ```bash
   open ios/Runner.xcworkspace
   ```

4. **Archive and Export**: In Xcode, select "Product" > "Archive" to create an IPA file. Follow the prompts to export the IPA for distribution or testing purposes.

Note: Ensure that your code signing and provisioning profiles are correctly set up in Xcode to avoid build errors when targeting physical devices or App Store distribution.
