import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';

class IncrementCalculator {
  static int _gracePeriodDays = 1; // Default to 1 day

  /// Set the grace period
  static void setGracePeriod(int days) {
    _gracePeriodDays = days;
  }

  /// Get the current grace period
  static int getGracePeriod() {
    return _gracePeriodDays;
  }

  /// Calculate the daily increment value for a DailyThing
  /// For frequency-based items, the increment is adjusted based on the interval
  static double calculateIncrement(DailyThing item) {
    if (item.duration <= 0) return 0.0;

    final double baseIncrement =
        (item.endValue - item.startValue) / item.duration;

    // For frequency-based items, adjust the increment to account for the interval
    if (item.intervalType == IntervalType.byDays && item.intervalValue > 1) {
      return baseIncrement * item.intervalValue;
    }

    return baseIncrement;
  }

  /// Get the last completed date from history (last day with doneToday == true)
  static DateTime? getLastCompletedDate(List<HistoryEntry> history) {
    final sortedHistory = List<HistoryEntry>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final entry in sortedHistory) {
      if (entry.doneToday) {
        return DateTime(entry.date.year, entry.date.month, entry.date.day);
      }
    }
    return null;
  }

  /// Get the date of the last entry (any entry irrespective of doneToday)
  static DateTime? getLastEntryDate(List<HistoryEntry> history) {
    if (history.isEmpty) return null;
    final sortedHistory = List<HistoryEntry>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));
    final e = sortedHistory.first;
    return DateTime(e.date.year, e.date.month, e.date.day);
  }

  /// Calculate days missed since last entry
  static int calculateDaysMissed(DateTime lastEntryDate, DateTime todayDate) {
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    return daysSinceLastEntry - 1; // Subtract 1 to get missed days
  }

  /// Determine if a task is due on a given date
  static bool isDue(DailyThing item, DateTime date) {
    final lastDone = getLastCompletedDate(item.history);

    if (lastDone == null) {
      // If never done, it's due if the start date is today or in the past
      return !date.isBefore(item.startDate);
    }

    // Check for missed days carry-over
    DateTime checkDate = DateTime(lastDone.year, lastDone.month, lastDone.day)
        .add(const Duration(days: 1));
    while (checkDate.isBefore(date) || checkDate.isAtSameMomentAs(date)) {
      bool wasDue = false;
      if (item.intervalType == IntervalType.byDays) {
        final daysDiff = checkDate.difference(lastDone).inDays;
        wasDue = daysDiff >= item.intervalValue;
      } else {
        // byWeekdays
        wasDue = item.intervalWeekdays.contains(checkDate.weekday);
      }

      if (wasDue) {
        // Check if it was done on that day
        final entryOnDay = item.history.where((e) {
          final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
          return entryDate.isAtSameMomentAs(checkDate);
        }).toList();

        if (entryOnDay.isEmpty || !entryOnDay.first.doneToday) {
          return true; // Carried over from a missed day
        }
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return false;
  }

  /// Calculate today's target value with increment/penalty based on days since last doneToday
  static double calculateTodayValue(DailyThing item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final increment = calculateIncrement(item);

    // If start date is today or in the future, return start value without increment
    final startDateOnly =
        DateTime(item.startDate.year, item.startDate.month, item.startDate.day);
    if (todayDate.isAtSameMomentAs(startDateOnly) ||
        todayDate.isBefore(startDateOnly)) {
      return item.startValue;
    }

    // Sort history by date (newest first)
    final sortedHistory = List<HistoryEntry>.from(item.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // If there's an entry for today, return its target (CHECK uses doneToday flag)
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        if (item.itemType == ItemType.check) {
          return entry.doneToday ? 1.0 : 0.0;
        }
        return entry.targetValue;
      }
    }

    // Identify last entry before today (for base target); if none, use startValue
    HistoryEntry? lastEntryBeforeToday;
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isBefore(todayDate)) {
        lastEntryBeforeToday = entry;
        break;
      }
    }
    final double baseTarget =
        lastEntryBeforeToday?.targetValue ?? item.startValue;

    // If item is paused, freeze today's target at baseTarget
    if (item.isPaused) {
      return baseTarget;
    }

    // If not due today, return the base target
    if (!isDue(item, todayDate)) {
      return baseTarget;
    }

    // Determine days since last doneToday
    final lastDoneDate = getLastCompletedDate(item.history);

    final int daysSinceDone = (lastDoneDate == null)
        ? todayDate
            .difference(DateTime(
                item.startDate.year, item.startDate.month, item.startDate.day))
            .inDays
        : todayDate.difference(lastDoneDate).inDays;

    // Apply spec from specs/increment_logic.md (days since doneToday)
    double newValue;
    if (daysSinceDone == 0) {
      // already done today
      newValue = baseTarget;
    } else if (daysSinceDone == 1) {
      // increment by increment
      newValue = baseTarget + increment;
    } else if (daysSinceDone <= getGracePeriod() + 1) {
      // Check if we're exactly on the frequency interval
      if (item.intervalType == IntervalType.byDays &&
          daysSinceDone == item.intervalValue) {
        // Exactly on frequency interval - increment
        newValue = baseTarget + increment;
      } else {
        // no change during grace period
        newValue = baseTarget;
      }
    } else {
      // after grace period: decrement by increment * (days - 1)
      final penalty = increment * (daysSinceDone - 1);
      newValue = baseTarget - penalty;
    }

    // Clamp with start anchored bound per spec
    // - if start < end: clamp to [startValue, endValue] (never below start)
    // - if start > end: clamp to [endValue, startValue] (never above start)
    final double minBound =
        item.startValue < item.endValue ? item.startValue : item.endValue;
    final double maxBound =
        item.startValue > item.endValue ? item.startValue : item.endValue;
    return newValue.clamp(minBound, maxBound);
  }

  // Note: _applyIncrementWithPenalty is no longer used; logic folded into calculateTodayValue

  /// Calculate display value
  ///
  /// Minutes (from docs/display_value.md):
  /// - If not yet started: show today's target value
  /// - If started and not completed: show time done (elapsed today)
  /// - If completed: show time done (elapsed today)
  ///
  /// Reps:
  /// - Show today's actual value if entered, otherwise today's target
  ///
  /// Check:
  /// - Delegates to today's target logic
  static double calculateDisplayValue(DailyThing item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Minutes logic per spec
    if (item.itemType == ItemType.minutes) {
      // Find today's entry (if any)
      final todaysEntry = item.history.firstWhere(
        (entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate == todayDate;
        },
        orElse: () => HistoryEntry(
          date: DateTime(0),
          targetValue: 0,
          doneToday: false,
        ),
      );

      final target = calculateTodayValue(item);
      final elapsed =
          todaysEntry.date.year != 0 ? (todaysEntry.actualValue ?? 0.0) : 0.0;

      // Not started: show today's target value
      if (elapsed <= 0.0) {
        return target;
      }

      // Started (and possibly completed): show time done (elapsed)
      return elapsed;
    }

    // Reps: show actual value if entered today
    if (item.itemType == ItemType.reps) {
      final todaysEntry = item.history.where((entry) {
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate == todayDate && entry.actualValue != null;
      }).toList();

      if (todaysEntry.isNotEmpty) {
        return todaysEntry.first.actualValue!;
      }
    }

    // Default: show today's target value
    return calculateTodayValue(item);
  }

  /// Determine if a task is done based on current value
  static bool isDone(DailyThing item, double currentValue) {
    if (item.itemType == ItemType.reps) {
      final increment = calculateIncrement(item);
      final todayValue = calculateTodayValue(item);

      if (increment > 0) {
        // For incrementing reps, done if current rounded is >= target rounded
        return currentValue.round() >= todayValue.round();
      } else if (increment < 0) {
        // For decrementing reps, done if current rounded is <= target rounded
        return currentValue.round() <= todayValue.round();
      } else {
        // No change case - done if currentValue equals today's value
        return currentValue.round() == todayValue.round();
      }
    }

    return determineStatus(item, currentValue) == Status.green;
  }

  /// Determine status (green/red) based on current value
  static Status determineStatus(DailyThing item, double currentValue) {
    final todayValue = calculateTodayValue(item);
    final increment = calculateIncrement(item);

    // For CHECK items, simple logic: green if checked (1.0), red if unchecked (0.0)
    if (item.itemType == ItemType.check) {
      return currentValue >= 1.0 ? Status.green : Status.red;
    }

    if (increment > 0) {
      // Incrementing case - green if currentValue meets or exceeds today's target
      return currentValue >= todayValue ? Status.green : Status.red;
    } else if (increment < 0) {
      // Decrementing case - green if currentValue meets or is below today's target
      return currentValue <= todayValue ? Status.green : Status.red;
    } else {
      // No change case - green if currentValue equals today's value
      return currentValue == todayValue ? Status.green : Status.red;
    }
  }
}

enum Status { green, red }
