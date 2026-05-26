# Spec — Multi-Theme Support

## Overview
Add a pluggable color-scheme system to Daily Inc. The current single theme becomes one of multiple selectable themes, each with full light and dark variants. The user picks the active theme from Settings; choice is persisted and applies instantly across every screen.

## Repo context (as of writing)
- Theme is centralized in two files: `lib/src/theme/color_palette.dart` (static const Colors) and `lib/src/theme/app_theme.dart` (single `darkTheme` getter using those colors).
- `lib/main.dart` configures `MaterialApp` with `theme: ThemeData.light()` (unstyled default), `darkTheme: AppTheme.darkTheme`, `themeMode: ThemeMode.system`.
- 16 view/widget files reference `ColorPalette.*` directly (114 references total). **No `const` expressions outside `lib/src/theme/` use ColorPalette**, so the palette members can safely become runtime getters without breaking call sites.
- State management is GetX; persistence is shared_preferences. Both already in `pubspec.yaml`.
- Some graph files and a few state-encoding spots use raw `Colors.red/Colors.amber/Colors.blueGrey` etc. — these are deliberately fixed (error red, snooze blueGrey, partial-completion amber) and stay as-is.

## What it should do
1. Ship three themes: **nīla** (current blue, default), **kasāya** (Kimbie-style warm monk colors — orange/amber on warm browns), **haritā** (muted sage/parchment).
2. Each theme exposes a dark and a light variant; `MaterialApp.themeMode` continues to honor system mode, so the OS still drives dark/light selection within the chosen theme.
3. A new Settings entry lets the user pick the active theme. Selection persists across launches via shared_preferences.
4. Switching theme rebuilds the whole app immediately — every view (timer, history, settings, graphs, dialogs) reflects the new theme without restart.
5. Adding a fourth theme later requires only: define one ColorScheme pair, register it in the theme registry. No call-site changes.

## Assumptions & uncertainties
- **Assumption:** Existing inline `Colors.red/amber/blueGrey/grey` usages are intentional state indicators (error, partial, snoozed, neutral) and should NOT be themed. Confirmed by reading their contexts. If the user wants them theme-aware later, that's a separate thread.
- **Assumption:** Graph colors (`Colors.white`, `Colors.yellow`, grid greys in `graph_mixin.dart`, `graph_style_helpers.dart`) stay hardcoded for now — they're tuned for chart legibility. Will route the obvious text/background ones through theme; chart line/grid colors stay fixed.
- **Assumption:** Kimbie reference is the Wes Bos / Kimbie Dark VSCode theme palette (warm browns ~#221A0F, oranges ~#F79A32, yellows ~#F06431, muted greens). User confirmed via "monk colours" — that aligns.
- **Assumption:** Light variants are derived in spirit from each theme's identity (kasāya light = warm cream + deeper amber; haritā light = parchment + sage); not strict inversions.
- **Uncertainty:** The current dark theme uses Inter via `google_fonts`. Assuming all themes share the same typography — only colors change. Flag if not.

## Constraints
- Don't break any existing call site. `ColorPalette.X` must keep working (becomes a getter that reads the active palette).
- Don't introduce a new state-management library — use GetX (already a dep).
- No backend or migration concerns — purely local.
- Keep the diff focused: this thread is theming infrastructure + three themes + settings UI. No drive-by refactors of unrelated UI.

## How we'll know it's done
- App launches on default theme (nīla) for first-time users.
- Settings has a "Color theme" section listing nīla / kasāya / haritā; selecting one immediately changes every visible surface.
- Backgrounding/foregrounding the app preserves the choice.
- System dark/light toggle still flips between the active theme's dark and light variants.
- `flutter test --no-pub` passes.
- Visual smoke test: open Daily Things, Settings, Add/Edit, Timer, History, Graph in each theme × dark/light = looks coherent.

## What's not included
- A separate "follow system theme" override per theme (system mode already controls dark/light).
- Custom user-defined themes / theme editor.
- Theming the existing intentional state colors (red error, amber partial, blueGrey snooze).
- Theming graph chart internals beyond text/background.
- A floating quick-cycle button in the app bar (user chose "Settings only").
