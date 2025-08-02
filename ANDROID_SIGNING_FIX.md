# Android App Signing Fix

## Problem
When users download the Android app from GitHub and install it, they get an error message saying "Failed to update because the same app is already present". This happens because the app was using the debug signing configuration for release builds, which causes installation conflicts when users try to install a new version over an existing one.

## Solution
We've implemented a proper signing configuration for release builds to ensure each build has a unique signature and can be properly updated.

## Changes Made

### 1. Updated build.gradle.kts
- Added a new signing configuration for release builds
- Changed the release build type to use the new signing configuration instead of debug signing
- Added comments explaining the versionCode and versionName will be overridden by flutter build command

### 2. Created keystore generation script
- Added `android/generate-keystore.sh` script to generate a release keystore
- The script creates a keystore with known credentials for the CI/CD pipeline
- Keystore details:
  - Store password: daily_inc_release
  - Key alias: daily_inc_key
  - Key password: daily_inc_release

### 3. Updated GitHub workflow
- Modified `.github/workflows/test-build.yml` to generate the keystore before building the APK
- Added a step to run the keystore generation script
- This ensures the keystore is available during the build process

### 4. Updated .gitignore
- Added `android/app/release.keystore` to .gitignore
- This prevents the keystore from being committed to the repository
- The keystore will be generated during the build process

## How It Works
1. When the GitHub workflow runs, it first generates the release keystore
2. The keystore is used to sign the release APK
3. Each build has a unique version number based on the GitHub run number
4. The signed APK can be installed over previous versions without conflicts

## Testing
To test the changes:
1. Run the GitHub workflow to build a new APK
2. Download the APK from the artifacts
3. Install it on an Android device
4. Run the workflow again to build a new version
5. Install the new version over the old one
6. Verify that the installation succeeds without conflicts

## Notes
- The keystore credentials are hardcoded in the script for simplicity
- For production use, consider using GitHub Secrets to store the credentials
- The keystore is generated fresh for each build, ensuring consistency
- The versioning strategy uses GitHub run numbers for automatic incrementing