# Spec — History add-row: Target must match today's target

## Overview
In the History editor (`lib/src/views/history_view.dart`), tapping the `+`
toolbar button opens an inline add-row. Its **Target** field pre-fills with a
number that does not match the target the item shows on the main daily list for
today. Ticking **Done** then copies that same wrong number into **Actual**.

This thread makes the add-row's Target pre-fill with today's real target — the
value the app already computes and renders on the main screen — and deletes the
second, divergent calculation that was producing the wrong number.

## Current behaviour (verified by reading the code)

Three call sites in `history_view.dart` pre-fill the Target field from
`IncrementCalculator.valueForDate(item, date)`:

- line 54 — `initState`, always today
- line 130 — `_maybeAutoFillTarget`, fired by a listener whenever the date text changes
- line 182 — `_startAddingEntry`, always today

`valueForDate` (`lib/src/core/increment_calculator.dart:125`) is a **pure
calendar projection** from the item's start date:

```dart
final daysSinceStart = target.difference(startDateOnly).inDays;
if (item.duration <= 0 || daysSinceStart <= 0) {
  value = item.startValue;
} else if (daysSinceStart >= item.duration) {
  value = item.endValue;              // <-- any item older than its ramp lands here
} else {
  final increment = (item.endValue - item.startValue) / item.duration;
  value = item.startValue + increment * daysSinceStart;
}
```

The target the main list shows is `DailyThing.todayValue` →
`IncrementCalculator.calculateTodayValue(item)`, a completely different,
**history-driven** calculation:

- base = the `targetValue` of the last history entry before today (or `startValue`)
- frozen at base when `item.isPaused`
- frozen at base when `!isDue(item, today)`
- base + increment when the item was done yesterday
- base unchanged during the grace period
- base − increment × (daysSinceDone − 1) after the grace period
- 1.0 / 0.0 for `ItemType.check`
- clamped to the start/end bounds

The two share no code path. They agree only for an item completed every single
calendar day since its start date, never paused and never past its ramp
duration. Worked example with real numbers — startValue 1, endValue 20,
duration 66, startDate 200 days ago, one history entry 10 days ago with
targetValue 5.0 and `doneToday: false`:

- `valueForDate(today)` → **20** (daysSinceStart 200 ≥ duration 66 → endValue)
- `calculateTodayValue` → base 5.0, no completion ever, penalty far exceeds
  base, clamped to the low bound → **1**

That 20-vs-1 gap is the reported symptom.

This is not a regression. `valueForDate` was written deliberately in thread
`20260518_history_add_target_and_sort` to guess a target for **backdated**
entries, and was then also wired into the default (today) case. That reuse is
the defect.

The add-row's Done checkbox (`history_view.dart` ~line 450) already copies
Target into Actual, so it is not broken — it faithfully copies the wrong
number. Fixing the target fixes both reported symptoms and the checkbox needs
no change.

CORRECTED AFTER REVIEW — an earlier draft of this spec claimed the verbatim
string copy lost precision and should parse-then-format instead. That was
backwards. The copy is verbatim, so a hand-typed `12.345` reaches Actual
intact; parsing and re-formatting through `NumberFormat('0.##')` would round
it to `12.35`, and `_saveNewEntry` parses the controller text as the saved
value, so the rounding would persist. The change was made, caught in review,
and reverted. The existing-entry rows are not a precedent for it either: they
write the real `double` via `copyWith(actualValue: targetValue)` and format
only for display, a split the add-row does not have.

## What it should do

1. The add-row's **Target** pre-fills with `widget.item.todayValue` — the same
   number the main daily list shows as today's target. The field stays editable.
2. Ticking **Done** in the add-row puts that same value into **Actual**. This
   already worked; it is left exactly as it was.
3. Setting the date to any day other than today **blanks** Target, so no
   wrong-but-plausible value can be saved on a backdated row. Returning to
   today restores today's target. Backdating stays possible — the date field
   remains — but the user types the past day's target by hand. (Superseded the
   original "editing the date no longer rewrites Target"; see the resolved open
   question at the end.)
4. `IncrementCalculator.valueForDate` is deleted; after (3) it has no callers.
5. `lib/src/views/widgets/add_history_entry_dialog.dart` is deleted — verified
   referenced by nothing in `lib/` or `test/`.

## Approach

No new calculation is introduced. `DailyThing.todayValue` already exists and is
what the main screen renders; the history view simply was not calling it.

- `initState` (line 54) and `_startAddingEntry` (line 182) → `widget.item.todayValue`.
- Delete `_maybeAutoFillTarget` and the `_lastAutoFilledTarget` field. The date
  listener keeps its `_validateDate(...)` call (duplicate-date checking) and
  gains `_syncTargetToDate(...)`, which blanks or restores Target on the
  today/not-today flip.
