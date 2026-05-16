## Thread
- **ID:** 20260516_trend_missed_decrement
- **Objective:** Missed past days for TREND items decrement the cumulative total by 1, floored at 0.

## Files Changed
- `lib/src/core/increment_calculator.dart` — added `accumulatedTrendUpTo` and `accumulatedTrendSeries` helpers (today excluded from decrement, per-step zero floor).
- `lib/src/views/widgets/mini_graph_widget.dart` — `_buildTrendSpots` delegates to `accumulatedTrendSeries`.
- `lib/src/views/graph_view.dart` — `_buildTrendSpots` delegates to `accumulatedTrendSeries`.
- `lib/src/views/category_graph_view.dart` — `_getTrendAccumulatedValue` delegates to `accumulatedTrendUpTo`.
- `test/increment_calculator_trend_test.dart` — new, 11 unit tests covering empty/single/gap/floor/today-excluded cases.

## Findings
No findings.

## Fixes Applied
- Initial test "only today entry is not part of the walk" expected 0.0 but a today entry of +1 correctly produces 1.0 — rewrote the test as "today entry counts but today is never decremented as missed" to reflect the real contract.

## Test Evidence
- `flutter test --no-pub test/increment_calculator_trend_test.dart` → 11 pass
- `flutter test --no-pub` → 71 pass
- `flutter analyze --no-pub` → No issues found

## Verdict
PASSED
- Review date: 2026-05-16
- Reviewer: kamma (inline)
