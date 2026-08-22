# Spec — Next-undone highlight includes sequences

## Problem

The pulsing "next undone item" highlight on the main list never lands on a
sequence. If the next thing the user should do is a sequence, nothing pulses
there and the highlight jumps to a later item (or disappears entirely when a
sequence is the only remaining undone thing).

## Verified root cause

`DailyThing.isUndoneToday` (`lib/src/models/daily_thing.dart:252`) has:

```dart
case ItemType.sequence:
  return false;
```

The model has no access to the full item list, so it cannot resolve a
sequence's children and hard-returns `false`.

`getNextUndoneIndex` (`lib/src/views/widgets/daily_things_helpers.dart:9`)
scans `items` and returns the first index where `isUndoneToday` is true.
Sequences therefore never match.

The single caller is `DailyThingsView._getNextUndoneIndex`
(`lib/src/views/daily_things_view.dart:928`), used at line 1236 to compute
`nextUndoneItem`. The row at line 1277 gets `isNextUndone` when its id matches
and `row.parent == null`; `_buildItemRow` line 833 wraps that row in `Pulse`.

Sequences are top-level rows (`row.parent == null`), so once the index
computation recognises them the existing rendering already pulses the sequence
card — no rendering change is needed.

Grep confirms `getNextUndoneIndex` has no other callers in `lib/` and no
references in `test/`.

## Existing helper to reuse

`SequenceHelper.sequenceIsUndoneToday(seq, allItems)`
(`lib/src/core/sequence_helper.dart:30`) already returns whether any resolved
child is undone today. It exists and is exactly the predicate needed. No new
logic gets written.

## Decision

Confirmed with the user: when a sequence is the next undone thing, **the
sequence card itself pulses**, like any other top-level item. Child rows stay
unhighlighted; the `row.parent == null` guard is untouched.

## Change

Make `getNextUndoneIndex` sequence-aware by giving it the full item list and
delegating sequences to the existing helper:

```dart
int getNextUndoneIndex(List<DailyThing> items, List<DailyThing> allItems) {
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    final undone = item.itemType == ItemType.sequence
        ? SequenceHelper.sequenceIsUndoneToday(item, allItems)
        : item.isUndoneToday;
    if (undone) return i;
  }
  return -1;
}
```

`DailyThing.isUndoneToday` is **not** touched — its `sequence` branch stays
`false`. Other call sites of `isUndoneToday` keep their current behaviour.

## Out of scope

- Pulsing a child row inside a sequence.
- Changing `isUndoneToday` on the model.
- Changing which items are displayed, filtered, or ordered.

## Known edge case (accepted, no code)

`sequenceIsUndoneToday` returns `true` for a sequence with no resolvable
children. Such a sequence can never be completed, so it would hold the
highlight. This mirrors `sequenceShouldShowInList`, which also treats an empty
sequence as visible, and an empty sequence is a transient authoring state
(the list already renders a "Drop items here or tap to add" placeholder for
it). No guard is added.

## Acceptance

- A sequence with at least one undone child, sitting above all other undone
  items, pulses.
- A sequence whose children are all done does not pulse; the next undone
  non-sequence item below it does.
- A non-sequence item above an undone sequence still wins the highlight.
- Child rows inside a sequence never pulse.
- `flutter analyze` clean, `flutter test --no-pub` green.

## Confidence

9/10. The mechanism is read directly from source and the fix reuses an
existing helper. The 1 point of doubt is device-only: the suite has no widget
tests for `DailyThingsView`, so the visual pulse needs a real run.
