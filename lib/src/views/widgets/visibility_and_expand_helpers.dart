import 'package:daily_inc/src/models/daily_thing.dart';

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
