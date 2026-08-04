# Show this list (what you get when you run `just` with no arguments)
default:
    @just --list

# Build a release APK and print its path — builds only, installs nothing
apk:
    flutter build apk --release --no-pub
    @echo ""
    @echo "========================================="
    @echo "APK ready:"
    @echo "  $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
    @echo "========================================="

# Run on the connected phone from source, with hot reload — for development
android-run:
    flutter run

# Run on this desktop, with hot reload — fastest way to try a UI change
linux:
    flutter run -d linux

# Same as `linux` but skips `pub get`, so it keeps your pinned package versions
linux-offline:
    flutter run -d linux --no-pub

# Tail the phone's log, filtered to Flutter lines — run in a second terminal
debug:
    adb logcat | grep -i flutter

# Build a release APK and replace the app on the connected device, keeping its data
update:
    flutter build apk --release --no-pub
    adb install -r build/app/outputs/flutter-apk/app-release.apk

# Same as `update` but runs `pub get` first — only if you changed dependencies
android-install:
    flutter build apk --release
    adb install -r build/app/outputs/flutter-apk/app-release.apk

# Identical to `update` — kept so old habits/notes still work
android-install-offline:
    flutter build apk --release --no-pub
    adb install -r build/app/outputs/flutter-apk/app-release.apk

# Install a debug build instead — slower app, but shows full errors and logs
android-install-debug:
    flutter build apk --debug
    adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Change the version in pubspec.yaml — CAUTION: a bump on main triggers a release
version:
    @CURRENT_FULL=$(grep "^version: " pubspec.yaml | cut -d " " -f 2) && \
    CURRENT_VER=$(echo $CURRENT_FULL | cut -d "+" -f 1) && \
    CURRENT_BUILD=$(echo $CURRENT_FULL | cut -s -d "+" -f 2) && \
    echo "Current version: $CURRENT_FULL" && \
    printf "Enter new version: " && \
    read INPUT_VER && \
    if echo "$INPUT_VER" | grep -q "+"; then \
        NEW_VERSION="$INPUT_VER"; \
    elif [ -n "$CURRENT_BUILD" ]; then \
        NEW_VERSION="$INPUT_VER+$CURRENT_BUILD"; \
    else \
        NEW_VERSION="$INPUT_VER"; \
    fi && \
    sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml && \
    echo "Version updated to $NEW_VERSION in pubspec.yaml"
