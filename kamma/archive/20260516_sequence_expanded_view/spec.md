# Sequence Expanded View Adaptations

## Overview
The expanded section of a DailyThingItem (action buttons row + bottom info row)
currently behaves the same for every item type. For SEQUENCE items several
controls are nonsensical (no own history, note, pause), and the bottom row
should aggregate child values instead of showing the sequence's own (unused)
start/end/increment. Also: the category default value 'None' is being rendered
literally as the word "None".

## Affected files
- `lib/src/views/daily_thing_item.dart` — sole UI file for the expanded section.
  Lines 467-588 (button row) and lines 590-723 (mini graph + bottom info row).
- `lib/src/core/sequence_helper.dart` — already exposes `resolveChildren`; we
  add a `sumMinutesChildren` helper here.

## What it should do
For SEQUENCE items, in the expanded section:

1. Action button row shows ONLY: graph (daily stats), edit, duplicate, archive,
   delete. Hidden: edit-history, edit-note, pause/resume.
2. Mini graph: unchanged (already shows the sum-of-children series).
3. Bottom row (always shown for sequences, regardless of category):
   - Left: category text. Shown if the stored category is a non-empty value
     other than the literal string 'None'. Otherwise blank.
   - Centre: sum of MINUTES children's startValue → endValue and increment,
     formatted as mm:ss via `TimeConverter`. Non-minutes children are ignored.
     If no minutes children exist, hide the centre cluster.
   - Right: alarm icon + nag time, unchanged.

For NON-SEQUENCE items: behaviour is unchanged, EXCEPT the 'None' literal is
also treated as blank in the category column (per user instruction to apply
this fix globally).

## Assumptions & uncertainties
- Sequences are intended to chain MINUTES children primarily (per project.md);
  summing only minutes children matches the dominant use case.
- Default category in the data model is the literal string 'None' (model line
  53). Blanking it in the UI does not require a data migration.
- Non-sequence bottom-row guard becomes `hasCategory || alarm`. Items that
  currently show only "None" will no longer render that row — accepted.

## Constraints
- Behaviour-preserving for non-sequence items beyond the 'None'→blank change.
- No new dependencies. No data model changes.

## How we'll know it's done
- Expanding a SEQUENCE shows only the 5 retained action icons.
- Bottom row of a sequence shows summed mm:ss for start→end and increment of
  its minutes children.
- A sequence (or any item) with category 'None' shows a blank left column.
- `flutter test --no-pub` passes.

## What's not included
- No changes to non-sequence button rows.
- No changes to mini-graph rendering.
- No changes to data model or persistence.
- No changes to how sequences are played, ordered, or completed.
