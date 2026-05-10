import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

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

/// Reorders a flat sequence-aware row list and returns an updated fullList.
///
/// The row list carries optional parent metadata so that dragging a top-level
/// item into a sequence block, or a child out of one, is handled correctly.
List<DailyThing> reorderWithSequences({
  required List<({DailyThing item, DailyThing? parent})> rows,
  required List<DailyThing> fullList,
  required int oldIndex,
  required int newIndex,
}) {
  final originalNewIndex = newIndex;
  if (newIndex > oldIndex) newIndex -= 1;

  if (oldIndex < 0 ||
      oldIndex >= rows.length ||
      newIndex < 0 ||
      newIndex >= rows.length) {
    return List<DailyThing>.from(fullList);
  }

  final sourceRow = rows[oldIndex];
  final destRow = rows[newIndex];
  final movingItem = sourceRow.item;
  final sourceParent = sourceRow.parent;
  final destParent = destRow.parent;

  List<DailyThing> result = List<DailyThing>.from(fullList);

  DailyThing updateItem(DailyThing item, DailyThing updated) =>
      item.id == updated.id ? updated : item;

  if (sourceParent == null && destParent == null) {
    // Top-level to top-level: standard reorder using displayed row positions
    final displayedItems = rows.map((r) => r.item).toList();
    return reorderDailyThings(
      fullList: fullList,
      displayedItems: displayedItems,
      oldIndex: oldIndex,
      newIndex: originalNewIndex,
    );
  } else if (sourceParent == null && destParent != null) {
    // Top-level item dragged into a sequence: remove from top-level position,
    // append to dest sequence's childIds
    if (destParent.itemType == ItemType.sequence &&
        !destParent.childIds.contains(movingItem.id)) {
      final updatedSeq = destParent.copyWith(
        childIds: [...destParent.childIds, movingItem.id],
      );
      result = result.map((item) => updateItem(item, updatedSeq)).toList();
    }
  } else if (sourceParent != null && destParent?.id == sourceParent.id) {
    // Child reordered within the same sequence
    final seq = result.firstWhere((item) => item.id == sourceParent.id);
    final ids = List<String>.from(seq.childIds);
    final srcIdx = ids.indexOf(movingItem.id);
    if (srcIdx != -1) {
      ids.removeAt(srcIdx);
      final dstIdx = seq.childIds.indexOf(destRow.item.id);
      ids.insert(dstIdx.clamp(0, ids.length), movingItem.id);
      final updatedSeq = seq.copyWith(childIds: ids);
      result = result.map((item) => updateItem(item, updatedSeq)).toList();
    }
  } else {
    // Child moved out of its sequence (to top-level or different sequence)
    if (sourceParent != null) {
      final srcSeq = result.firstWhere((item) => item.id == sourceParent.id);
      final updatedSrc = srcSeq.copyWith(
        childIds:
            srcSeq.childIds.where((id) => id != movingItem.id).toList(),
      );
      result = result.map((item) => updateItem(item, updatedSrc)).toList();
    }
    if (destParent != null && destParent.itemType == ItemType.sequence) {
      final dstSeq = result.firstWhere((item) => item.id == destParent.id);
      if (!dstSeq.childIds.contains(movingItem.id)) {
        final updatedDst = dstSeq.copyWith(
          childIds: [...dstSeq.childIds, movingItem.id],
        );
        result = result.map((item) => updateItem(item, updatedDst)).toList();
      }
    }
  }

  return result;
}
