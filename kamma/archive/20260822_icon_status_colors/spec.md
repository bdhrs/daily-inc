# Spec: Done/undone color for the item emoji icon

## Problem

Each `DailyThing` list row can show a custom emoji in its "icon" field (set via
the edit-item form). In `lib/src/views/daily_thing_item.dart` this emoji is
rendered as a `Text` widget colored by completion state:

```dart
color: effectiveDone
    ? Theme.of(context).colorScheme.primary
    : Theme.of(context).colorScheme.onSurface,
```

- Done → `colorScheme.primary`, which is `AppPalette.primaryBlue` for the
  active palette.
- Undone → `colorScheme.onSurface` (the theme's default text color) — not a
  status color at all.

`AppPalette.primaryBlue` is only literally blue in the "Classic" palette. In
"Monk" and "Sage" it holds each theme's orange/green accent instead, so
reusing it as "done = blue" would not read as blue in those palettes.

## Requested change

The row has **three** completion states, not two — the status icon beside the
emoji already distinguishes all three, and the emoji must match it:

- Undone emoji → orange (`warningOrange`).
- Partially done emoji → yellow (`partialYellow`), i.e. `_hasIncompleteProgress`
  — a minutes item started but not finished, or a reps item with a value
  entered below target.
- Done emoji → blue (`doneBlue`).
- Preserve "shading": each of the 3 palettes (Classic, Monk, Sage) keeps its
  own dark/light-tuned shade for these two colors, the same way the existing
  `partialYellow`/`warningOrange` status colors already vary per palette,
  rather than one flat color forced across every theme.

## Design

`AppPalette.warningOrange` is already an orange tone in all 6 existing
palette variants (Classic/Monk/Sage × dark/light = 6) — reuse it directly for
"undone", no new field needed.

There is no existing field that is blue in every palette. `AppPalette.primaryBlue`
is not itself reusable as a status color in Monk/Sage since it also drives
theme-wide elements unrelated to done/undone. Add one new field, `doneBlue`,
to `AppPalette` (and thread it through `AppPaletteRegistry` /
`ColorPalette` the same way every other palette color is exposed), with a
value chosen per variant to read clearly as blue against that palette's
background while keeping the dark/light contrast pattern the other status
colors already use (brighter blue on dark backgrounds, deeper blue on light
backgrounds):

| Variant | doneBlue |
|---|---|
| classicDark | `Color.fromARGB(255, 29, 153, 255)` (= existing `primaryBlue`) |
| classicLight | `Color(0xFF1565C0)` (= existing `primaryBlue`) |
| monkDark | `Color(0xFF5DA9E0)` |
| monkLight | `Color(0xFF2E6DA4)` |
| sageDark | `Color(0xFF6FA8DC)` |
| sageLight | `Color(0xFF3A6EA5)` |

### Correction: a `TextStyle` colour cannot tint an emoji

The first implementation set `color:` on the emoji's `TextStyle`. This was
verified on device to have **no effect at all** — emoji render from a colour
font (NotoColorEmoji on Android), whose glyphs carry their own baked-in
colours, so the text fill colour is ignored. Trees stayed green, footprints
stayed blue.

To actually recolour the glyph it must be repainted, not styled. Wrap the
emoji `Text` in a `ColorFiltered` using a 5x4 `ColorFilter.matrix` that:

1. collapses each pixel to its Rec. 709 luminance
   (`0.2126R + 0.7152G + 0.0722B`) — discarding the emoji's original hue is
   what makes every emoji read as the same status colour, and
2. scales that luminance by the tint's RGB, which is what **preserves the
   glyph's internal shading** (the user's stated requirement).

The alpha row stays identity (`0,0,0,1,0`) so transparent pixels around the
glyph remain transparent rather than filling a coloured rectangle.

### Correction: luminance must not run to zero

The first working version multiplied luminance straight into the tint. That
renders correctly for a single colour but destroys the distinction between two
adjacent ones: at luminance 0.2 the undone orange became `(39,24,0)` and the
partially-done yellow `(51,39,1)` — both effectively black. Most of an emoji
sits in that range, so a half-finished item looked identical to an untouched
one on device even though the correct tint was being passed in.

Luminance therefore drives a `_tintFloor`..1 band (floor 0.55) instead of 0..1:

```
channel = 255 * tintChannel * (_tintFloor + (1 - _tintFloor) * luminance)
```

expressed in the matrix as a scaled coefficient row plus a constant in the
translation column, which `ColorFilter.matrix` takes in 0-255 space. Shading
survives in the remaining 45% of the range; no pixel can fall dark enough to
lose its hue. Full-brightness pixels are unchanged.

`BlendMode.modulate` was rejected: it multiplies rather than replacing hue, so
a green tree under an orange tint goes muddy brown and a blue footprint goes
near-black — the emoji would not read as one consistent status colour.
`BlendMode.srcIn` was rejected: it flattens the glyph to a solid silhouette,
destroying the shading.

## Scope

Only the emoji rendering at `daily_thing_item.dart` (the `widget.item.icon`
block) changes — from a styled `Text` to a `ColorFiltered`-wrapped `Text`, with
the tint chosen by the same `effectiveDone` / `_hasIncompleteProgress` pair the
sibling status icon already branches on, so the two always agree.

A snoozed row still takes the orange "undone" tint. Its status icon renders
`Icons.snooze` in `white70` instead, so the two disagree in that one state —
raised with the user during review and accepted as-is, since a snoozed item is
literally not done.

Everything else that currently uses `colorScheme.primary`/`colorScheme.error`
for done/undone status (the check/close icon, the item name text, the
trailing action chip, the sequence chip) is explicitly out of scope — the
user confirmed this request is about the emoji icon field only.

## Affected files

- `lib/src/theme/app_palette.dart` — add `doneBlue` field + 6 variant values.
- `lib/src/theme/app_palette_registry.dart` — no change; confirmed on read to
  be a plain passthrough to the current `AppPalette`.
- `lib/src/theme/color_palette.dart` — add `ColorPalette.doneBlue` getter.
- `lib/src/views/daily_thing_item.dart` — add the `_emojiTint` colour-matrix
  helper and wrap the emoji `Text` in `ColorFiltered`.
