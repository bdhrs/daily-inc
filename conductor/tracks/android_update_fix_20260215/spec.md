# Specification: Android Update Process Simplification

## Overview
This track aims to fix and simplify the update process for the Android version of Daily Inc. The current process is unreliable, often getting stuck during installation. We will implement a robust hybrid flow that prioritizes automated installation while providing a reliable fallback to manual file saving via a directory picker.

## Functional Requirements
- **Proactive Permission Management:**
    - Before initiating an update download, the app must check for the `REQUEST_INSTALL_PACKAGES` permission (Install Unknown Apps).
    - If missing, the app will prompt the user and redirect them to the specific Android System Settings page to grant it.
- **Hybrid Installation Flow:**
    - **Primary Path (Automated):** If permissions are granted, the app downloads the APK to a temporary cache and triggers the system package installer.
    - **Fallback Path (Manual):** If the user denies permissions or the automated install fails, the app will prompt the user to select a directory using a file picker.
- **User-Directed Saving:**
    - In the fallback path, use a directory/file picker to allow the user to choose the download destination (e.g., `Downloads` folder).
- **Status Communication:**
    - Provide clear progress feedback during the download.
    - Upon successful download in the fallback path, display a dialog confirming the file location and providing instructions/shortcuts to install it.

## Non-Functional Requirements
- **Reliability:** Ensure file streams are properly closed and temporary files are cleaned up.
- **UX Consistency:** Follow existing Material Design patterns for dialogs and progress indicators.

## Acceptance Criteria
- [ ] User is prompted to grant "Install Unknown Apps" permission if not already granted.
- [ ] Automated installation triggers successfully after download when permission is present.
- [ ] If automated install is bypassed or fails, the user can successfully pick a directory and save the APK there.
- [ ] The app does not "hang" or get stuck at any point in the download/install process.

## Out of Scope
- Auto-updating on non-Android platforms (Linux, Windows, etc.).
- Background "silent" updates without user interaction.
