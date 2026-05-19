# Plan — Sequence chip remaining time

## Architecture Decisions
- Inline the per-child remaining calculation in the existing `Builder` block — single call site, no helper needed.
- Use existing `todayHistoryEntry` and `completedForToday` getters; no new fields or model methods.
- Clamp per-child remaining at 0 to defend against floating-point underflow.

## Phase 1 — Update chip label calculation

- [ ] Modify the `Builder` block in `lib/src/views/daily_thing_item.dart` (~lines 315–327): when `allMinutes`, replace the sum of `c.todayValue` over `incomplete` children with a sum across all `seqChildren` of `c.completedForToday ? 0.0 : math.max(0.0, c.todayValue - (c.todayHistoryEntry?.actualValue ?? 0.0))`.
  → verify: read resulting code; formula matches spec.

- [ ] Add `import 'dart:math' as math;` to `lib/src/views/daily_thing_item.dart` if not already present.
  → verify: grep top of file.

- [ ] Run `flutter test --no-pub`.
  → verify: all pass.
