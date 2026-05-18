## Thread
- **ID:** 20260518_sequence_tap_unifies_expansion
- **Objective:** A single tap on a sequence row should toggle both the buttons/mini-graph and the children list together, instead of needing two separate gestures.

## Files Changed
- `lib/src/views/daily_things_view.dart` — couple `_isExpanded` and `_sequenceExpanded` in the sequence row's `onExpansionChanged` callback, and persist the latter to SharedPreferences.

## Findings
No findings.

- Correctness: change is symmetric with the existing `_toggleSequenceCollapse` (lines 74-81) — same key (`seq_expanded_<id>`), same value semantics — so chevron and tap stay in sync.
- Readability: small, self-contained block guarded by `item.itemType == ItemType.sequence`.
- Architecture: respects existing decision to keep two state maps; only couples them at the write site.
- Security/performance: irrelevant scope (local UI state + single pref write).
- Children: each child's `_isExpanded` is independent and defaults to false, so children render as a plain list — matches user's stated preference.

## Fixes Applied
None.

## Test Evidence
- `flutter test --no-pub` → All tests passed (71 tests).
- Manual: user confirmed "works beautifully".

## Verdict
PASSED
- Review date: 2026-05-18
- Reviewer: kamma (inline)
