import 'package:daily_inc/src/models/daily_thing.dart';

/// Computes the new ordering of the full list of DailyThing based on a reorder
/// interaction within a filtered (displayed) view.
///
/// This mirrors the logic originally embedded in the onReorder callback of
/// DailyThingsView. It is a pure function to keep UI code clean and enable
/// independent testing.
///
/// Parameters:
/// - fullList: the original, complete list of items (will not be mutated)
/// - displayedItems: the subset of items currently displayed (e.g., filtered)
/// - oldIndex/newIndex: indices within displayedItems provided by ReorderableListView
///
/// Returns: a new `List<DailyThing>` reflecting the new order in the full list.
List<DailyThing> reorderDailyThings({
  required List<DailyThing> fullList,
  required List<DailyThing> displayedItems,
  required int oldIndex,
  required int newIndex,
}) {
  // Work on a copy to keep function pure
  final List<DailyThing> result = List<DailyThing>.from(fullList);

  // Normalize newIndex when moving downward as ReorderableListView semantics require
  int normalizedNewIndex = newIndex;
  if (normalizedNewIndex > oldIndex) {
    normalizedNewIndex -= 1;
  }

  // Moving item from the visible subset
  if (oldIndex < 0 || oldIndex >= displayedItems.length) {
    // Out of bounds, return original
    return result;
  }
  final moving = displayedItems[oldIndex];

  // Remove from the full list
  final fromFull = result.indexOf(moving);
  if (fromFull == -1) {
    // Not found; nothing to do
    return result;
  }
  final removed = result.removeAt(fromFull);

  // Compute insertion point in the full list based on the visible anchor
  int toFull;
  if (normalizedNewIndex >= 0 && normalizedNewIndex < displayedItems.length) {
    final anchor = displayedItems[normalizedNewIndex];
    toFull = result.indexOf(anchor);
    if (toFull == -1) {
      // If anchor not found (rare), fallback to keeping relative spot
      toFull = fromFull;
    }
  } else {
    // Dropped past end of visible list: insert right after the last visible item in the full list
    toFull = fromFull; // default fallback keeps original if no visible items
    if (displayedItems.isNotEmpty) {
      final lastVisible = displayedItems.last;
      final lastIdx = result.indexOf(lastVisible);
      toFull = (lastIdx == -1) ? fromFull : lastIdx + 1;
    }
  }

  // Adjust if moved downward in the full list after removal
  if (fromFull < toFull) {
    toFull -= 1;
  }

  // Clamp to valid range and insert
  toFull = toFull.clamp(0, result.length);
  result.insert(toFull, removed);

  return result;
}
