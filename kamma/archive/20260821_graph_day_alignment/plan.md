# Plan — Graph day-boundary alignment

## Phase 1: Fix epoch-days conversion
- [x] In `lib/src/views/widgets/graph_style_helpers.dart`, rewrite
      `epochDays` to compute from `DateTime.utc(d.year, d.month, d.day)`
      instead of local-midnight `.millisecondsSinceEpoch`.
- [x] Rewrite `dateFromEpochDays` to walk whole days from
      `DateTime.utc(1970, 1, 1)` and return a local `DateTime` built from the
      resulting UTC date's y/m/d.
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 2: First verification round (user) — found the real bug
- [x] `flutter test --no-pub` — 82 tests, all pass.
- [x] User tested on device with screenshots. Epoch-days fix alone did not
      resolve the visible misalignment — bars still shifted off the
      gridlines. See "Correction" in spec.md: the dominant cause was
      `GraphStyle.stepDirection = 0.76`, not the epoch-days math.

## Phase 3: Fix step direction
- [x] In `lib/src/views/widgets/graph_style_helpers.dart`, change
      `GraphStyle.stepDirection` from `0.76` to `1.0` so each day's step
      riser lands exactly on the boundary gridline to the next day.
- [x] `flutter test --no-pub` — 82 tests, all pass.
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 4: Second verification round (user)
- [x] User re-tested on device (`just update`): confirmed graphs are now
      aligned correctly (alignment symptom resolved).
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 5: Independent review — found stepDirection was the wrong extreme
- [x] Independent agent reviewed the diff against `fl_chart` 1.0.0's actual
      painter source. Found `stepDirection: 1.0` (`stepDirectionBackward`)
      makes each day's cell display the *next* day's value, not its own —
      still gridline-aligned (why the user's spot-check passed) but the
      wrong data per cell. Correct value per source: `0.0`
      (`stepDirectionForward`). CodeRabbit's separate finding on
      `dateFromEpochDays` returning local vs UTC was traced to every call
      site and rejected as a false positive (no site depends on `isUtc`).
- [x] Changed `GraphStyle.stepDirection` from `1.0` to `0.0`.
- [x] `flutter test --no-pub` — 82 tests, all pass.
- [x] User re-tested on device: today's data no longer appeared at all.
      `stepDirection = 0.0` fills the interval to the *right* of a day's
      point, which requires a following point — today has none, so its bar
      is never drawn. This wasn't caught by the source-only review because
      nothing was actually rendered. See "Correction 3" in spec.md.
- [x] Reverted `GraphStyle.stepDirection` to `1.0` (final value) — it fills
      the interval to the *left* of a day's point (bounded by yesterday and
      today), which is always drawable including for the most recent day,
      and still satisfies the original gridline-alignment complaint.
- [x] `flutter test --no-pub` — 82 tests, all pass.
- [x] User re-verified on device once more: today's data visible again,
      bars still aligned to gridlines, Mondays line up. Confirmed correct.
- [x] PHASE COMPLETE: verify all tasks done, no regressions
