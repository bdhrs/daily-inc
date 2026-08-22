# Plan: Done/undone color for the item emoji icon

## Phase 1: Implement
- [x] Add `doneBlue` field to `AppPalette` (constructor + all 6 variant consts — Classic/Monk/Sage × dark/light) per spec table
- [x] Add `ColorPalette.doneBlue` getter forwarding to `AppPaletteRegistry.current.doneBlue`
- [x] Update the emoji `Text` color in `daily_thing_item.dart` to `ColorPalette.doneBlue` (done) / `ColorPalette.warningOrange` (undone)
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 2: Verify
- [x] Run `flutter test --no-pub` — all tests passed
- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced

## Phase 3: Fix — TextStyle colour does not tint emoji
Device check showed no visible change: emoji come from a colour font, so the
`TextStyle` colour is ignored. See the "Correction" section in spec.md.

- [x] Add `_emojiTint` luminance-preserving colour-matrix helper in `daily_thing_item.dart`
- [x] Wrap the emoji `Text` in `ColorFiltered` using that helper instead of styling its colour
- [x] `flutter analyze` clean on the edited file
- [x] Run `flutter test --no-pub` — 87 tests passed
- [x] PHASE COMPLETE: user confirmed on device that emoji now render orange/blue

## Phase 4: Third state — partially done
The row has three completion states, not two. The status icon already shows
`partialYellow` for `_hasIncompleteProgress`; the emoji did not.

- [x] Tint the emoji `partialYellow` when `_hasIncompleteProgress(item)` is true
- [x] `flutter analyze` clean on the edited file
- [x] Run `flutter test --no-pub` — 87 tests passed
- [ ] PHASE COMPLETE: pending device confirmation that partial items show yellow
- [x] PHASE COMPLETE: user confirmed on device that partial items show yellow

## Phase 5: Fix — tint crushed orange and yellow together
Device test showed a half-done item still reading orange. Detection was correct
(the chip was yellow); `_emojiTint` was collapsing both hues into brown.

- [x] Floor the luminance band at `_tintFloor` = 0.55 so no pixel falls below 55% of the tint
- [x] Verify the output RGB separates all three status colours across luminance 0.2-1.0
- [x] `flutter analyze` clean on the edited file
- [x] Run `flutter test --no-pub` — 87 tests passed
- [x] PHASE COMPLETE: user confirmed on device that yellow now reads distinctly from orange
