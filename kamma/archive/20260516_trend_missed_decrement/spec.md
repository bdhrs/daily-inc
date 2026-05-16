# Spec — Trend missed-day decrement with zero floor

## Overview
The TREND activity type currently shows an accumulated total of all per-day entries (-1 / 0 / +1). Missed days are simply skipped, leaving the cumulative line flat across gaps. We want missed past days to count as -1 against the accumulated total, but the accumulated total must never drop below zero.

## What it should do
- For each TREND item, when displaying the accumulated value (mini graph, full graph, category graph):
  - Walk day-by-day from the first history entry through yesterday.
  - For each day:
    - If a `HistoryEntry` exists with a non-null `actualValue` → add that value to the running total.
    - Otherwise (missed day) → subtract 1.
  - After every step, clamp the running total at 0 (floor).
- Today's date is NOT treated as a missed day even if no entry exists yet.
- No new `HistoryEntry` rows are written. The change is purely in how the cumulative value is computed.
- Behavior applies to all existing trend history retroactively (backfill is implicit because the computation runs each render).

## Assumptions & uncertainties
- The user-visible "current value" on the daily card (today's -1/0/+1) is unchanged. The mechanic affects accumulated/graph display only.
- The mini graph's Y-axis padding logic already supports the new (potentially lower) min/max range.
- `category_graph_view._getTrendAccumulatedValue` is the only other place that computes a cumulative trend total.
- `HistoryEntry` records older than the first stored entry don't exist; we start the walk from `history.first.date`.
- No persistence migration is needed.

## Constraints
- Touch only trend-accumulation code paths. No changes to data model, persistence, or per-day input UI.
- Keep behavior strict: floor at zero is applied at each step, not only at the end.

## How we'll know it's done
- Unit tests covering: empty history, single entry, missed days reducing total, floor at zero stopping decrement, mix of manual -1 and missed days, today excluded from decrement.
- `flutter test --no-pub` passes.
- Manual graph check: a trend item with a gap shows a downward slope across the gap and bottoms out at 0, never going negative.

## What's not included
- Writing synthetic HistoryEntry rows for missed days.
- Notifying or marking the daily card differently for trend items with missed days.
- Any changes to other item types.
