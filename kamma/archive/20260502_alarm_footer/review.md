## Thread
- **ID:** 20260502_alarm_footer
- **Objective:** Show alarm time in the expanded item footer, right-aligned, with category left and values centred

## Files Changed
- `lib/src/views/daily_thing_item.dart` — restructured footer row into 3-column layout; added alarm icon+time in amber on the right
- `justfile` — added android-install-debug recipe

## Findings
No findings.

## Fixes Applied
None

## Test Evidence
- `dart analyze lib/src/views/daily_thing_item.dart` → no issues

## Verdict
PASSED
- Review date: 2026-05-02
- Reviewer: kamma (inline)
