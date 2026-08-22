# Review — Next-undone highlight includes sequences

## Coverage

What was actually reviewed:

- Agent review of the full diff of the two changed source files and the new
  test file, read from disk after implementation.
- `flutter analyze` (project-wide): no issues found.
- `flutter test --no-pub` (full suite, 87 tests): all passed. Baseline before
  the change was also green, so there are no pre-existing failures to carry.
- Device confirmation by the user: a sequence card pulses when it is the next
  undone item.

What was **not** covered:

- CodeRabbit was deliberately skipped. A second agent had uncommitted work in
  the same tree (`lib/src/theme/app_palette.dart`,
  `lib/src/theme/color_palette.dart`, `lib/src/views/daily_thing_item.dart`)
  and no scoping flag cleanly covers this thread's three files without also
  reviewing that in-progress work. Decision confirmed with the user.
- No widget test covers `DailyThingsView`, so the pulse rendering itself is
  verified only by the user's device run, not by the suite.

## Shared-tree check

`git status --short` and `git diff` were used to confirm both changed source
files contain this thread's changes and nothing else. The other agent's files
were not read, edited, staged, or reverted.

## Findings

None requiring a fix. Four points examined and cleared:

1. **Missing `shouldShowInList` gate on the sequence branch.**
   `DailyThing.isUndoneToday` returns false when an item is not due, but
   `SequenceHelper.sequenceIsUndoneToday` has no equivalent gate on the
   sequence itself. Not a defect: it delegates to each child's own
   `isUndoneToday`, which applies that child's gate, so a sequence whose
   children are not due today yields no undone child and does not pulse.

2. **Archived children.** `resolveChildren` defaults to
   `includeArchived: false`, so an archived undone child cannot pull the
   highlight onto its sequence. This differs from `_buildDisplayRows`, which
   passes `includeArchived: _showArchivedItems`, but the stricter behaviour is
   the desirable one — archived work should not drive the next-item cue.

3. **Correct source list for resolution.** The caller passes `_dailyThings`
   rather than the displayed subset. This is required: a sequence's children
   need not appear in `displayedItems`. It matches what `_buildDisplayRows`
   already passes.

4. **Per-sequence map rebuild.** `resolveChildren` builds an id→item map on
   every call, so a list with many sequences rebuilds it repeatedly. The scan
   returns at the first undone item and the list is a single user's task list,
   so this is not worth optimising.

## Accepted behaviour, no code

A sequence with no resolvable children reports as undone and will hold the
highlight indefinitely. Recorded in spec.md, confirmed with the user, left
unguarded — it mirrors `sequenceShouldShowInList` and is a transient authoring
state that already renders an "add items" placeholder.

## Outcome

Approved. No changes required as a result of review.
