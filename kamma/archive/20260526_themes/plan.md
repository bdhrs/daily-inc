# Plan — Multi-Theme Support

## Architecture Decisions

1. **Palette becomes runtime, not const.** Convert `ColorPalette` members from `static const` fields to `static` getters that read from a current `AppPalette` instance held by a controller. Verified no external `const` expression depends on these, so the change is safe. This keeps all 114 existing call sites working unchanged.

2. **One `AppPalette` class, one instance per theme×mode.** A plain Dart class with the same semantic tokens as today (`primaryBlue`, `darkBackground`, `cardBackground`, `inputBackground`, `lightText`, `secondaryText`, `warningOrange`, `partialYellow`, `onPartialYellow`, `scrollbarThumb`, plus `blackText`). Names are preserved even when the literal color isn't blue/dark — they're semantic slots ("primary accent", "page background", etc.). Renaming would mean touching all 16 view files for no functional benefit; deferred.

3. **`ThemeController` via GetX.** A GetX controller exposes the current `ThemeKey` (enum: `nila`, `kasaya`, `harita`) and rebuilds the app via `Obx`/`GetMaterialApp`-equivalent. Since the rest of the app uses `MaterialApp` (not `GetMaterialApp`), the cleanest minimal change is: wrap `MaterialApp` in an `AnimatedBuilder`/`ListenableBuilder` over a `ValueNotifier<ThemeKey>` — no GetX import needed in `main.dart`. Keeps scope tight.

4. **Persistence key:** `selected_theme` in shared_preferences, value is the enum name. Default `nila`.

5. **Light variants are real, full themes** (not `ThemeData.light()`). Built via the same builder function as dark, parameterized on the palette.

6. **No global theme-cycle button in the app bar** — user chose "Settings only" placement.

## Phase 1 — Palette runtime infrastructure

- [ ] Convert `ColorPalette` to runtime getters backed by a static `AppPalette` field
  - Sub-tasks:
    - [ ] Create `lib/src/theme/app_palette.dart` defining `class AppPalette` with all current ColorPalette fields as final instance fields + a `const AppPalette({...})` constructor.
    - [ ] Edit `lib/src/theme/color_palette.dart`: replace static const fields with static getters that return `AppPaletteRegistry.current.X`. Keep the public API (names) identical.
    - [ ] Create `lib/src/theme/app_palette_registry.dart`: holds a mutable static `AppPalette current` (defaults to nīla-dark for safe startup) and a `set(AppPalette)` method.
    - [ ] Drop the `const` keyword on the 8 lines in `lib/src/theme/app_theme.dart` (104, 106, 107, 113, 150, 157, 160, 161) that prefix `Color: ColorPalette.X` constants — these stop being compile-time constants.
  - → verify: `flutter analyze --no-pub` passes with no new errors.

