import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

class ValueConverter {
  static DailyThing convert(DailyThing original, ItemType newType) {
    if (original.itemType == newType) {
      return original;
    }

    double convertValue(double value) {
      // From check to anything else
      if (original.itemType == ItemType.check) {
        return value; // 0 or 1, no change needed
      }
      // From percentage to anything else
      if (original.itemType == ItemType.percentage) {
        // Convert percentage (0-100) to other types
        if (newType == ItemType.check) {
          return value >= 100 ? 1.0 : 0.0; // 100% = done, else not done
        }
        // For minutes/reps, scale percentage to a reasonable value
        return value; // Keep as is for now (percentage value as minutes/reps)
      }
      // From trend to anything else
      if (original.itemType == ItemType.trend) {
        if (newType == ItemType.check) {
          return value == 1.0 ? 1.0 : 0.0; // Improving -> done
        }
        return value == 1.0 ? 1.0 : 0.0; // Improving -> 1, else 0
      }
      // From minutes/reps to check
      if (newType == ItemType.check) {
        return value != 0 ? 1.0 : 0.0;
      }
      // From minutes/reps to percentage
      if (newType == ItemType.percentage) {
        // Convert minutes/reps to percentage (0-100)
        // For now, treat any non-zero value as 100%, zero as 0%
        return value != 0 ? 100.0 : 0.0;
      }
      // To trend from other types
      if (newType == ItemType.trend) {
        if (original.itemType == ItemType.check) {
          return value == 1.0
              ? 1.0
              : 0.0; // Done -> improving, not done -> same
        }
        return value != 0 ? 1.0 : 0.0; // non-zero -> improving, zero -> same
      }
      // For all other conversions (minutes <-> reps)
      return value;
    }

    return DailyThing(
      id: original.id,
      icon: original.icon,
      name: original.name,
      itemType: newType,
      startDate: original.startDate,
      startValue: convertValue(original.startValue),
      duration: original.duration,
      endValue: convertValue(original.endValue),
      history: original.history,
      nagTime: original.nagTime,
      nagMessage: original.nagMessage,
      category: original.category,
      isPaused: original.isPaused,
      intervalType: original.intervalType,
      intervalValue: original.intervalValue,
      intervalWeekdays: original.intervalWeekdays,
      bellSoundPath: original.bellSoundPath,
      subdivisions: original.subdivisions,
      subdivisionBellSoundPath: original.subdivisionBellSoundPath,
      notes: original.notes,
      isArchived: original.isArchived,
      notificationEnabled: original.notificationEnabled,
    );
  }
}
