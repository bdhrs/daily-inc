import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

class SequenceHelper {
  static DailyThing? findParentSequence(
      DailyThing item, List<DailyThing> allItems) {
    for (final seq in allItems) {
      if (seq.itemType == ItemType.sequence &&
          !seq.isArchived &&
          seq.childIds.contains(item.id)) {
        return seq;
      }
    }
    return null;
  }

  static List<DailyThing> resolveChildren(
      DailyThing seq, List<DailyThing> allItems) {
    final itemMap = {for (final item in allItems) item.id: item};
    return seq.childIds
        .map((id) => itemMap[id])
        .whereType<DailyThing>()
        .where((item) => !item.isArchived)
        .toList();
  }

  static bool sequenceIsUndoneToday(
      DailyThing seq, List<DailyThing> allItems) {
    return resolveChildren(seq, allItems).any((child) => child.isUndoneToday);
  }

  static bool sequenceCompletedForToday(
      DailyThing seq, List<DailyThing> allItems) {
    if (!seq.isDueToday) return true;
    return resolveChildren(seq, allItems)
        .every((child) => child.completedForToday);
  }

  static bool sequenceShouldShowInList(
      DailyThing seq, List<DailyThing> allItems) {
    if (seq.isDueToday) return true;
    return resolveChildren(seq, allItems)
        .any((child) => child.hasBeenDoneLiterallyToday);
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
