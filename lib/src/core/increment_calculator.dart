import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:logging/logging.dart';

final _logger = Logger('IncrementCalculator');

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

    // No entry for today - find the last relevant entry
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

    // Check frequency - if not due yet, don't change value
    if (daysSinceLastEntry < item.frequencyInDays) {
      return lastEntry.targetValue;
    }

    // Calculate days missed (adjusted for frequency)
    final daysMissed =
        _calculateDaysMissed(lastEntryDate, todayDate, item.frequencyInDays);

    // Apply increment logic with penalty
    return _applyIncrementWithPenalty(lastEntry, increment, daysMissed, item);
  }

  /// Calculate days missed since last entry, adjusted for frequency
  static int _calculateDaysMissed(
      DateTime lastEntryDate, DateTime todayDate, int frequencyInDays) {
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;

    // Calculate how many frequency periods have passed
    final periodsPassed = (daysSinceLastEntry / frequencyInDays).floor();

    // Return the number of missed days (0 if no periods have passed)
    return periodsPassed > 0 ? periodsPassed : 0;
  }

  /// Apply increment with penalty logic
  static double _applyIncrementWithPenalty(HistoryEntry lastEntry,
      double increment, int daysMissed, DailyThing item) {
    // Base value is the target value from the last entry
    double baseValue = lastEntry.targetValue;

    double newValue;

    // Apply penalty logic
    if (daysMissed == 0) {
      // No days missed - apply normal daily increment
      newValue = baseValue + increment;
      _logger.info(
          'Normal increment applied for item "${item.name}": $increment, new target value: $newValue');
    } else if (daysMissed == 1) {
      // One day missed - no change to target value (keep the last completed value)
      newValue = baseValue;
      _logger.info(
          'One day missed for item "${item.name}" - keeping target value at $baseValue');
    } else {
      // Two or more days missed - apply daily increment + penalty decrement
      // Apply normal increment first
      newValue = baseValue + increment;
      // Then apply penalty decrement for each additional missed day beyond the first
      double penalty = -increment * (daysMissed - 1);
      newValue = newValue + penalty;
      _logger.info(
          'Penalty applied for item "${item.name}": $daysMissed days missed, increment: $increment, penalty: $penalty, new target value: $newValue');
    }

    // Clamp to appropriate bounds
    if (item.startValue < item.endValue) {
      return newValue.clamp(item.startValue, item.endValue);
    } else {
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
