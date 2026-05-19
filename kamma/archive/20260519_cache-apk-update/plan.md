# Plan — Fix the in-app update loop

## Architecture Decisions
- **Single-slot APK cache.** Reuse the existing fixed path
  `<externalCacheDir>/DailyInc_update.apk`. No history of older APKs.
- **Cached version tracked in SharedPreferences** under `cachedUpdateApkVersion`
  (the GitHub `tag_name`, verbatim).
- **Cache invalidation = mismatch.** If the cached version != latest tag, the
  cached file is deleted before download. If the cached version matches and
  the file exists, short-circuit to `readyToInstall`.
- **No install-success callback.** Treat absence of `isUpdateAvailable()` as
  proof the install succeeded, and clear the cache then.
- **pubspec.yaml as the single source of release truth.** CI reads it; manual
  `workflow_dispatch` removed. Version-bump-on-push is the release signal.
- **Build number from `github.run_number`.** Preserved from the previous
  workflow — guarantees CI builds have monotonically-increasing versionCodes.

## Phase 1 — APK cache (controller + service)

- [x] In `app_update_controller.dart`, after `isUpdateAvailable()` returns true
      and before `_download(...)`, read `cachedUpdateApkVersion`. If it equals
      `latestTag` and the file at the known cache path exists, transition
      state directly to `readyToInstall` with `apkPath` set, skipping
      `_download`.
      → verify: logs show no "Downloading APK" on second launch.

- [x] If `cachedUpdateApkVersion` does not equal `latestTag`, delete the stale
      cached APK (if present) and clear the pref before downloading.
      → verify: set pref to a fake old tag; confirm a fresh download starts.

- [x] After a successful `downloadUpdate(...)`, persist
      `cachedUpdateApkVersion = latestTag`.
      → verify: log the stored tag on next launch and confirm it matches.

- [x] When `isUpdateAvailable()` returns false in `checkAndMaybeDownload`,
      clear `cachedUpdateApkVersion` and best-effort delete the cached APK.
      → verify: install the update; relaunch; confirm cache file is gone.

- [x] Add `Future<File> getCachedApkFile()` to `UpdateService` so the cache
      path lives in one place. Used by both `downloadUpdate` and the
      controller's cache lookup.
      → verify: `rg "DailyInc_update.apk" lib/` returns one literal.

- [x] Phase verification: `flutter test --no-pub` passes; `flutter analyze`
      reports no new warnings in touched files.

## Phase 2 — Release workflow (pubspec as source of truth)

- [x] Replace the `Calculate Version` step in `.github/workflows/release.yml`
      with one that reads `version:` from `pubspec.yaml` (strip the `+N`
      build suffix).
      → verify: `grep -A 2 "Determine Version" .github/workflows/release.yml`
        shows pubspec extraction.

- [x] Change the workflow trigger to `push` on `branches: [main]` filtered to
      `paths: ['pubspec.yaml']`. Remove `workflow_dispatch` per user
      preference (release should be fully automatic on version bump).
      → verify: `grep -A 4 "^on:" .github/workflows/release.yml` shows only
        the push trigger.

- [x] In the prepare step, set `SHOULD_RELEASE=true` only if the new pubspec
      version is strictly higher than the previous commit's pubspec version
      (using `sort -V`), AND no `v<version>` tag exists yet. Otherwise
      `SHOULD_RELEASE=false` with a clear log message.
      → verify: re-read the workflow; confirm both guards are present.

- [x] Gate `test`, `build-android`, `build-linux`, and `publish-release`
      jobs on `if: needs.prepare.outputs.SHOULD_RELEASE == 'true'`.
      → verify: `grep "SHOULD_RELEASE" .github/workflows/release.yml`
        shows the `if:` on all four jobs.

- [x] Keep `--build-number=${{ github.run_number }}` on the Flutter build
      commands so CI builds always have monotonically-increasing
      versionCodes.
      → verify: `grep build-number .github/workflows/release.yml` confirms.

- [x] Phase verification: workflow file YAML is syntactically valid; jobs
      reference the correct outputs.
