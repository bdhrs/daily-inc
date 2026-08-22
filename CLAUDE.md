# Local Rules — Daily Inc

## Flutter / Android
- Always include a `+N` build number in `pubspec.yaml` version strings (e.g. `1.2.3+45`). Without it, Flutter defaults `versionCode` to 1, causing `INSTALL_FAILED_VERSION_DOWNGRADE` on devices with a higher version installed.

## Flutter ReorderableListView
- `ReorderableListView` cannot detect a drag into a zero-height child. Empty group containers need a minimum-height placeholder row (e.g. 48px) to be a valid drop target. Plan for this when designing flat-list grouping UIs.

## Emoji Icons
- Item icons are emoji, which render from a colour font (NotoColorEmoji on Android). Their glyphs carry their own baked-in colours, so setting `color` on a `TextStyle` has **no effect** — it fails silently and `flutter test`/`analyze` stay green. To recolour one, repaint it: wrap in `ColorFiltered` with the `_emojiTint` colour matrix in `daily_thing_item.dart`, which collapses the pixel to luminance (dropping the original hue so every emoji reads as one status colour) and scales by the tint (preserving the glyph's shading). `BlendMode.modulate` keeps the source hue and goes muddy; `BlendMode.srcIn` flattens the glyph to a silhouette.
- `_emojiTint` floors the luminance band at `_tintFloor` rather than letting it run to 0. A plain `luminance × tint` looks fine for one colour but makes two adjacent ones indistinguishable: at luminance 0.2 the undone orange and the partially-done yellow both render as the same near-black brown, and most of an emoji sits in that range. Whenever a status colour is added or retuned, check the tinted output at low luminance, not just at full brightness.

## Timer and Stopwatch Views
- Before making anything fire automatically when a timer/stopwatch view opens, check the already-finished-today path. `TimerStateHelper.initializeTimerState` returns `hasStarted: true` for an item completed earlier today (the `startInOvertime` tap), and `StopwatchView._initializeState` restores `_elapsedSeconds` from today's accumulated value — so an unguarded auto-action resumes a finished item and `_saveProgress` persists the inflated value.
- `StopwatchView._lastTriggeredSubdivision` starts at `-1` while `_elapsedSeconds` may be restored, so the first tick rings a subdivision bell. Account for this whenever the stopwatch can start without a user tap.

## Android Install
- Debug and release are both signed with the release keystore (`android/app/build.gradle.kts`), so `adb install -r` replaces the app in place and keeps `shared_preferences` data. Use `just update`. Never `adb uninstall` or `pm clear` — that wipes all user data.

## Testing
- Run `flutter test --no-pub` before marking any implementation complete. New code can expose pre-existing test failures that must be fixed before review.
- The suite has no widget tests: nothing covers `TimerView`, `StopwatchView`, or the add/edit form. A green `flutter test` says nothing about view behaviour — changes there need a real device run.
