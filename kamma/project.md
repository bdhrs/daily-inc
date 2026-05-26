# Project Guide — Daily Inc

## What It Is and Why
A habit tracker that helps users keep their habits and develop them incrementally over time. The app supports seven activity types — SEQUENCE, MINUTES, STOPWATCH, REPS, CHECK, PERCENTAGE, and TREND — with targets that auto-adjust based on consistency. Sequences chain ordered child items into a single play session with optional auto-advance and auto-start.

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

## Theming
The app has a pluggable theme system (`lib/src/theme/`). Three themes ship: Classic (blue), Monk (Kimbie warm), Sage (muted green/parchment). Each has dark and light variants. Adding a fourth theme requires only new `AppPalette` constants and a `palettesFor()` case in `ThemeController`. The user picks from Settings; choice persists via shared_preferences key `selected_theme`.

**Guiding principle:** A working app is invisible. Friction is visible.
