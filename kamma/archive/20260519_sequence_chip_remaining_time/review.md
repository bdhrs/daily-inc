## Thread
- **ID:** 20260519_sequence_chip_remaining_time
- **Objective:** Sequence chip shows remaining time (not full target) for all-countdown sequences.

## Files Changed
- `lib/src/views/daily_thing_item.dart` — chip label calculation now sums per-child remaining (target − actualValue, 0 if completed) instead of sum of `todayValue` for incomplete children; added `dart:math` import.

## Findings
No findings.

## Fixes Applied
None.

## Test Evidence
- `flutter test --no-pub` → all 71 tests pass.
- User manually verified the chip behavior across completed / partial / untouched children.

## Verdict
PASSED
- Review date: 2026-05-19
- Reviewer: kamma (inline)
