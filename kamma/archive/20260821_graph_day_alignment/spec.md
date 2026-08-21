# Spec — Graph day-boundary alignment

## Problem reported

- Individual item graphs (`GraphView`) and group/category graphs
  (`CategoryGraphView`) look "off, half days" — data points don't line up
  with the day gridlines.
- Monday gridlines/labels are "not clear" — they don't line up with the
  Monday they're supposed to mark.

## Root cause (verified by reading)

`GraphStyleHelpers.epochDays` / `dateFromEpochDays`
(`lib/src/views/widgets/graph_style_helpers.dart:25-33`) convert a calendar
date to an "epoch days" double using **local wall-clock midnight run through
UTC-based `millisecondsSinceEpoch`**:

```dart
static double epochDays(DateTime d) {
  final day = DateTime(d.year, d.month, d.day); // local midnight
  return day.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
}
```

`DateTime(...).millisecondsSinceEpoch` is always UTC-epoch-based. Local
midnight is only a whole multiple of 86,400,000 ms when the device's UTC
offset is exactly 0. For any other offset, every date's `epochDays` value is
shifted by `offset_hours / 24` — a fixed fractional day (e.g. an offset of
+12h/-12h — common in Australia/NZ/Pacific timezones — produces exactly a
half-day shift, matching the "half days" description; this repo's dev
machine is UTC+2, which shifts by ≈0.083 day).

This fractional shift only affects **where data spots are plotted** — but
the chart's gridlines are computed independently, snapped to whole-number x
positions (`minX.floorToDouble()` + `verticalInterval: 1`). Whole-number x
positions round-trip through `dateFromEpochDays` back to local midnight
exactly (the shift cancels out when going epoch-days → ms → local date), so
gridlines *do* land on real calendar-day boundaries and Mondays are
correctly identified — but the data spots themselves sit at a fractional
offset from those gridlines, so every point appears shifted away from the
day/Monday line that actually represents it.

Confirmed call sites using these two functions:
- `graph_view.dart` (`_buildSpots`, `_buildSequenceSpots`, `_buildTrendSpots`,
  chart `minX`/`maxX`)
- `category_graph_view.dart` (`_buildCategorySpots`, chart `minX`/`maxX`,
  tooltip date lookup)
- `graph_mixin.dart` (`buildAxisTitles`, `buildGridData`,
  `buildTouchTooltipData` — all consume `dateFromEpochDays`, not the buggy
  direction, so they are correct already and need no change)

`GraphStyleHelpers.getTitlesData` / `getGridData` in the same file duplicate
similar logic but are dead code (no call sites) — out of scope.

`mini_graph_widget.dart` computes its own epoch-days inline with a different
(also wrong: divides by minutes-per-day, not seconds-per-day) formula. It's
an unlabeled sparkline with no gridlines/axis, so the reported symptom
(misalignment against day/Monday gridlines) doesn't apply there — out of
scope.

## Fix

Make `epochDays`/`dateFromEpochDays` timezone-independent by anchoring to
UTC calendar dates instead of routing local midnight through a UTC-epoch
millisecond count:

```dart
static double epochDays(DateTime d) {
  return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch /
      (24 * 60 * 60 * 1000);
}

static DateTime dateFromEpochDays(double v) {
  final utc = DateTime.utc(1970, 1, 1).add(Duration(days: v.round()));
  return DateTime(utc.year, utc.month, utc.day);
}
```

`DateTime.utc(y, m, d)` for a whole calendar date always has zero
sub-day remainder against the UTC epoch, so `epochDays` always returns a
whole number and every data spot lands exactly on its gridline, regardless
of device timezone. `dateFromEpochDays` returns a local `DateTime` (matching
its current contract — callers compare it against local calendar dates and
check `.weekday`), just built by walking whole days from the UTC epoch
instead of interpreting the ms count as local.

No other call site changes needed — every consumer already treats
`epochDays`/`dateFromEpochDays` as an opaque round-trippable pair.

## Out of scope

- `GraphStyleHelpers.getTitlesData`/`getGridData` (dead code).
- `mini_graph_widget.dart`'s separate epoch-days formula (no gridlines to
  misalign against).
- Visual styling of the Monday gridline/label (currently `grey.shade500`
  vs `grey.shade700`, `strokeWidth: 1.5` vs `1`) — the "not clear" complaint
  is explained by the misalignment above, not by insufficient contrast. If
  Mondays are still hard to spot once alignment is fixed, that's a follow-up.

## Assumptions

- The "half days" and "Mondays not clear" complaints are the same root
  cause (spot/gridline misalignment), not two separate bugs. Confidence
  based on the math above matching both symptoms exactly.

## Confidence

8/10 — root cause is confirmed by reading the epoch-days math, and the fix
is minimal and mechanical. Residual uncertainty is only whether the user
still finds Monday contrast insufficient after the alignment fix (out of
scope above, flagged as a possible follow-up).

