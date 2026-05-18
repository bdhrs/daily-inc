# Spec — Sequence tap unifies expansion

## Overview
A sequence row in the daily-things list previously required two separate gestures to fully open: tapping the tile opened the buttons + mini-graph (`_isExpanded`), while clicking the chevron icon expanded the children list (`_sequenceExpanded`). Unify these so a single tap on the sequence row toggles both at once.

## What it should do
- Tapping a collapsed sequence row opens its buttons + mini-graph AND renders its children as a basic list below it.
- Tapping an expanded sequence row collapses both at once.
- Children render as plain rows (title only, no buttons/graph); each child's own expansion state is independent and unchanged.
- The chevron icon next to the sequence title is preserved as a redundant toggle (no behavioural change requested).
- The unified child-visibility state is persisted across launches (same SharedPreferences key as the existing chevron toggle).

## Assumptions & uncertainties
- The two state maps `_isExpanded` and `_sequenceExpanded` are independently maintained in `daily_things_view.dart`. Confirmed by reading the file.
- Children render based solely on `_sequenceExpanded[parentId]` in `_buildDisplayRows`; child rows do not key off `_isExpanded` of the parent. Confirmed.
- Each child's own `_isExpanded[child.id]` defaults to `false`, so children appear collapsed (basic list) when the sequence is opened. Confirmed.

## Constraints
- Touch only `daily_things_view.dart`. No refactor of unrelated code.
- Persistence must use the existing `seq_expanded_<id>` SharedPreferences key so chevron toggle and tap toggle stay in sync.

## How we'll know it's done
- Tapping a collapsed sequence shows buttons, mini-graph, and child rows simultaneously.
- Tapping again hides all three.
- Children are visible but not themselves expanded.
- `flutter test --no-pub` passes.

## What's not included
- No removal or restyling of the chevron icon.
- No change to children's own expansion behaviour.
- No new tests (change is a small UI state-coupling tweak; existing tests cover unrelated logic).