- [ ] Define the three palettes (nīla, kasāya, haritā) × dark/light
  - Sub-tasks:
    - [ ] In `app_palette.dart`, add six static `AppPalette` constants: `nilaDark`, `nilaLight`, `kasayaDark`, `kasayaLight`, `haritaDark`, `haritaLight`. `nilaDark` reuses the current literal color values.
    - [ ] kasāya dark: warm dark brown background (~#221A0F), card (~#2F2418), input (~#3A2C1B), primary accent Kimbie orange (~#F79A32), text light-cream (~#F8E5C0), secondary muted tan (~#B59F7E), warning orange existing, scrollbar (~#5B4A30).
    - [ ] kasāya light: cream background (~#FBF4E4), card (~#F2E7CC), input (~#E8DAB8), primary deep amber (~#B96C18), text dark coffee (~#2D2114), secondary (~#7A6748).
    - [ ] haritā dark: muted slate-green background (~#1A1F1B), card (~#242A26), input (~#2E3631), primary sage (~#8AA88A), text parchment (~#E6E2D3), secondary (~#94A099).
    - [ ] haritā light: parchment background (~#F2EFE3), card (~#E7E2D0), input (~#DCD7C2), primary forest-sage (~#4F7A55), text dark olive (~#28301E), secondary (~#6B7264).
  - → verify: open `app_palette.dart`, all 6 palettes compile; `flutter analyze --no-pub` clean.

## Phase 2 — Theme builder + controller

- [ ] Parameterize `AppTheme` to build from any `AppPalette`
  - Sub-tasks:
    - [ ] Refactor `lib/src/theme/app_theme.dart`: extract the current body of `darkTheme` into `static ThemeData build(AppPalette p, {required Brightness brightness})`. Replace every `ColorPalette.X` reference with `p.X`. Set `colorScheme: ColorScheme.fromSeed(seedColor: p.primaryBlue, brightness: brightness).copyWith(...)` so Material widgets we don't explicitly style still pick up the palette.
    - [ ] Keep a `darkTheme` getter for backward-compat that returns `build(AppPalette.nilaDark, brightness: Brightness.dark)` — used only as a safety fallback.
  - → verify: `flutter analyze --no-pub` clean.

- [ ] Add `ThemeController` (ValueNotifier-based, no GetX needed here)
  - Sub-tasks:
    - [ ] Create `lib/src/theme/theme_controller.dart`: `enum ThemeKey { nila, kasaya, harita }`. `class ThemeController extends ValueNotifier<ThemeKey>` with `Future<void> load()` (reads shared_preferences), `Future<void> set(ThemeKey)` (persists + notifies + updates `AppPaletteRegistry`), and `(AppPalette dark, AppPalette light) palettesFor(ThemeKey)`.
    - [ ] Singleton instance `ThemeController.instance` for global access (matches the existing `NotificationService()`/`DataManager()` pattern in main.dart).
    - [ ] When the controller's value changes, update `AppPaletteRegistry.current` to the dark variant of the new theme (mode-aware update happens in the MaterialApp builder — see next task).
  - → verify: `flutter analyze --no-pub` clean.

- [ ] Wire MaterialApp to ThemeController
  - Sub-tasks:
    - [ ] In `lib/main.dart`, await `ThemeController.instance.load()` before `runApp`.
    - [ ] Wrap the existing `MaterialApp` in a `ValueListenableBuilder<ThemeKey>` listening to `ThemeController.instance`.
    - [ ] Inside the builder, compute `(darkPalette, lightPalette)` from the active key, set `AppPaletteRegistry.current` to whichever matches the platform's current brightness (read via `MediaQuery.platformBrightnessOf` in a `Builder` *inside* `MaterialApp` so we get the right context), and pass both themes to `MaterialApp(theme: AppTheme.build(lightPalette, brightness: Brightness.light), darkTheme: AppTheme.build(darkPalette, brightness: Brightness.dark), themeMode: ThemeMode.system)`.
  - → verify: build runs; manually launching the app on a fresh install shows the current (nīla) appearance unchanged.

- [ ] Phase 2 verification: `flutter test --no-pub` passes.

## Phase 3 — Settings UI for theme picker

- [ ] Add "Color theme" section to Settings
  - Sub-tasks:
    - [ ] In `lib/src/views/settings_view.dart`, add a new section labeled "Color theme" near the existing appearance/brightness-adjacent settings.
    - [ ] Render three options as a `RadioListTile<ThemeKey>` group OR as three large tappable swatches (preferred — easier to compare at a glance). Each swatch shows: theme name (`nīla` / `kasāya` / `haritā`), a small preview row of three filled circles using that theme's primary + surface + secondary colors, and a check mark when active.
    - [ ] Tapping a swatch calls `ThemeController.instance.set(key)` and the app rebuilds.
  - → verify: open Settings, tap each of the three swatches; whole app re-skins instantly each time; selection persists after app restart.

## Phase 4 — Final verification

- [ ] Visual smoke test across views
  - Sub-tasks:
    - [ ] Daily Things list, Add/Edit dialog, Timer view, History view, Graph view, Settings — for each of {nīla, kasāya, haritā} × {dark, light} = 18 combinations, no jarring contrast failures or hardcoded-color bleed.
  - → verify: spot-check (user will do the actual eyeballing in STOP 2).

- [ ] Run full test suite
  - → verify: `flutter test --no-pub` passes.

- [ ] Run static analysis
  - → verify: `flutter analyze --no-pub` clean (no new warnings/errors).
