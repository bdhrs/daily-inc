# Spec — Default items for a fresh install

## Overview
A new user, or a user who has just cleared all data, currently lands on an empty
list with no idea what the seven activity types are for. Seed a small, useful
default set — one working example of every ItemType — on first load, shipped as a
JSON asset in the app's own store format and copied into place verbatim.

## Repo context (verified by reading)
- `ItemType` = { minutes, stopwatch, reps, check, percentage, trend, sequence }
  (`lib/src/models/item_type.dart:1`).
- Storage is a single JSON file `daily_inc_data.json` in the app documents dir,
  shaped `{"dailyThings": [...], "meta": {...}}` (`data_manager.dart:111-141`).
- `DataManager._readRawStore()` returns `{}` both when the file is missing AND
  when a read/parse throws (`data_manager.dart:111-131`) — so "empty map" is NOT
  a safe first-run signal. Seeding must check `File.existsSync()` directly, or a
  transient read failure would overwrite real data.
- `resetAllData()` deletes that file (`data_manager.dart:219`). First-run and
  post-reset are therefore the same state: no file. One hook covers both.
- `saveTemplateToFile()` (`data_manager.dart:280`) already exports
  `{dailyThings, savedAt, isTemplate}` with `history` stripped — the same shape
  `_readRawStore` accepts. So the defaults asset can be regenerated from a real
  app state via Save Template, and extra keys like `savedAt` are ignored on read.
- Assets are already wired: `pubspec.yaml:106-108` declares `assets/bells/` and
  `assets/icon/`; `AssetUtils` (`lib/src/core/asset_utils.dart`) already reads
  `rootBundle`.
- **A stale `startDate` is harmless for an untouched item** (verified against
  `calculateTodayValue`): with empty history, `baseTarget = startValue`
  (line 188-189), the item is due, `daysSinceDone` is large, so the penalty
  branch (line 229-233) subtracts — and the start-anchored clamp (line 238-242)
  pins the result back to `startValue`. An item never done behaves as if it
  started today, so **no `startDate` stamping is needed** and the seed can be a
  verbatim file copy. This holds for increasing items (start < end); a
  *decreasing* default would clamp to `endValue` instead. None of the nine
  defaults decrease.
- Reset has two call sites: `settings_view.dart:363` (confirm dialog → calls
  `resetAllData()`, then the `onResetAllData` callback) and
  `daily_things_view.dart:773` (the callback → calls `resetAllData()` a second
  time, then sets `_dailyThings = []`). The second delete is redundant, and its
  try/catch guards calls that already swallow and log their own failures.
  `daily_things_view.dart:1262` is the callback's only wiring.
- `DailyThing.icon` is free-text `String?` rendered before the name
  (`add_edit_daily_item_view.dart:566`) — an emoji is a valid icon, no new field.
- Per `_submitDailyItem` (`add_edit_daily_item_view.dart:700-712`), check,
  percentage, trend, stopwatch and sequence items store startValue 0.0 /
  duration 1 / endValue 0.0. Only minutes and reps carry a real progression.
- `DailyThing.fromJson` requires `name`, `itemType`, `startDate`, `startValue`,
  `duration`, `endValue`; every other field has a default, so the asset can stay
  lean and hand-editable.
- Sequence children are excluded from the top-level list
  (`SequenceHelper.findParentSequence`, used at `daily_things_view.dart:997`), so
  the sequence needs its own children for all seven types to stay visible.
- TREND records ↗️ Improving / → Same / ↘️ Worse (`trend_input_dialog.dart:70-74`).
- Baseline: `flutter test --no-pub` → 76 tests, all passing. No existing test
  touches `DataManager`, so nothing asserts "loadData returns empty".

## What it should do
Ship `assets/default_items.json` holding 9 items (7 types + 2 sequence children).
On `loadData()`, if no store file exists, copy the asset's text straight to the
store path, then read it normally.

| Emoji | Name | Type | Settings | Category |
|-------|------|------|----------|----------|
| 🌅 | Morning Routine | SEQUENCE | autoPlay true, chainDelay 20s, children ↓ | Routine |
| 🤸 | Stretch | MINUTES | 2 → 10 min over 60 days | Routine |
| 🫁 | Breathing | MINUTES | 1 → 5 min over 30 days | Routine |
| 🧘 | Meditation | MINUTES | 5 → 20 min over 60 days | Mind |
| ⏱️ | Journal | STOPWATCH | open-ended timing | Mind |
| 💪 | Push-ups | REPS | 5 → 30 reps over 90 days | Body |
| 💊 | Vitamins | CHECK | daily yes/no | Health |
| 💧 | Water | PERCENTAGE | % of daily water goal | Health |
| 😊 | Mood | TREND | improving / same / worse | Mind |

All: `intervalType` byDays / `intervalValue` 1, no nag time, `notificationEnabled`
false, `autoStart` false, empty history, fixed readable ids so the sequence's
`childIds` resolve and the file stays hand-editable.

Sequence children are 🤸 Stretch and 🫁 Breathing rather than a second "Sit" item,
so the standalone 🧘 Meditation example isn't duplicated on the first screen.

## Assumptions & uncertainties
- Seeding is a write inside a read path (`loadData`). Accepted deliberately: it
  is guarded on file absence, runs at most once, and covers every entry point
  (startup, list view, notification rescheduling) with one hook.
- Fixed ids are safe because they only need to be unique within one store. The
  remote edge case is importing another user's export carrying the same ids.
- A malformed asset (bad hand edit) is caught, logged, and degrades to today's
  behavior — an empty list — rather than crashing startup. The unit test is what
  actually keeps a broken asset from shipping, since nothing else type-checks it.
- The baked `startDate` must be in the past, not the future, or nothing is due.
- Progression numbers are judgement calls, not derived from anything in the repo.

## Rejected alternatives
- **Defaults as a Dart constructor list**: ~60 lines of content data in code,
  needs a recompile to tune, and can drift from the shape `fromJson` expects.
- **Parse the asset and stamp `startDate` to today**: unnecessary — see the
  clamping behavior above — and it turns a 3-line copy into a parse/map/save.
- **`buildDefaultItems()` inside a new loader file**: no longer needed once the
  seed is a byte copy; there is nothing left to build.
- **Seeding in `resetAllData()`**: first run would still need its own hook, and it
  turns a method whose name says "delete" into one that writes.

## Constraints
- No new dependency. Reuse `rootBundle`, the existing store format, `File`.
- Emoji go in the existing `icon` field.
- A read failure must never trigger a write over existing data.
- The asset must stay in the store's own format so `Save Template` can regenerate it.

## How we'll know it's done
- Fresh install (or Settings → Reset All Data) shows the 9 items, with Stretch
  and Breathing nested under Morning Routine, and Meditation's target at 5 min
  regardless of install date.
- `flutter analyze` clean; `flutter test --no-pub` green (76 + new tests).
- The new test parses the shipped asset and asserts: 9 items, each `ItemType`
  once at top level, non-empty icon on every item, resolvable `childIds`, and
  Meditation's `todayValue` at 5.0.

## What's not included
- No settings toggle for "seed defaults".
- No re-seed when the user empties the list manually (the file then exists).
- No onboarding tour, no changes to the add/edit UI.
- No change to `settings_view.dart`.
