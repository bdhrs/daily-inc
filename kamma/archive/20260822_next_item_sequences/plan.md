# Plan — Next-undone highlight includes sequences

## Phase 1: Make the index computation sequence-aware

- [x] Add the `SequenceHelper` and `ItemType` imports to
  `lib/src/views/widgets/daily_things_helpers.dart` if not already present.
  → verify: `flutter analyze lib/src/views/widgets/daily_things_helpers.dart`
- [x] Change `getNextUndoneIndex` to take a second `allItems` parameter and
  branch on `ItemType.sequence` to `SequenceHelper.sequenceIsUndoneToday`.
  → verify: file compiles; no other logic added
- [x] Update the only caller, `DailyThingsView._getNextUndoneIndex`
  (`lib/src/views/daily_things_view.dart:928`), to pass `_dailyThings` as
  `allItems`.
  → verify: `flutter analyze` reports no errors
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 2: Cover it with a test

- [x] Add a unit test for `getNextUndoneIndex` covering the four acceptance
  cases in spec.md: undone sequence pulses, completed sequence is skipped,
  a non-sequence item above the sequence wins, and empty list returns -1.
  → verify: `flutter test --no-pub` green
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 3: Handoff

- [x] Run the full suite: `flutter test --no-pub` and `flutter analyze`.
  → verify: both clean, any failure that predates this thread noted as
  pre-existing rather than fixed here
- [x] Ask the user to run on device and confirm a sequence card pulses when it
  is the next undone item (no widget tests cover `DailyThingsView`).
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
