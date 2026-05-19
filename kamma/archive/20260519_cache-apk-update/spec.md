# Spec — Fix the in-app update loop

## Overview
The in-app updater had two compounding problems:

1. **APK re-downloads every launch.** The updater wrote the APK to a fixed path
   but stored no metadata about which version was on disk, so the controller
   re-downloaded the same APK on every launch when the user dismissed the
   system install prompt — wasting mobile data.

2. **Version namespaces were incoherent.** The release CI workflow computed
   the release version by auto-incrementing the latest git tag, completely
   ignoring `pubspec.yaml`. Local `just android-install` builds embed pubspec's
   version. The two never agreed, so the updater would forever see GitHub as
   "ahead" of locally-installed dev builds, perpetually offering an update
   that often failed to install (typically because the CI-signed APK could
   not replace the locally-signed one).

## What it should do

### Cache behavior
- Download a given update APK at most **once** per release version.
- On every launch where GitHub's latest tag is newer than the installed
  version:
  - If a cached APK for that exact release version exists on disk, skip the
    download and immediately offer install (same path as a fresh download).
  - If a cached APK exists for a stale version, delete it and download the
    new one.
  - Otherwise, download normally.
- Dismissing the system install prompt leaves the cached APK intact, so the
  next launch re-prompts without re-downloading.
- After the user installs the update (no update available next launch), the
  cache is cleared.

### Release workflow
- `pubspec.yaml` is the single source of truth for the release version.
- CI release runs **automatically** on push to `main` whenever `pubspec.yaml`
  changes — no manual `workflow_dispatch`.
- Release runs only if the new pubspec version is strictly higher than the
  previous commit's pubspec version (via `sort -V`), and the corresponding
  `v<version>` tag does not already exist.
- Non-version pubspec edits (dependency bumps, description changes) trigger
  the workflow but harmlessly stop at the prepare step.

## Current behavior (discovered in repo)
- `lib/src/services/update_service.dart` `downloadUpdate()` wrote to a fixed
  path with no version metadata.
- `lib/src/services/app_update_controller.dart` `checkAndMaybeDownload()`
  always called `_download(...)` whenever `isUpdateAvailable()` was true.
- `.github/workflows/release.yml` computed version via
  `git describe --tags --abbrev=0` → increment patch, ignoring pubspec.

## Assumptions & uncertainties
- Cached version tracked in `SharedPreferences` key `cachedUpdateApkVersion`
  (release tag string, verbatim).
- APK file kept at `<externalCacheDir>/DailyInc_update.apk` (single slot).
- Android only for cache; no-op on other platforms.
- No reliable "install succeeded" callback exists. We rely on
  `isUpdateAvailable()` returning false next launch as the success signal.
- The CI `KEY_JKS` secret must remain the same keystore that signed all
  prior releases. If signing keys diverged historically, users who
  installed older CI builds will still hit install failures unrelated to
  this fix.

## Constraints
- Solo-developer project — keep changes minimal and follow existing patterns.
- Non-Android platform behavior unchanged.

## How we'll know it's done
- Cold launch with an update available → APK downloads once.
- Subsequent cold launches (install dismissed) → no network download,
  install prompt re-appears.
- After actual install → cache cleared on next launch.
- Bumping `pubspec.yaml` and pushing to `main` → CI builds and releases with
  that exact version; the tag matches; the installed app upgrades cleanly.
- Pushing pubspec edits that don't change the version → workflow runs but
  logs "No version bump — skipping release" and does nothing.
- Pushing a version that matches an existing tag → workflow logs the tag
  exists and skips.

## What's not included
- No UI change to the "ready to install" snackbar wording.
- No "skip this version" setting.
- No detection of locally-signed vs. CI-signed APKs (out of scope).
- No retroactive fix for users who installed a build signed with a divergent
  keystore — those installs will continue to fail until manually reinstalled.
