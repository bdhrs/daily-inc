import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

class SequenceHelper {
  static DailyThing? findParentSequence(
      DailyThing item, List<DailyThing> allItems) {
    for (final seq in allItems) {
      if (seq.itemType == ItemType.sequence &&
          seq.childIds.contains(item.id)) {
        return seq;
      }
    }
    return null;
  }

  /// Returns children of [seq]. By default filters out archived items so the
  /// timer flow and due-today logic only see active children. Pass
  /// [includeArchived: true] when rendering the archived view.
  static List<DailyThing> resolveChildren(
      DailyThing seq, List<DailyThing> allItems,
      {bool includeArchived = false}) {
    final itemMap = {for (final item in allItems) item.id: item};
    return seq.childIds
        .map((id) => itemMap[id])
        .whereType<DailyThing>()
        .where((item) => includeArchived || !item.isArchived)
        .toList();
  }

  static bool sequenceIsUndoneToday(
      DailyThing seq, List<DailyThing> allItems) {
    final children = resolveChildren(seq, allItems);
    if (children.isEmpty) return true;
    return children.any((child) => child.isUndoneToday);
  }

  static bool sequenceCompletedForToday(
      DailyThing seq, List<DailyThing> allItems) {
    if (!seq.isDueToday) return true;
    final children = resolveChildren(seq, allItems);
    if (children.isEmpty) return false;
    return children.every((child) => child.completedForToday);
  }

  static bool sequenceShouldShowInList(
      DailyThing seq, List<DailyThing> allItems) {
    final children = resolveChildren(seq, allItems);
    if (children.isEmpty) return true;
    return children.any((child) => child.shouldShowInList);
  }

  static List<DailyThing> sweepDeletedItem(
      String deletedId, List<DailyThing> allItems) {
    return allItems.map((item) {
      if (item.itemType == ItemType.sequence &&
          item.childIds.contains(deletedId)) {
        return item.copyWith(
          childIds: item.childIds.where((id) => id != deletedId).toList(),
        );
      }
      return item;
    }).toList();
  }
}