## Correction (2026-08-21, after first round of user testing)

The epoch-days fix above was real (and worth keeping — it removes a
timezone-dependent bug that would bite on any non-UTC device) but it was
**not** the dominant cause of the reported "off, half days" / unclear-Monday
symptom. Screenshots from the device showed bars whose vertical risers land
visibly inside a day cell, not on the gridline — the epoch-days fix alone
does not explain that, since gridlines and data spots were already
proven to round-trip to the same integer x once that fix landed.

**Actual dominant cause:** `GraphStyle.stepDirection = 0.76`
(`graph_style_helpers.dart:9`), used by every `isStepLineChart: true` in
`GraphView` and `CategoryGraphView`. `fl_chart`'s
`LineChartStepData.stepDirection` controls where between two consecutive
data points (day *D* and day *D+1*) the vertical riser is drawn: `0` = right
after *D*, `1` = right before *D+1*. At `0.76`, the riser lands 76% of the
way through day *D*'s interval — i.e. visibly inside the day-*D* cell,
24% before the day-*D+1* gridline — instead of exactly on the boundary
between the two days. That is what produces bars that look shifted away
from the gridlines, and Monday gridlines that don't line up with where a
bar actually starts/ends.

**Fix:** `stepDirection: 1.0` — the step holds day *D*'s value flat all the
way to the day-*D+1* gridline, then jumps exactly on it, so every rectangle
spans exactly one calendar day between two gridlines. This makes the
epoch-days fix's effect actually visible (previously masked by the larger
stepDirection offset).

`mini_graph_widget.dart:171` has its own literal `stepDirection: 0.76`
(not sourced from `GraphStyle.stepDirection`). It's an unlabeled sparkline
with no gridlines shown, so the same visual mismatch isn't observable there
— left out of scope, as originally scoped, but flagged in case a future
`GraphView`/`CategoryGraphView`-style axis is ever added to it.

## Correction 2 (2026-08-21, from independent review)

`stepDirection: 1.0` fixed the *alignment* symptom (riser now lands exactly
on a gridline), which is why the user's on-device spot-check passed — but
an independent review read `fl_chart` 1.0.0's actual painter source
(`generateStepBarPath`, `line_chart_painter.dart`) and found the direction
convention is the opposite of what this spec originally assumed:

- riser x-position = `current.dx + deltaX * (1 - stepDirection)`
- `stepDirection = 0.0` (`stepDirectionForward`) → riser at `next.dx`: the
  flat segment across day *D*'s cell shows day *D*'s value, jump exactly at
  the day-*D+1* boundary. This is the semantic this spec wants.
- `stepDirection = 1.0` (`stepDirectionBackward`) → riser at `current.dx`:
  the flat segment across day *D*'s cell shows day *D+1*'s value instead —
  each cell displays *tomorrow's* number. Still gridline-aligned (so still
  passes an "are the bars on the lines" check), but wrong data per cell.

**Fix:** `stepDirection = 0.0`, not `1.0`. Re-verify on device against a day
with a known logged value: the flat segment *inside* that day's cell should
show that day's own number, not the next day's.

## Correction 3 (2026-08-21, after re-testing Correction 2 on device)

`stepDirection = 0.0` was tested on device and made **today's data
disappear entirely.** Root cause, missed by Correction 2 because it was
argued from reading `fl_chart`'s source only, never rendered: a step chart
draws a filled interval only *between* two consecutive real data points.
With forward fill (`0.0`), the interval `[x_D, x_{D+1}]` is filled with day
*D*'s value — i.e. day *D*'s bar is the cell to its *right*. That works for
every day that has a following day's point already in the series, but today
is always the last point in `_getFilteredDates()`/`_buildSpots()` — there is
no "tomorrow" point yet, so there is no bounded interval to the right of
today's gridline, and nothing gets drawn for it at all.

With backward fill (`1.0`), the interval `[x_{D-1}, x_D]` is filled with day
*D*'s value instead — day *D*'s bar is the cell to its *left*, bounded by
yesterday's point on the left and *D*'s own point on the right. Every day up
to and including today always has a preceding point, so today's bar is
always drawable under this convention.

**Which cell "belongs" to which day is a labeling convention, not a
correctness bug** — Correction 2's finding wasn't factually wrong about
what `fl_chart` draws, but it evaluated the two directions purely as an
abstract "which value fills this interval" question and picked the option
that happens to make the most recent day's data permanently invisible. That
is worse than the original complaint, and no on-device check was run before
recommending it. Reverting to `stepDirection = 1.0` (final): it satisfies
the original "off, half days" / gridline-alignment complaint (bars sit
exactly on gridlines) and keeps today's data visible without needing a
synthetic extra data point past today.

**Lesson:** for any chart-rendering fix in this codebase, a claim from
reading library source must be checked against an actual render before
being treated as the fix — source-reading alone missed a real, visible
regression.
