## Thread
- **ID:** 20260510_sequence
- **Objective:** Add a Sequence item type that chains ordered child items back-to-back.

## Files Changed
- `lib/src/models/item_type.dart` — add `sequence` enum value.
- `lib/src/models/daily_thing.dart` — add `childIds`, `autoPlay`, `autoStart` fields with JSON, copyWith, and `isUndoneToday` sequence case.
- `lib/src/core/sequence_helper.dart` — new helper for parent lookup, child resolution, done state, and delete sweep.
- `lib/src/views/widgets/filtering_helpers.dart` — exclude sequence children from top-level rows; use sequence-specific show/undone checks.
- `lib/src/views/widgets/reorder_helpers.dart` — new `reorderWithSequences` covering the four drag cases.
- `lib/src/views/add_edit_daily_item_view.dart` — Sequence type in dropdown (first), simplified form, Auto-advance/Auto-start switches, child manage dialog, "Belongs to sequence" parent picker, parent-sweep on save.
- `lib/src/views/daily_thing_item.dart` — sequence header row layout, child indent + accent border, sequence-aware done indicator and chip.
- `lib/src/views/daily_things_view.dart` — flat row builder, persisted collapse state, sequence play launcher, drop-zone placeholder, delete sweep, reorder integration.
- `lib/src/views/timer_view.dart` — `autoAdvance`, `autoStart`, `chainAutoStart` params; first-frame auto-toggle and post-complete auto-navigate.
- `pubspec.yaml` — version bump to 1.6.7+37.

## Findings
| # | Severity | Location | What | Why | Fix |
|---|---|---|---|---|---|
| 1 | major | `sequence_helper.dart:findParentSequence` + `filtering_helpers.dart` | Archived sequences still claimed their children, hiding them from the active list. | Spec §Lifecycle says "Archive sequence: children unaffected." | Skip archived sequences in `findParentSequence`. |
| 2 | minor | `sequence_helper.dart:sequenceCompletedForToday` | Empty due sequence was hard-coded undone, blocking the all-done snackbar. | Inconsistent with spec wording ("all children done" — vacuously true on empty). | Removed the explicit empty-list false branch; `every` on empty returns true. |
| 3 | nit | `reorder_helpers.dart` (within-seq drag onto placeholder) | Placeholder row only exists for empty sequences (no child to drag onto it), so unreachable today; latent if invariants change. | Readability/footgun only. | Left as-is. |
| 4 | nit | `reorder_helpers.dart` newIndex math | `newIndex -= 1` followed by `newIndex + 1` in the top-level branch round-trips the offset. | Readability only. | Left as-is. |

## Fixes Applied
- Finding #1: `findParentSequence` now ignores archived sequences. `childIds` remains intact, so unarchiving restores the relationship.
- Finding #2: `sequenceCompletedForToday` no longer special-cases empty children.
- CodeRabbit (critical): `reorderWithSequences` now preserves the original `newIndex` when delegating to `reorderDailyThings`. Previously, an adjacent down-swap (oldIndex+1 == newIndex) silently no-op'd because the anchor row was the moving row itself.
- CodeRabbit (major): added `_isNavigatingNext` guard in `TimerView._navigateToNextTask` so a manual NextTaskArrow tap during the 2 s auto-advance delay can't double-navigate.
- CodeRabbit (major): added `mounted` check in `_showSequenceTimer` after the `SharedPreferences` await before using `context`.
- CodeRabbit (minor): removed unused `parentSequence` field/param from `DailyThingItem` and its call site.
- CodeRabbit findings skipped (validated as not actionable):
  - `autoStart` invariant in `DailyThing` constructor/copyWith — already enforced at the form layer; defensive validation rejected per simplicity rule.
  - `firstWhere` without `orElse` in `reorderWithSequences` (two sites) — sequences in `rows` come from `fullList`, so the lookups cannot fail under current invariants.
  - Atomic batch update in sequence membership save — over-engineering for a solo-user offline app; partial failure would just leave a recoverable inconsistency.
  - Dead-icon branch in `daily_thing_item.dart:411` — pre-existing in HEAD; out of scope for this thread.

## Test Evidence
- `flutter analyze` → No issues found (ran post-fix).
- `coderabbit review --agent` → 10 findings; 4 fixed, 4 skipped with reason, 1 fixed by earlier internal review (#1 archived parent), 1 (Findings #6 = my own #4) re-classified critical and fixed.
- Manual smoke checks from the plan are still TODO (deferred to user / `/kamma:4-finalize`).

## Verdict
PASSED
- Review date: 2026-05-10
- Reviewer: Claude (same agent that implemented the thread; review is correspondingly less independent — recommend a quick manual pass through the spec's "How We'll Know It's Done" checklist before finalizing).
