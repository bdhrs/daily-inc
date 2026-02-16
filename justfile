android:
    flutter run

linux:
    flutter run -d linux

debug:
    adb logcat | grep -i flutter

build-install:
    flutter build apk --release
    adb install build/app/outputs/flutter-apk/app-release.apk

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
