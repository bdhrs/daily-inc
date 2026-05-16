import 'package:daily_inc/src/models/daily_thing.dart';

/// Reorders a flat sequence-aware row list and returns an updated fullList.
///
/// Each row carries an optional parent, so the algorithm can route the move to
/// the correct container (fullList order for top-level items, childIds for
/// sequence children). The destination is always determined by row position —
/// the item lands where the user dropped it.
List<DailyThing> reorderWithSequences({
  required List<({DailyThing item, DailyThing? parent})> rows,
  required List<DailyThing> fullList,
  required int oldIndex,
  required int newIndex,
}) {
  final originalNewIndex = newIndex;
  if (newIndex > oldIndex) newIndex -= 1;
  if (oldIndex < 0 || oldIndex >= rows.length) return List.from(fullList);
  newIndex = newIndex.clamp(0, rows.length - 1);

  final sourceRow = rows[oldIndex];
  final destRow = rows[newIndex];
  final movingItem = sourceRow.item;
  final sourceParent = sourceRow.parent;
  final destParent = destRow.parent;
  final destIsPlaceholder = destRow.item.id.startsWith('__seq_placeholder_');

  // Placeholders are drop targets only, never draggable.
  if (movingItem.id.startsWith('__seq_placeholder_')) {
    return List.from(fullList);
  }

  List<DailyThing> result = List.from(fullList);

  List<DailyThing> applyUpdate(DailyThing updated) =>
      result.map((item) => item.id == updated.id ? updated : item).toList();

  // destSeqId: the sequence the item should land inside, or null for top-level.
  final String? destSeqId = destParent?.id;

  // --- Same-sequence reorder ---
  if (sourceParent != null && destSeqId == sourceParent.id) {
    final seq = result.firstWhere((item) => item.id == sourceParent.id);
    final originalChildIds = List<String>.from(seq.childIds);
    final ids = List<String>.from(seq.childIds)
      ..removeWhere((id) => id == movingItem.id);
    // Use the pre-removal childIds to find the insertion index so that
    // moving an item downward past another lands correctly after it.
    final insertAt = destIsPlaceholder
        ? 0
        : originalChildIds.indexOf(destRow.item.id).clamp(0, ids.length);
    ids.insert(insertAt, movingItem.id);
    return applyUpdate(seq.copyWith(childIds: ids));
  }

  // --- Step 1: Remove from source container ---
  if (sourceParent != null) {
    final srcSeq = result.firstWhere((item) => item.id == sourceParent.id);
    result = applyUpdate(srcSeq.copyWith(
      childIds: srcSeq.childIds.where((id) => id != movingItem.id).toList(),
    ));
  }

  // --- Step 2: Insert into destination container ---
  if (destSeqId != null) {
    // Into a sequence: insert at the position of the dest child (or first if placeholder).
    final dstSeq = result.firstWhere((item) => item.id == destSeqId);
    final ids = List<String>.from(dstSeq.childIds);
    final insertAt = destIsPlaceholder
        ? 0
        : ids.indexOf(destRow.item.id).clamp(0, ids.length);
    ids.insert(insertAt, movingItem.id);
    result = applyUpdate(dstSeq.copyWith(childIds: ids));
  } else {
    // Into top-level: reposition in fullList adjacent to the anchor row item.
    final fromIdx = result.indexWhere((item) => item.id == movingItem.id);
    if (fromIdx != -1) result.removeAt(fromIdx);
    final anchorIdx = result.indexWhere((item) => item.id == destRow.item.id);
    if (anchorIdx == -1) {
      result.add(movingItem);
    } else if (originalNewIndex > oldIndex) {
      // Moving down: item goes after the anchor.
      result.insert(anchorIdx + 1, movingItem);
    } else {
      // Moving up: item goes before the anchor.
      result.insert(anchorIdx, movingItem);
    }
  }

  return result;
}
