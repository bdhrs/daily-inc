# Specification: Custom Android Notification Status Bar Icon

## Overview
Replace the default Android notification status bar icon with a custom checkmark-in-circle icon. The icon will appear in the Android status bar (next to time and connectivity indicators) when a habit notification is active, providing a distinctive visual indicator that Daily Inc has an active reminder.

## Functional Requirements

### FR-1: Custom Status Bar Icon
- The notification status bar icon shall display as a checkmark inside a circle.
- The icon shall be a white silhouette (alpha channel only) following Android notification icon requirements.
- The icon shall only appear when an active notification exists (not persistent).
- All habit notifications shall use the same custom status bar icon.

### FR-2: Icon Design Requirements
- The icon shall use the app's existing checkmark visual language (`Icons.check` / `Icons.check_circle`).
- The icon must be **white shape on transparent background** (alpha channel only) per Android guidelines.
- Non-transparent colored icons will render as a white/gray square on Android 5.0+.
- The design shall be a checkmark outline within a circle outline (both white).

### FR-3: Icon Sizing
- Icons must be provided in multiple densities:
  - mdpi: 24x24 pixels
  - hdpi: 36x36 pixels
  - xhdpi: 48x48 pixels
  - xxhdpi: 72x72 pixels
  - xxxhdpi: 96x96 pixels

### FR-4: Resource Placement
- Icons shall be placed in `drawable-*` folders (not `mipmap`) per Android official guidance.
- Path: `android/app/src/main/res/drawable-{density}/ic_notification.png`

### FR-5: Notification Configuration
- Update `AndroidInitializationSettings` to reference the custom icon: `AndroidInitializationSettings('ic_notification')`.
- Icon name is referenced without file extension or `@` prefix for drawable resources.

## Non-Functional Requirements

### NFR-1: Android Compatibility
- Icon must follow Android status bar icon guidelines (monochrome white on transparent).
- Must work across all Android API levels supported by the app (Android 5.0+).

### NFR-2: Visual Consistency
- The icon should be recognizable at small sizes (status bar icons are typically 24x24dp).
- The icon should align with the app's visual identity using the checkmark motif.

### NFR-3: Release Build Preservation
- Drawable resources must be preserved in release builds via `keep.xml` to prevent R8 from removing them.
- Path: `android/app/src/main/res/raw/keep.xml`

## Acceptance Criteria
- [ ] When a notification fires, the status bar shows a white checkmark-in-circle icon.
- [ ] The icon is visible in the Android status bar next to time/connectivity icons.
- [ ] When no active notifications exist, the icon is not visible in the status bar.
- [ ] The icon displays correctly in the notification shade when pulled down.
- [ ] The icon renders correctly on both debug and release builds.

## Out of Scope
- iOS notification icons (iOS uses app icon automatically).
- Different icons for different item types (all notifications use same icon).
- Persistent status bar icon mode.
- Colored icons (not supported by Android for status bar small icons).

## Technical Notes
- Android notification small icons only use the alpha channel; any color information is ignored.
- The system renders the icon as white (or tinted by notification color setting).
- Using a non-compliant icon (colored, non-transparent) results in a white/gray square.
- Icons in `mipmap` folders can work but `drawable` is the official recommendation for notification icons.