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

  /// Calculate today's target value with increment/penalty based on days since last doneToday
  static double calculateTodayValue(DailyThing item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final increment = calculateIncrement(item);

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

    // Determine days since last doneToday
    final lastDoneDate = getLastCompletedDate(item.history);
    final int daysSinceDone = (lastDoneDate == null)
        ? todayDate
            .difference(DateTime(
                item.startDate.year, item.startDate.month, item.startDate.day))
            .inDays
        : todayDate.difference(lastDoneDate).inDays;

    // Respect frequency: if not due yet, keep base target
    if (lastEntryBeforeToday != null) {
      final lastEntryDate = DateTime(lastEntryBeforeToday.date.year,
          lastEntryBeforeToday.date.month, lastEntryBeforeToday.date.day);
      final gapFromLastEntry = todayDate.difference(lastEntryDate).inDays;
      if (gapFromLastEntry < item.frequencyInDays) {
        return baseTarget;
      }
    }

    // Apply spec from specs/increment_logic.md (days since doneToday)
    double newValue;
    if (daysSinceDone == 0) {
      // already done today
      newValue = baseTarget;
      _logger
          .info('No change (already done today) for "${item.name}": $newValue');
    } else if (daysSinceDone == 1) {
      // increment by increment
      newValue = baseTarget + increment;
      _logger.info('Increment (+$increment) for "${item.name}": $newValue');
    } else if (daysSinceDone == 2) {
      // no change
      newValue = baseTarget;
      _logger
          .info('No change (2 days since done) for "${item.name}": $newValue');
    } else {
      // 3+ days: decrement by increment * (days - 1)
      final penalty = increment * (daysSinceDone - 1);
      newValue = baseTarget - penalty;
      _logger.info(
          'Penalty (${daysSinceDone - 1} * $increment = $penalty) for "${item.name}": $newValue');
    }

    // Clamp within [startValue, endValue] inclusive
    if (item.startValue < item.endValue) {
      return newValue.clamp(item.startValue, item.endValue);
    } else {
      return newValue.clamp(item.endValue, item.startValue);
    }
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
