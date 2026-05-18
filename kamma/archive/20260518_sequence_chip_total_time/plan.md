# Plan — Sequence chip shows total time when all children are countdown timers

## Architecture Decisions
- Compute the display string inline in the `Builder` where `seqChildren` is already in scope. No new helper — single use site, trivial logic.
- Reuse existing `TimeConverter.toSmartString` for formatting (same as elsewhere for minutes).

## Phase 1 — Implement chip variant
- [x] In `lib/src/views/daily_thing_item.dart`, inside the `isSequenceTile` chip block (around line 315), compute:
  - `allMinutes = seqChildren.isNotEmpty && seqChildren.every((c) => c.itemType == ItemType.minutes)`
  - if `allMinutes`: `label = TimeConverter.toSmartString(sum of c.todayValue for c in seqChildren where !c.completedForToday)`
  - else: `label = '${seqChildren.where((c) => !c.completedForToday).length}'` (current behavior)
- [x] Replace the existing `Text('${seqChildren.where((c) => !c.completedForToday).length}')` with `Text(label)`. Leave the play arrow and surrounding layout untouched.
  → verify: `flutter test --no-pub` passes.

## Phase 2 — Manual smoke check
- [x] Build & run; observe one all-minutes sequence and one mixed sequence; confirm chip text differs as expected.
  → verify: user confirms in STOP 2.
