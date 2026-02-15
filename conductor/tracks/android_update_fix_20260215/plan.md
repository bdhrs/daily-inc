# Implementation Plan - Android Update Process Simplification

## Phase 1: Environment & Permissions
- [x] Task: Research and verify `permission_handler` or custom platform channels for `REQUEST_INSTALL_PACKAGES`.
- [x] Task: Implement a permission check utility in `UpdateService` or a dedicated service.
- [x] Task: Add the `REQUEST_INSTALL_PACKAGES` permission to `AndroidManifest.xml` if missing.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Environment & Permissions' (Protocol in workflow.md)

## Phase 2: Core Download & Install Logic
- [x] Task: Refactor `UpdateService.downloadUpdate` to handle downloading to a temporary file using `dio`.
- [x] Task: Implement `UpdateService.installUpdate` using `open_filex` or a custom Intent to trigger the Android package installer.
- [x] Task: Implement a fallback mechanism that triggers `file_picker` if automated installation fails or permissions are denied.
- [x] Task: Ensure proper cleanup of temporary APK files after installation attempt.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Core Download & Install Logic' (Protocol in workflow.md)

## Phase 3: UI Integration & UX
- [x] Task: Update the "Update Available" dialog to include the new download progress indicator.
- [x] Task: Implement the permission request flow (Dialog -> Settings) within the update UI.
- [x] Task: Implement the "Success/Fallback" dialog for manual installation (showing file path and "Open" button).
- [x] Task: Conductor - User Manual Verification 'Phase 3: UI Integration & UX' (Protocol in workflow.md)

## Phase 4: Verification & Cleanup
- [x] Task: Manual end-to-end testing on an Android device/emulator (Automated path).
- [x] Task: Manual end-to-end testing on an Android device/emulator (Fallback/Picker path).
- [x] Task: Run `flutter analyze` and `dart format lib`.
- [x] Task: Conductor - User Manual Verification 'Phase 4: Verification & Cleanup' (Protocol in workflow.md)
