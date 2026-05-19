## Thread
- **ID:** 20260519_cache-apk-update
- **Objective:** Fix the in-app update loop — cache APK between launches and
  make `pubspec.yaml` the single source of truth for releases.

## Files Changed
- `lib/src/services/update_service.dart` — extracted `getCachedApkFile()` so
  the cached APK path lives in one place; `downloadUpdate` now reuses it.
- `lib/src/services/app_update_controller.dart` — cache-aware update flow:
  reuses an existing APK that matches the latest tag, deletes stale APKs
  before re-downloading, persists the downloaded version, and clears the
  cache when no update is available.
- `.github/workflows/release.yml` — trigger is now push-on-main filtered by
  `pubspec.yaml`; version is read from pubspec; release runs only when the
  version is strictly higher than the previous commit's and the `v<version>`
  tag does not already exist; `workflow_dispatch` removed.

## Findings
No findings. Reviewed across correctness, readability, architecture, security,
and performance:
- Cache lookup happens after the install-permission check, so we don't trigger
  the system prompt for a phantom update; controller transitions match the
  existing `idle → checking → readyToInstall` state diagram.
- `_clearCachedApk` is best-effort and swallows errors via try/catch — correct
  behavior since cache cleanup must never break the update flow.
- Workflow `SHOULD_RELEASE` is gated on all four downstream jobs; YAML
  parses; `--build-number=${{ github.run_number }}` is preserved on both
  Android and Linux builds.
- Only one literal `'DailyInc_update.apk'` remains in `lib/`.

## Fixes Applied
None — review found no blocking or major issues.

## Test Evidence
- `flutter analyze lib/src/services/app_update_controller.dart lib/src/services/update_service.dart` → no issues
- `flutter test --no-pub` → all 71 tests pass
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))"` → valid
- `grep -c "SHOULD_RELEASE == 'true'" .github/workflows/release.yml` → 4 (test, build-android, build-linux, publish-release)

## Verdict
PASSED
- Review date: 2026-05-19
- Reviewer: kamma (inline)
