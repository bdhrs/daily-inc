# Plan — Trend missed-day decrement with zero floor

## Architecture Decisions
- Centralize accumulation in `IncrementCalculator`. Today the logic is duplicated across `mini_graph_widget.dart`, `graph_view.dart`, and `category_graph_view.dart`.
- No HistoryEntry writes. Display-time computation only.
- Floor applied per step, not only at end.
- Today is excluded from decrement.

## Phase 1 — Central helper
- [ ] Add `IncrementCalculator.accumulatedTrendUpTo(history, asOfDate)` → double.
  → verify: see Phase 3 tests.
- [ ] Add `IncrementCalculator.accumulatedTrendSeries(history, dates)` → Map<DateTime,double>.
  → verify: see Phase 3 tests.

## Phase 2 — Wire into views
- [ ] Replace `_buildTrendSpots` in `lib/src/views/widgets/mini_graph_widget.dart`.
  → verify: line slopes down across gaps and flattens at 0.
- [ ] Replace `_buildTrendSpots` in `lib/src/views/graph_view.dart`.
  → verify: full graph behaves the same.
- [ ] Replace `_getTrendAccumulatedValue` in `lib/src/views/category_graph_view.dart`.
  → verify: values match per-item graph endpoints.

## Phase 3 — Tests
- [ ] Add `test/increment_calculator_trend_test.dart`.
  → verify: `flutter test --no-pub test/increment_calculator_trend_test.dart` all pass.
- [ ] Full suite.
  → verify: `flutter test --no-pub` all pass.

## Phase 4 — Cleanup verification
- [ ] Confirm no other callers compute trend cumulative outside the helper.
  → verify: `rg "accumulatedValue|accumulated trend"` shows only helper usages.
