# Local Rules — Daily Inc

## Flutter / Android
- Always include a `+N` build number in `pubspec.yaml` version strings (e.g. `1.2.3+45`). Without it, Flutter defaults `versionCode` to 1, causing `INSTALL_FAILED_VERSION_DOWNGRADE` on devices with a higher version installed.

## Flutter ReorderableListView
- `ReorderableListView` cannot detect a drag into a zero-height child. Empty group containers need a minimum-height placeholder row (e.g. 48px) to be a valid drop target. Plan for this when designing flat-list grouping UIs.

## Testing
- Run `flutter test --no-pub` before marking any implementation complete. New code can expose pre-existing test failures that must be fixed before review.
