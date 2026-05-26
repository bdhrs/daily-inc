# Review — 20260526_themes

## Thread
- **ID:** 20260526_themes
- **Objective:** Add pluggable multi-theme support (Classic, Monk, Sage) with dark/light variants, settings picker, and instant apply.

## Files Changed
- `lib/src/theme/app_palette.dart` — new: AppPalette class + 6 const palette instances
- `lib/src/theme/app_palette_registry.dart` — new: mutable static current palette holder
- `lib/src/theme/theme_controller.dart` — new: ValueNotifier-based ThemeController singleton
- `lib/src/theme/color_palette.dart` — converted from static const fields to runtime getters
- `lib/src/theme/app_theme.dart` — refactored to parameterized `build(AppPalette, Brightness)`
- `lib/main.dart` — wires ThemeController load, syncPalette, ValueListenableBuilder around MaterialApp
- `lib/src/views/settings_view.dart` — adds Color theme section with _ThemePicker + _Dot widgets; fixes const const-value errors; fixes two Row→Wrap overflow bugs
- `lib/src/views/daily_things_view.dart` — removes const from two Text/Row widgets using ColorPalette
- `lib/src/views/widgets/daily_things_helpers.dart` — removes const from TextStyle(color: ColorPalette.X) usages
- `lib/src/views/widgets/next_task_arrow.dart` — removes const from Icon using ColorPalette
- `lib/src/views/widgets/pulse.dart` — makes pulseColor nullable to allow const constructor

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | nit | `settings_view.dart:_ThemePickerState` | `_current` is local state, not a listener on `ThemeController` | If picker were opened while theme changed externally it could show stale selection | Read `ThemeController.instance.value` directly in build — but since picker is the only change site, no practical impact |

## Fixes Applied
- None required (nit only).

## Test Evidence
- `flutter test --no-pub` → 71/71 pass
- `flutter analyze --no-pub` → no issues

## Verdict
PASSED
- Review date: 2026-05-26
- Reviewer: kamma (inline)
