## Thread
- **ID:** 20260804_item_auto_start
- **Objective:** Make auto-start a per-item property of time-based items, with a
  sequence's Auto-start switch acting as a bulk setter for its children.
- **GitHub issue:** none referenced.

## Files Changed
- `lib/src/models/daily_thing.dart` — `autoStart` doc comment: per-item timing session, not sequence-only
- `lib/src/views/add_edit_daily_item_view.dart` — Auto-start switch for minutes/stopwatch; Auto-advance gate removed from the sequence switch; `_isTimeBased`/`_supportsAutoStart`; child propagation on submit
- `lib/src/views/timer_view.dart` — `chainAutoStart` deleted; chained `autoStart` reads the next item's flag; fresh-session guard; `_createUpdatedItem` → `copyWith`
- `lib/src/views/stopwatch_view.dart` — new `autoStart` param with fresh-session guard; `_createUpdatedItem` → `copyWith`
- `lib/src/views/daily_things_view.dart` — all three timer/stopwatch launch sites pass the item's own `autoStart`

## Findings
| # | Severity | Location | What | Why | Fix |
|---|----------|----------|------|-----|-----|
| 1 | major | `daily_things_view.dart:160`, `add_edit_daily_item_view.dart:842` | Sequences with Auto-start on today lose it; propagation was gated on the sequence's flag *changing*, so a plain save did not self-heal | Silent loss of existing behaviour on upgrade | Fixed: gate dropped, every sequence save re-asserts the flag onto time-based children. Accepted cost — the sequence is authoritative, so per-child divergence lasts only until the next sequence save |
| 2 | major | `timer_view.dart:341`, `stopwatch_view.dart:273` | Auto-start fired on an item already finished today (`initializeTimerState` returns `hasStarted: true`), starting an overtime clock that `_saveProgress` persists | Mutates saved data with no user action and no audible cue | Fixed: `!_hasStarted` guard (timer), `_elapsedSeconds == 0` guard (stopwatch) |
| 3 | major | `timer_view.dart:829` | Chained `autoStart` was ANDed with `widget.autoAdvance`, but `_navigateToNextTask` is also reached from the manual next-arrow | Contradicted spec reqs 2 and 4; an item with the flag on would not start | Fixed: `autoStart: nextTask.autoStart` |
| 4 | minor | `add_edit_daily_item_view.dart:847` | Propagation used `_supportsAutoStart`, which includes `sequence`, so a nested sequence child could be written non-recursively | Latent trap reading as intentional | Fixed: `_isTimeBased` for the loop |
| 5 | minor | `stopwatch_view.dart:274`, `timer_view.dart:341` | Un-awaited SharedPreferences reads race the post-frame auto-start, so dim/fade can be skipped for a session | Pre-existing; this thread makes it reachable on every plain open | Deferred — pre-existing, logged to `kamma/lessons.md` |
| 6 | minor | `stopwatch_view.dart:361` | `_lastTriggeredSubdivision = -1` against restored `_elapsedSeconds` rings a subdivision bell on the first tick | Bell with no user action | Fixed as a side effect of finding 2's guard; underlying manual-play case left pre-existing and logged |
| 7 | minor | `add_edit_daily_item_view.dart:1298` | The sequence switch could show a value none of its children held | Subtitle overstated the guarantee | Fixed alongside finding 1: the switch is now authoritative and re-asserted on every save |
| 8 | nit | `add_edit_daily_item_view.dart:296` | `_haveTemplateParametersChanged()` ignores `autoStart` | Consistent with existing omissions (`autoPlay`, `chainDelaySeconds`); only the backup *trigger* is missed, content is re-read from storage | Left as-is |
| 9 | nit | `add_edit_daily_item_view.dart:849` | Propagation does N load+save round trips | Matches the sibling child-stealing sweep; bounded by child count | Left as-is |
| 10 | nit | `add_edit_daily_item_view.dart:1264` | Build guard said "time-based" the long way round | Readability | Fixed via `_isTimeBased` |

**Came back clean** (verified by reading every call site, not assumed): the
`copyWith` substitution for both `_createUpdatedItem` bodies — old code passed
23 fields and dropped exactly `childIds`, `autoPlay`, `autoStart`,
`chainDelaySeconds`, all of which were being destroyed; `actualTodayValue` is
dropped identically before and after. `chainAutoStart` removal — exactly three
`TimerView` construction sites, zero remaining references. `nextTask`
staleness — the edit form is unreachable while a timer is open. Stopwatch
post-frame double-fire — impossible. Propagation ordering against both sibling
write blocks — disjoint field sets. Auto-advance gate removal — no data-loss
path. Edit round-trip and duplicate — intact. No orphaned code from this thread.

## Fixes Applied
- Findings 1, 2, 3, 4, 6, 7, 10 fixed; CodeRabbit's `autoStart` comment wording applied
- Findings 5, 8, 9 deferred with reasons
- Finding 1 was first accepted as a manual re-toggle, then fixed in code when the
  user restated the requirement: a sequence's Auto-start must always drive its
  children. Re-verified: `flutter analyze` clean, 76/76 tests pass.

## Test Evidence
- `flutter analyze --no-pub` (scope: whole project) → pass, no issues
- `flutter test --no-pub` (scope: whole suite, 76 tests / 10 files) → pass, no pre-existing failures
- `coderabbit review --agent --base main --type uncommitted` (scope: all 5 changed files, first attempt) → 1 minor finding, applied
- Independent agent review (scope: full diff, five axes, all required methods) → 10 findings

- Manual device test by the user on a Pixel 8 Pro (release build, versionCode 38)
  after `just update` → reported working. This covers the auto-start paths the
  automated suite cannot reach.

## Not Verified
- **The feature has zero automated coverage.** No test in the repo references
  `autoStart`, `TimerView` or `StopwatchView`; the 76 green tests are
  IncrementCalculator/grace-period/trend math. They prove only that the
  `copyWith` substitution did not break history-reading math.
- Not exercised at all: any behaviour requiring the app to run — the finding-5
  prefs race in practice, the finding-6 bell timing, end-to-end persistence of
  the finding-2 overtime path, wakelock/brightness across the `pushReplacement`
  chain hand-off, and the rendered placement of the new switch.
- Per the repo's own testing rule, this needs one real interactive run on device
  before it is called done. That run has not happened.

## Verdict
PASSED
- Review date: 2026-08-04
- Reviewer: independent subagent (zero-context) + CodeRabbit CLI; fixes applied and re-verified by the implementing session
