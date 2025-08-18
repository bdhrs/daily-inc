import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

/// Returns the list of items to display based on showItemsDueToday and hideWhenDone rules.
List<DailyThing> filterDisplayedItems({
  required List<DailyThing> allItems,
  required bool showItemsDueToday,
  required bool hideWhenDone,
}) {
  // First, determine all items that should be shown based on due status
  List<DailyThing> displayed = showItemsDueToday
      ? allItems.where((item) => item.shouldShowInList).toList()
      : List<DailyThing>.from(allItems);

  // Then, apply the "hide when done" filter
  if (hideWhenDone) {
    displayed = displayed.where((item) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // For REPS items, hide when any actual value has been entered today
      if (item.itemType == ItemType.reps) {
        final hasActualValueToday = item.history.any((entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate == todayDate && entry.actualValue != null;
        });
        return !hasActualValueToday;
      }

      // For MINUTES items, hide when there is any progress today (partial or completed)
      if (item.itemType == ItemType.minutes) {
        final hasProgressToday = item.history.any((entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          if (entryDate != todayDate) return false;
          final actual = entry.actualValue ?? 0.0;
          return actual > 0.0 || entry.doneToday;
        });
        if (hasProgressToday) return false; // hide minutes if partial or done
        return !item.completedForToday;
      }

      // For CHECK items, maintain existing behavior
      return !item.completedForToday;
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
