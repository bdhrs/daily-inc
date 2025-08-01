import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/core/missed_days_calculator.dart';

class IncrementCalculator {
  /// Calculate the daily increment value for a DailyThing
  static double calculateIncrement(DailyThing item) {
    if (item.duration <= 0) return 0.0;
    return (item.endValue - item.startValue) / item.duration;
  }

  /// Get the last completed date from history
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

  /// Calculate days missed since last entry
  static int calculateDaysMissed(DateTime lastEntryDate, DateTime todayDate) {
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    return daysSinceLastEntry - 1; // Subtract 1 to get missed days
  }

  /// Calculate today's target value with proper increment logic
  static double calculateTodayValue(DailyThing item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final increment = calculateIncrement(item);


    // Sort history by date (newest first)
    final sortedHistory = List<HistoryEntry>.from(item.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Check for today's entry first
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {

        if (item.itemType == ItemType.check) {
          return entry.doneToday ? 1.0 : 0.0;
        }

        // For non-check items, return the target value from today's entry
        return entry.targetValue;
      }
    }

    // No entry for today - check if we should apply increment
    final lastCompleted = getLastCompletedDate(item.history);

    if (lastCompleted != null && lastCompleted.isBefore(todayDate)) {
      // There was a completion before today - check if we should apply increment

      // Find the last completed entry to get the base value
      HistoryEntry? lastCompletedEntry;
      for (final entry in sortedHistory) {
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (entry.doneToday && entryDate.isBefore(todayDate)) {
          lastCompletedEntry = entry;
          break;
        }
      }

      if (lastCompletedEntry != null) {
        final lastCompletedDate = DateTime(lastCompletedEntry.date.year,
            lastCompletedEntry.date.month, lastCompletedEntry.date.day);
        final daysSinceLastCompleted =
            todayDate.difference(lastCompletedDate).inDays;


        // Check frequency - if not due yet, don't increment
        if (daysSinceLastCompleted < item.frequencyInDays) {
          return lastCompletedEntry.targetValue;
        }

        // Handle special cases for missed days using the MissedDaysCalculator
        double? specialCaseValue;

        // Handle decreasing progression special case
        specialCaseValue = MissedDaysCalculator.handleDecreasingProgression(
          item,
          lastCompletedEntry,
          todayDate,
        );

        if (specialCaseValue != null) {
          return specialCaseValue;
        }

        // Handle increasing progression penalty
        specialCaseValue = MissedDaysCalculator.handleIncreasingProgression(
          item,
          lastCompletedEntry,
          todayDate,
          increment,
        );

        if (specialCaseValue != null) {
          return specialCaseValue;
        }

        // Handle decreasing progression penalty
        specialCaseValue = MissedDaysCalculator.handleDecreasingPenalty(
          item,
          lastCompletedEntry,
          todayDate,
          increment,
        );

        if (specialCaseValue != null) {
          return specialCaseValue;
        }

        // For all other cases, apply one increment
        // Apply increment based on progression direction
        double newValue;
        if (item.startValue < item.endValue) {
          // Increasing progression - add increment (which is positive)
          newValue = lastCompletedEntry.targetValue + increment;
          return newValue.clamp(item.startValue, item.endValue);
        } else {
          // Decreasing progression - add increment (which is negative)
          newValue = lastCompletedEntry.targetValue + increment;
          return newValue.clamp(item.endValue, item.startValue);
        }
      }
    }
    // No previous completion or no last entry - find the latest entry before today
    HistoryEntry? lastEntry;
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isBefore(todayDate)) {
        lastEntry = entry;
        break;
      }
    }

    if (lastEntry == null) {
      // No history before today - return start value
      return item.startValue;
    }

    final lastEntryDate =
        DateTime(lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    final daysMissed = calculateDaysMissed(lastEntryDate, todayDate);


    // Check frequency - if not due yet, don't change value
    if (daysSinceLastEntry < item.frequencyInDays) {
      return lastEntry.targetValue;
    }

    // Handle missed days logic
    if (lastEntry.doneToday) {
      if (daysMissed >= 2) {
        // Two or more days missed - apply exactly one increment
        return _applyIncrement(lastEntry.targetValue, increment, item);
      }
      // One day missed - no change to value
      return lastEntry.targetValue;
    }

    // If last entry was not done, apply same logic as missed days
    if (daysMissed >= 2) {
      return _applyIncrement(lastEntry.targetValue, increment, item);
    }

    return lastEntry.targetValue;
  }

  /// Apply increment with proper direction handling
  static double _applyIncrement(
      double currentValue, double increment, DailyThing item) {
    double newValue;
    if (item.startValue < item.endValue) {
      // Increasing progression - add increment
      newValue = currentValue + increment;
      return newValue.clamp(item.startValue, item.endValue);
    } else {
      // Decreasing progression - subtract increment
      newValue = currentValue - increment;
      return newValue.clamp(item.endValue, item.startValue);
    }
  }

  /// Calculate display value (shows actual value if entered today for reps)
  static double calculateDisplayValue(DailyThing item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // For REPS items, show actual value if entered today
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

    // For all item types, show today's target value when no actual progress is recorded
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
