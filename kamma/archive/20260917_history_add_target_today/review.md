# Review — History add-row: Target must match today's target

**Verdict: PASSED**

Written after the fact — the two reviews ran in-session but this file was not
created at the time, which is itself recorded as a lesson.

## Reviews run

Two in parallel:

1. `coderabbit review --agent --uncommitted --include-untracked` — **0 findings**
   across all six files, spec and plan included.
2. An independent zero-context adversarial audit, instructed to distrust the
   thread's own spec and plan and to verify every factual claim against the
   code, including a revert-and-retest coverage proof. **4 real findings.**

## Files changed

- `docs/project_map.md`
- `lib/src/core/increment_calculator.dart`
- `lib/src/views/history_view.dart`
- `lib/src/views/widgets/add_history_entry_dialog.dart` (deleted)
- `test/history_add_row_target_test.dart` (new)

## Findings and fixes

**HIGH — the Done-handler change was a fabricated fix that introduced a real
bug.** The spec claimed the verbatim string copy
`_newActualValueController.text = _newTargetValueController.text;` lost
precision through `NumberFormat('0.##')`. There is no formatter on that line.
The replacement added one, so a hand-typed `12.345` became `12.35`, and
`_saveNewEntry` parses the controller text as the saved value — the rounding
would have persisted to user data. **Fixed: reverted.** The handler is byte-for-byte
as it was before the thread.

**HIGH — that change was never guarded.** The audit's revert-and-retest proved
it: reverting only the Done handler left 3 of 3 tests passing, because the
pre-filled value round-trips through the formatter unchanged. The plan's
"how we'll know it's done" implied coverage that did not exist. Moot after the
revert, but it is why the defect survived to review.

**MEDIUM — backdating pre-filled today's target into a historical row.** Not
cosmetic: `calculateTodayValue` takes its base from the last entry before
today, so a backdated row saved with today's target permanently rebases every
later target. **Fixed:** user chose to blank the field. `_syncTargetToDate`
clears Target when the date is not today and restores it on return, acting only
on the today/not-today flip so a hand-typed value is not clobbered.

**LOW — test fragility.** The index-based `TextFormField` lookup would pass
even with no add-row rendered, given a fixture whose entry carried an
`actualValue`. **Fixed:** both cases now assert the add-row opened first.

**LOW — stale doc reference.** `docs/project_map.md` still described the deleted
dialog; the thread's "referenced by nothing" sweep covered `lib/` and `test/`
but not `docs/`. **Fixed:** section removed.

**Spec corrections applied.** Three claims were wrong and are now marked
CORRECTED AFTER REVIEW in `spec.md`: the inverted precision rationale; the
claim that the main list renders `todayValue` (it renders `displayValue`, which
agrees here for a structural reason now stated explicitly); and the
`1.0 / 0.0 for check` bullet, which describes a branch the pre-fill never reaches.

## Test evidence

- Baseline before the thread: **95 tests, all passing.**
- Final: **100 tests, all passing.**
- `flutter analyze`: 1 issue, pre-existing and untouched —
  `'onReorder' is deprecated • lib/src/views/daily_things_view.dart:1264`.
- **Coverage proof, core fix:** reverting both pre-fill call sites (restoring
  `valueForDate`, its callers and the import) fails **2 of 3** tests.
- **Coverage proof, blanking:** removing the `_syncTargetToDate(...)` call fails
  **1 of 5** tests in the file. The clobber-guard test passes without the
  feature by design — it guards the implementation, not its presence.
- Both proofs backed up the file, edited via scripted rewrite, and restored in
  the same command; `md5sum -c` confirmed byte-identical restoration. No git
  commands used on the shared tree.
- Device-tested by the user before review; the blanking behaviour added after
  review is covered by tests but not yet device-checked.

## Committed

`2a55693 fix: match history add-row target to today's target`
