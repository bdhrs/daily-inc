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
      // From minutes/reps to check
      if (newType == ItemType.check) {
        return value != 0 ? 1.0 : 0.0;
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
    );
  }
}
