import 'package:daily_inc/src/core/sequence_helper.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

/// Returns the list of items to display based on showItemsDueToday and hideWhenDone rules.
List<DailyThing> filterDisplayedItems({
  required List<DailyThing> allItems,
  required bool showItemsDueToday,
  required bool hideWhenDone,
  bool showArchivedItems = false,
}) {
  // First, determine all items that should be shown based on due status
  List<DailyThing> displayed = showItemsDueToday
      ? allItems.where((item) {
          if (item.itemType == ItemType.sequence) {
            return SequenceHelper.sequenceShouldShowInList(item, allItems);
          }
          return item.shouldShowInList;
        }).toList()
      : List<DailyThing>.from(allItems);

  // Filter based on archived status
  displayed = displayed
      .where((item) => item.isArchived == showArchivedItems)
      .toList();

  // Remove child items — they are rendered inline under their parent sequence
  displayed = displayed
      .where((item) =>
          SequenceHelper.findParentSequence(item, allItems) == null)
      .toList();

  // Then, apply the "hide when done" filter
  if (hideWhenDone) {
    displayed = displayed.where((item) {
      if (item.isSnoozedForToday) {
        return false;
      }
      if (item.itemType == ItemType.sequence) {
        return SequenceHelper.sequenceIsUndoneToday(item, allItems);
      }
      return item.isUndoneToday;
    }).toList();
  }

  return displayed;
}

/// Calculates the list of items that are due today for completion status calculation.
List<DailyThing> calculateDueItems({
  required List<DailyThing> allItems,
  required bool showItemsDueToday,
}) {
  return showItemsDueToday
      ? allItems.where((item) => item.shouldShowInList).toList()
      : allItems;
}
