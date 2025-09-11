# Auto Update Specification

## Current Behavior
`UpdateService` checks for updates via GitHub API but lacks:
- Actual download implementation (`downloadUpdate` returns URL only)
- Platform-specific installation logic (`installUpdate` is stubbed)

## Requirements
1. **Automatic Android Download**
   - Download `.apk` from GitHub release assets

2. **Installation**
   - Save to external storage
   - Trigger install intent with user confirmation

## Implementation Plan
1. Extend `getDownloadUrl()` to return APK URL
2. Implement `downloadUpdate()` to fetch and save APK
3. Implement `installUpdate()` to launch installer

## Security
- Only accept releases from official GitHub repo