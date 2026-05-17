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

  static ({double start, double end, double increment, int count})
      sumMinutesChildren(DailyThing seq, List<DailyThing> allItems) {
    final children = resolveChildren(seq, allItems)
        .where((c) => c.itemType == ItemType.minutes)
        .toList();
    double start = 0, end = 0, increment = 0;
    for (final c in children) {
      start += c.startValue;
      end += c.endValue;
      increment += c.increment;
    }
    return (
      start: start,
      end: end,
      increment: increment,
      count: children.length
    );
  }

  /// True if [item] is already completed today, or actively in-progress today.
  /// Used to suppress nag notifications for items the user has already engaged with.
  static bool isHandledToday(DailyThing item, List<DailyThing> allItems) {
    if (item.itemType == ItemType.sequence) {
      if (sequenceCompletedForToday(item, allItems)) return true;
      final children = resolveChildren(item, allItems);
      for (final child in children) {
        final entry = child.todayHistoryEntry;
        if (entry == null) continue;
        if (entry.doneToday) return true;
        if ((entry.actualValue ?? 0) > 0) return true;
      }
      return false;
    }

    if (item.hasBeenDoneLiterallyToday) return true;

    final entry = item.todayHistoryEntry;
    if (entry == null) return false;

    switch (item.itemType) {
      case ItemType.minutes:
        return (entry.actualValue ?? 0) > 0 && !entry.doneToday;
      case ItemType.reps:
        return entry.actualValue != null && !entry.doneToday;
      default:
        return false;
    }
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
