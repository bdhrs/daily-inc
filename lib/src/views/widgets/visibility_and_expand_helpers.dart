import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

/// Returns the list of items to display based on showOnlyDueItems and hideWhenDone rules.
/// This mirrors the filtering logic currently used in DailyThingsView.
List<DailyThing> filterDisplayedItems({
  required List<DailyThing> allItems,
  required bool showOnlyDueItems,
  required bool hideWhenDone,
}) {
  List<DailyThing> displayed = showOnlyDueItems
      ? allItems
          .where((item) => item.isDueToday || item.hasBeenDoneLiterallyToday)
          .toList()
      : List<DailyThing>.from(allItems);

  if (hideWhenDone) {
    displayed = displayed.where((item) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (item.itemType == ItemType.reps) {
        final hasActualValueToday = item.history.any((entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate == todayDate && entry.actualValue != null;
        });
        return !hasActualValueToday;
      }

      if (item.itemType == ItemType.minutes) {
        final hasProgressToday = item.history.any((entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          if (entryDate != todayDate) return false;
          final actual = entry.actualValue ?? 0.0;
          return actual > 0.0 || entry.doneToday;
        });
        if (hasProgressToday) return false;
        return !item.completedForToday;
      }

      return !item.completedForToday;
    }).toList();
  }

  return displayed;
}

/// Toggles expansion for the provided visible items by updating isExpanded map.
/// Returns the new allExpanded state after toggling.
bool toggleExpansionForVisibleItems({
  required List<DailyThing> visibleItems,
  required Map<String, bool> isExpanded,
  required bool currentAllExpanded,
}) {
  // Determine if all currently visible are expanded
  final allExpandedNow =
      visibleItems.every((item) => isExpanded[item.id] ?? false);

  // Toggle target state
  final target = !allExpandedNow;

  for (final item in visibleItems) {
    isExpanded[item.id] = target;
  }

  return target;
}
