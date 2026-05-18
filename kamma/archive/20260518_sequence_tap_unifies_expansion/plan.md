# Plan — Sequence tap unifies expansion

## Architecture Decisions
- Sync the two existing state maps in the `onExpansionChanged` callback rather than collapsing them into one. Reason: `_sequenceExpanded` has additional consumers (chevron toggle, persistence, all-expand action); merging would require touching all of them. Coupling at the write site is the smallest possible change.
- Persist the `_sequenceExpanded` update inline using the same `seq_expanded_<id>` key as `_toggleSequenceCollapse`. Reason: keeping behaviour identical between the two entry points, no helper extraction needed for one extra line.
- Keep the chevron icon and `onToggleCollapse` callback. Reason: harmless redundancy, removing it is unrequested scope.

## Phase 1 — Couple expansion in the tap handler
- [x] Update `onExpansionChanged` in `lib/src/views/daily_things_view.dart` (~line 820) so that when the item is a sequence, both `_isExpanded[id]` and `_sequenceExpanded[id]` are set to the new value, and the latter is persisted to SharedPreferences under `seq_expanded_<id>`.
  → verify: run `flutter test --no-pub`, expect all pass.
- [x] Manual check: tap a collapsed sequence and confirm buttons, mini-graph, and child rows appear together; tap again and confirm all collapse.
  → verify: user confirmed.
