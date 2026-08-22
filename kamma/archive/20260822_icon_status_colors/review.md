## Thread
- **ID:** 20260822_icon_status_colors
- **Objective:** Render the per-item emoji icon orange when undone, yellow when partially done, and blue when done, preserving the glyph's shading.

## Files Changed
- `lib/src/theme/app_palette.dart` — new `doneBlue` field plus a per-variant value on all six palette consts
- `lib/src/theme/color_palette.dart` — `doneBlue` getter forwarding to the active palette
- `lib/src/views/daily_thing_item.dart` — `_emojiTint` luminance-preserving colour matrix with a `_tintFloor`; emoji `Text` wrapped in `ColorFiltered`, tinted across three completion states

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | minor | `lib/src/views/daily_thing_item.dart:280` | A snoozed item's emoji gets the orange "undone" tint, while its status icon renders `Icons.snooze` in `white70` because snoozed means "not due" rather than "not done" | The emoji and the status icon in the same row now express different things | Add a snoozed branch to the tint selection, or leave snoozed emoji untinted |
| 2 | nit | `lib/src/views/daily_thing_item.dart:280` | Partial-progress rows show `partialYellow` on the status icon but plain orange on the emoji | Two nearby amber tones carrying different meanings | **Fixed** — the emoji now takes `partialYellow` on the same `_hasIncompleteProgress` condition |
| 4 | major | `lib/src/views/daily_thing_item.dart:21` | `_emojiTint` multiplied luminance straight into the tint, driving mid-tone pixels toward black | Adjacent status hues stopped being tellable apart — undone orange and partial yellow both rendered as the same brown, so the feature looked broken on device | **Fixed** — luminance now drives a `_tintFloor`(0.55)..1 band |
| 3 | nit | `lib/src/theme/app_palette.dart:46,61` | Classic variants duplicate the literal value of `primaryBlue` instead of referencing it | The two values can silently drift apart | Acceptable as data — they are deliberately independent knobs now |

Finding 1 was reviewed and **accepted as-is**: the request was literally "undone = orange, done = blue", and a snoozed item is not done. Raised with the user rather than changed unilaterally, since it is a product-behaviour call and not a code defect.

## Fixes Applied
**Finding 4 — the tint crushed adjacent hues together.** Device testing showed a
half-finished item still reading orange. The partial-state detection was never at
fault: the chip rendered `partialYellow` correctly and the emoji was already
receiving it. The defect was in `_emojiTint` itself — a plain `luminance × tint`
drives every mid-tone pixel toward black, and at luminance 0.2 undone orange
became `(39,24,0)` while partial yellow became `(51,39,1)`: two indistinguishable
browns. Luminance now drives a `_tintFloor`(0.55)..1 band, so the darkest pixel
still shows 55% of the tint. The same pair now renders `(125,76,0)` and
`(163,124,4)`. Full-brightness pixels are unchanged. Confirmed on device.

This is the risk the independent review had already flagged under "Not Verified"
— that shading preservation maps low-luminance regions near black. It was filed
as a residual risk rather than acted on, and it was the actual bug.

Finding 2 fixed after the user pointed out the row has three completion states,
not two: the emoji now takes `partialYellow` when `_hasIncompleteProgress` is
true, branching on exactly the condition the sibling status icon already used.
Finding 1 remains accepted as-is with the rationale above.

Earlier in the thread a genuine defect was found and fixed before review: the first implementation set `color` on the emoji's `TextStyle`, which emoji colour fonts ignore entirely, so it had no visible effect. Replaced with the `ColorFiltered` approach.

## Test Evidence
- `flutter test --no-pub` (scope: whole project, 87 tests — none of which exercise this view; the suite has no widget tests for `DailyThingItem`) → pass
- `flutter analyze` (scope: the three changed files) → clean, no unused-element warnings
- `coderabbit review --agent --base main --type uncommitted` (scope: 5 files, including 2 dirty from unrelated parallel work) → 0 findings
- Independent zero-context agent review (scope: the three changed files; verified matrix row/column layout and the identity alpha row against the engine's `ColorFilter.matrix` contract, the 0..1 range of `Color.r/.g/.b`, `doneBlue` presence on all six consts, and `ColorFiltered` layout/compositing behaviour) → 1 minor, 2 nits
- Manual device run by the user → emoji confirmed rendering orange when undone and blue when done
- Arithmetic check of `_emojiTint` output across luminance 0.2–1.0 for all three status colours (scope: computed RGB only, not rendered) → confirmed the old matrix collapsed orange and yellow into near-identical browns below ~0.4 luminance, and the floored matrix separates them at every level
- Manual device run by the user after the floor fix → half-finished minutes item confirmed rendering yellow, distinct from undone orange

## Not Verified
- `_tintFloor` is set to 0.55 by eye against one device and one palette. It trades
  shading range for hue separation; no sweep established that it is the right
  value for the other five palette variants.
- `_hasIncompleteProgress` returns `false` for stopwatch, percentage and trend
  items, so those types can never show the partial state anywhere — emoji, status
  icon or chip. Pre-existing, outside this thread, reported to the user and left
  unchanged.
- No automated coverage of the rendered result — the project has no widget tests for this view, so every green check above is indifferent to whether the emoji is tinted at all. The device run is the only evidence the feature works.
- Legibility of dark-heavy emoji on the dark palettes is much improved by the floor (nothing drops below 55% of the tint) but still only spot-confirmed on one device, not swept across all six palette variants.
- Multi-codepoint emoji (ZWJ sequences, skin-tone modifiers) not specifically exercised.
- Monk and Sage palettes not visually checked at all; only the active palette on the user's device was seen.

## Verdict
PASSED
- Review date: 2026-08-22
- Reviewer: independent subagent (zero-context) + CodeRabbit CLI, collated by the implementing session
