# Plan — Sequence Completion State

## Architecture Decisions
- Make `sequenceCompletedForToday` purely child-driven, consistent
  with the two sibling helpers (`sequenceShouldShowInList`,
  `sequenceIsUndoneToday`). The sequence container's own
  `isDueToday` is unreliable (sequences never accrue history), so it
  must not gate completion.
- One-line removal; no new fields, no signature change, no new
  abstraction. All four consumers benefit unchanged.
- Add the first unit tests for the sequence-state helpers since none
  exist today.

## Phase 1 — Fix completion logic
- [x] In `lib/src/core/sequence_helper.dart::sequenceCompletedForToday`,
      remove the `if (!seq.isDueToday) return true;` gate so the
      result is `children.every((c) => c.completedForToday)` (with
      the existing empty-children → `false` guard).
      → verify: `flutter analyze` clean. ✓ No issues found.
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 2 — Tests
- [x] Add `test/sequence_completion_test.dart` covering a weekly
      (weekday-based) sequence with three `check` children:
      - 1 of 3 done on the due weekday → `sequenceCompletedForToday`
        is false.
      - simulate "day after the due weekday" (the original bug):
        sequence not due by its own schedule, children carried over,
        1 of 3 done → still false.
      - 3 of 3 done → true.
      - cross-check `sequenceIsUndoneToday` flips to false only when
        all three are done.
      → verify: new tests pass. ✓ 5/5 pass.
- [x] PHASE COMPLETE: verify all tasks done, no regressions

## Phase 3 — Verification
- [x] `flutter test --no-pub` → full suite green. ✓ 76 tests, 0 failures.
- [x] Manual sanity check by user. ✓ Tested on device; solves the problem.
