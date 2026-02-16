import 'package:daily_inc/src/models/daily_thing.dart';

/// Returns the list of items to display based on showItemsDueToday and hideWhenDone rules.
List<DailyThing> filterDisplayedItems({
  required List<DailyThing> allItems,
  required bool showItemsDueToday,
  required bool hideWhenDone,
  bool showArchivedItems = false,
}) {
  // First, determine all items that should be shown based on due status
  List<DailyThing> displayed = showItemsDueToday
      ? allItems.where((item) => item.shouldShowInList).toList()
      : List<DailyThing>.from(allItems);

  // Filter based on archived status
  displayed = displayed
      .where((item) => item.isArchived == showArchivedItems)
      .toList();

  // Then, apply the "hide when done" filter
  if (hideWhenDone) {
    displayed = displayed.where((item) {
      if (item.isSnoozedForToday) {
        return false; // Always hide snoozed items when this filter is on
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
