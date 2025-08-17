enum IntervalType { byDays, byWeekdays }

enum TimeRange {
  oneWeek,
  twoWeeks,
  fourWeeks,
  eightWeeks,
  twelveWeeks,
  sixteenWeeks,
  all,
}

extension TimeRangeExtension on TimeRange {
  String get name {
    switch (this) {
      case TimeRange.oneWeek:
        return '1 Week';
      case TimeRange.twoWeeks:
        return '2 Weeks';
      case TimeRange.fourWeeks:
        return '4 Weeks';
      case TimeRange.eightWeeks:
        return '8 Weeks';
      case TimeRange.twelveWeeks:
        return '12 Weeks';
      case TimeRange.sixteenWeeks:
        return '16 Weeks';
      case TimeRange.all:
        return 'All';
    }
  }

  DateTime getStartDate(DateTime today) {
    switch (this) {
      case TimeRange.oneWeek:
        // Get the date 7 days ago
        return DateTime(today.year, today.month, today.day - 6);
      case TimeRange.twoWeeks:
        // Get the date 14 days ago
        return DateTime(today.year, today.month, today.day - 13);
      case TimeRange.fourWeeks:
        // Get the date 28 days ago
        return DateTime(today.year, today.month, today.day - 27);
      case TimeRange.eightWeeks:
        // Get the date 56 days ago (8 weeks)
        return DateTime(today.year, today.month, today.day - 55);
      case TimeRange.twelveWeeks:
        // Get the date 84 days ago (12 weeks)
        return DateTime(today.year, today.month, today.day - 83);
      case TimeRange.sixteenWeeks:
        // Get the date 112 days ago (16 weeks)
        return DateTime(today.year, today.month, today.day - 111);
      case TimeRange.all:
        // Return a very early date to include all data
        return DateTime(2000, 1, 1);
    }
  }
}
