# Implementation Plan: Custom Android Notification Status Bar Icon

## Phase 1: Create Notification Icon Assets
- [ ] Task: Create white silhouette checkmark-in-circle icon
    - [ ] Design icon as white shape with transparent background (alpha channel only)
    - [ ] Icon should be checkmark outline inside circle outline (both white on transparent)
    - [ ] Export PNG files in required densities:
        - [ ] drawable-mdpi/ic_notification.png (24x24 px)
        - [ ] drawable-hdpi/ic_notification.png (36x36 px)
        - [ ] drawable-xhdpi/ic_notification.png (48x48 px)
        - [ ] drawable-xxhdpi/ic_notification.png (72x72 px)
        - [ ] drawable-xxxhdpi/ic_notification.png (96x96 px)
- [ ] Task: Add icon resources to Android project
    - [ ] Create drawable-mdpi directory if needed
    - [ ] Create drawable-hdpi directory if needed
    - [ ] Create drawable-xhdpi directory if needed
    - [ ] Create drawable-xxhdpi directory if needed
    - [ ] Create drawable-xxxhdpi directory if needed
    - [ ] Place ic_notification.png in each density folder
- [ ] Task: Conductor - User Manual Verification 'Create Notification Icon Assets' (Protocol in workflow.md)

## Phase 2: Update Notification Service Configuration
- [ ] Task: Update AndroidInitializationSettings to use custom icon
    - [ ] Change `AndroidInitializationSettings('@mipmap/launcher_icon')` to `AndroidInitializationSettings('ic_notification')`
    - [ ] Note: Icon name is referenced without extension or @ prefix for drawable resources
- [ ] Task: Verify existing AndroidNotificationDetails uses default icon
    - [ ] Confirm no `icon` parameter override in AndroidNotificationDetails (uses default from init)
- [ ] Task: Run tests and static analysis
    - [ ] Run `flutter test`
    - [ ] Run `flutter analyze`
- [ ] Task: Conductor - User Manual Verification 'Update Notification Service Configuration' (Protocol in workflow.md)

## Phase 3: Configure Release Build Resource Preservation
- [ ] Task: Create keep.xml to prevent R8 from removing drawable resources
    - [ ] Create file at `android/app/src/main/res/raw/keep.xml`
    - [ ] Add content to preserve all drawable resources including ic_notification
- [ ] Task: Conductor - User Manual Verification 'Configure Release Build Resource Preservation' (Protocol in workflow.md)

## Phase 4: Verification & Testing
- [ ] Task: Build and test on Android device
    - [ ] Build Android debug APK
    - [ ] Trigger test notification from app
    - [ ] Verify white checkmark-in-circle icon appears in status bar
    - [ ] Verify icon displays correctly in notification shade
    - [ ] Build release APK and verify icon still shows
- [ ] Task: Conductor - User Manual Verification 'Verification & Testing' (Protocol in workflow.md)