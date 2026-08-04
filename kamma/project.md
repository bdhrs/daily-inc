# Project Guide — Daily Inc

## What It Is and Why
A habit tracker that helps users keep their habits and develop them incrementally over time. The app supports seven activity types — SEQUENCE, MINUTES, STOPWATCH, REPS, CHECK, PERCENTAGE, and TREND — with targets that auto-adjust based on consistency. Sequences chain ordered child items into a single play session with optional auto-advance; auto-start is a per-item setting that a sequence can set for all its children.

## One-Off or Ongoing
Ongoing. The project continuously evolves with new features and improvements.

## What It Will Produce
- Android APK (primary, current focus)
- Linux AppImage (current focus)
- iOS (planned, later)

## How You'll Know It Worked
- All activity types work correctly
- Smart notifications fire only on due days
- Data persists reliably across sessions
- Progression logic increments targets correctly

## First Run
A fresh install — or a store with no data file, which is also the state left by
Reset All Data — is seeded with nine default items covering all seven activity
types, each with an emoji icon. The defaults ship as `assets/default_items.json`
in the store's own format and are copied into place verbatim by
`DataManager.loadData()`. To retune them, build the set in the app and export via
Settings → Save Template, then replace the asset.

## Theming
The app has a pluggable theme system (`lib/src/theme/`). Three themes ship: Classic (blue), Monk (Kimbie warm), Sage (muted green/parchment). Each has dark and light variants. Adding a fourth theme requires only new `AppPalette` constants and a `palettesFor()` case in `ThemeController`. The user picks from Settings; choice persists via shared_preferences key `selected_theme`.

**Guiding principle:** A working app is invisible. Friction is visible.
