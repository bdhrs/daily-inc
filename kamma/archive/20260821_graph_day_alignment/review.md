## Thread
- **ID:** 20260821_graph_day_alignment
- **Objective:** Fix individual-item and category graphs so data spots and
  Monday gridlines/labels line up on the correct calendar day.

## Files Changed
- `lib/src/views/widgets/graph_style_helpers.dart` — `epochDays`/
  `dateFromEpochDays` rewritten to anchor on `DateTime.utc(y,m,d)` (removes
  a timezone-dependent fractional-day offset). `GraphStyle.stepDirection`
  went through three values during this thread: `0.76` (original, buggy) →
  `1.0` (fixed the reported misalignment, confirmed by user) → `0.0`
  (changed during independent review based on reading `fl_chart` source,
  but broke on-device: today's data disappeared entirely) → **`1.0`
  (final, reverted)**.

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | major (resolved via revert) | `graph_style_helpers.dart:9` | Original bug: `stepDirection = 0.76` put the step riser 76% through each day's interval instead of on a gridline. | Bars visibly offset from gridlines, Mondays didn't line up. | Fixed by moving to `1.0`. |
| 2 | rejected on re-test | `graph_style_helpers.dart:9` | An independent review read `fl_chart`'s painter source and argued `1.0` (`stepDirectionBackward`) makes each day's cell show the *next* day's value, and recommended `0.0` (`stepDirectionForward`) instead. | The review was correct about what the two directions do to *historical* cells, but never rendered the chart — `0.0` requires a "next" point to bound the most recent day's interval, and today has none, so today's bar is never drawn at all. Confirmed by the user on device: "today is no longer showing." | Reverted to `1.0`. Documented as a source-only-review blind spot in spec.md "Correction 3" — a claim from library source must be checked against an actual render before being applied. |
| 3 | nit | `graph_style_helpers.dart:56-199` | `GraphStyleHelpers.getTitlesData`/`getGridData` are dead code (zero call sites, confirmed via grep) with the old local-midnight date math, independent of `stepDirection`. | If ever resurrected, silently reintroduces the original timezone bug. | No action required now; flagged for whoever eventually deletes or revives this code. |
| 4 | rejected | `graph_style_helpers.dart:30-33` (`dateFromEpochDays`) | CodeRabbit flagged that the reconstructed `DateTime` should stay UTC rather than being converted to local. | Traced every call site (`graph_mixin.dart:148,202,288`, `category_graph_view.dart:432`, `graph_view.dart:159`) — each either checks `.weekday` (timezone-safe) or rebuilds a local `DateTime` from y/m/d before use. No site depends on the `isUtc` flag. | No change. |

## Fixes Applied
- `epochDays`/`dateFromEpochDays`: rewritten to UTC-anchored (kept).
- `GraphStyle.stepDirection`: `0.76` → `1.0` → `0.0` (regression, reverted)
  → `1.0` (final).

## Test Evidence
- `flutter test --no-pub` (scope: full project, 82 tests) → all pass at
  every step of the above, including the final `1.0` value. None of these
  tests exercise `epochDays`/`dateFromEpochDays`/`stepDirection` directly —
  this suite proves no regressions elsewhere, not correctness of the graph
  rendering itself.
- `flutter analyze` (scope: full project) → "No issues found!"
- `coderabbit review --agent --base main --type uncommitted` (scope: full
  uncommitted diff) → one finding, reviewed and rejected as a false
  positive (#4 above).
- User manually tested on device four times across this thread: rejected
  `0.76` (misaligned), confirmed `1.0` ("spot on"), rejected `0.0` (today
  missing), and re-confirmed final `1.0` after the revert ("now it's
  correct").

## Not Verified
- No automated test covers `epochDays`/`dateFromEpochDays`/`stepDirection`
  directly — coverage for this code path is manual/visual only, consistent
  with this project's documented lack of widget tests for graph views. A
  regression here (like the `0.0` one) would not be caught by CI.
- `mini_graph_widget.dart`'s separate (still-buggy) epoch-days divisor and
  literal `stepDirection: 0.76` were confirmed out of scope (no shared
  gridlines/state with the fixed views) but remain unfixed.

## Verdict
PASSED — code, tests, and lint clean; the epoch-days fix is solid;
`stepDirection` settled on `1.0`, confirmed correct on device by the user
after the full round-trip (including the caught-and-reverted `0.0`
regression).
- Review date: 2026-08-21
- Reviewer: Independent subagent (general-purpose, source-only — later
  found to have a blind spot) + coordinator (caught the regression from
  user's live device report and reverted)