- Delete `IncrementCalculator.valueForDate`.
- Delete the dead dialog widget file.
- The add-row Done handler is left untouched (an earlier draft changed it; see
  the correction above).

Net effect is a deletion. `IncrementCalculator` loses a function and gains none.

## Rejected alternative
Folding the add-row into the normal entry rows (tap `+` → insert a real
`HistoryEntry` for today, let the existing row editor handle it) would delete
roughly 250 lines and make both bugs structurally impossible. It was rejected
because existing rows render their date as read-only `Text`, so keeping
backdating would require adding a per-row editable date field with its own
controller, parsing, duplicate-check and re-sort — more new code than it
removes. Backdating is rare but must stay possible.

## Assumptions & uncertainties
- **CORRECTED AFTER REVIEW — the main list does not render `todayValue`.**
  `daily_thing_item.dart:493` renders `widget.item.displayValue` →
  `calculateDisplayValue`, which returns today's *actual* value when today has
  an entry and only falls through to `calculateTodayValue` otherwise. The two
  agree here for a structural reason rather than by coincidence: every
  divergent branch of `calculateDisplayValue` requires an entry dated today,
  and `_saveNewEntry` rejects a duplicate date — so whenever the add-row can
  actually be saved for today, `displayValue == todayValue`. The values match.
- **The rendered strings still differ, and this thread does not change that.**
  `daily_thing_item.dart:135-152` formats minutes and stopwatch through
  `TimeConverter.toSmartString`, reps as `12x`, percentage with `%`, check as
  ✅/❌. The history editor uses `NumberFormat('0.##')` everywhere. A minutes
  target of 12.5 therefore reads `12:30` on the main list and `12.5` in the
  Target field. This mismatch predates the thread, is consistent within the
  history editor (existing rows have always shown decimal minutes), and was
  left alone deliberately.
- **CORRECTED AFTER REVIEW:** the `1.0 / 0.0 for ItemType.check` branch listed
  above only fires when an entry for today already exists — exactly the case
  where the add-row refuses to save. It never affects the pre-fill. For check,
  percentage, trend, stopwatch and sequence items the add/edit form forces
  `startValue 0, duration 1, endValue 0`, so the old and new calculations both
  return `0.0`. Nothing changed for those types.
- **Verified:** `valueForDate` has exactly three call sites, all in
  `history_view.dart`; removing them leaves it dead.
- **Verified:** `AddHistoryEntryDialog` is referenced nowhere in `lib/` or `test/`.
- **Verified:** `test/` has no test file for `history_view`, but `testWidgets`
  is already in use (`test/widget_test.dart`) and `DataManager`'s constructor
  has no side effects, so a widget test that pumps `HistoryView` and taps `+`
  is feasible without storage mocking.
- **Uncertain:** `IncrementCalculator._gracePeriodDays` is static global state.
  Any new test must set it explicitly rather than rely on the default.
- **Accepted trade-off:** backdated entries lose their auto-filled target guess.

## Constraints
- No change to `HistoryEntry`'s JSON shape or persistence.
- No change to in-row editing of existing entries, beyond nothing at all.
- No change to `calculateTodayValue`.
- No refactor of `history_view.dart` beyond the edits listed above.
- The date field stays in the add-row.

## How we'll know it's done
- A widget test taps `+` on an item whose projection and real target diverge
  (the 20-vs-1 example above) and asserts the Target field reads the real target.
- The same test ticks Done and asserts Actual matches Target.
- `flutter analyze` is clean — proves nothing still references the deleted
  function or the deleted file.
- `flutter test --no-pub` passes.
- On a real device: pick an item whose main-list target is **not** its end
  value, note that number, open its history, tap `+` → Target shows exactly
  that number; tick Done → Actual shows the same number.

## What's not included
- No auto-fill of Target for backdated dates.
- No syncing of Actual if the user manually edits Target after ticking Done.
- No editable date on existing entry rows.
- No change to the main list, graph, or any other view.

## Open question — raised by review, not yet decided

Removing the date-change auto-fill means typing a **past** date leaves the
Target field showing **today's** target. The field is not blank; it holds a
confident-looking number for the wrong day, so the user must notice and
overwrite it.

That is more than cosmetic. `calculateTodayValue` takes its base from the
`targetValue` of the last entry *before* today
(`increment_calculator.dart:151-161`). A backdated entry saved with today's
pre-filled target silently rebases every future target. With this thread's own
fixture — base 5.0, today's target 1.0 — backdating an entry to three days ago
and leaving the Target at the pre-filled `1` permanently drops the base from
5.0 to 1.0.

RESOLVED — the user chose to blank the field. `_syncTargetToDate` on the date
listener clears Target when the parsed date is not today and restores today's
target when it returns to today. It acts only on the today/not-today *flip*,
tracked by `_targetIsForToday`, so a hand-typed target survives further editing
of the date within the same category. Two tests cover it: one for the blanking
and restore, one proving a hand-typed value is not clobbered.
