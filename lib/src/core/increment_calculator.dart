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

    _logger.info('Calculating todayValue for ${item.name}');
    _logger.info('Increment: $increment');
    _logger.info('Today date: $todayDate');

    // Sort history by date (newest first)
    final sortedHistory = List<HistoryEntry>.from(item.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Check for today's entry first
    for (final entry in sortedHistory) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        _logger.info('Found entry for today: target=${entry.targetValue}, done=${entry.doneToday}');
        
        if (item.itemType == ItemType.check) {
          return entry.doneToday ? 1.0 : 0.0;
        }

        // For non-check items, return the target value from today's entry
        return entry.targetValue;
      }
    }

    // No entry for today - check if we should apply increment
    final lastCompleted = getLastCompletedDate(item.history);
    _logger.info('Last completed date: $lastCompleted');

if (lastCompleted != null && lastCompleted.isBefore(todayDate)) {
      // There was a completion before today - check if we should apply increment
      _logger.info('Found previous completion, checking increment rules');
      
      // Find the last completed entry to get the base value
      HistoryEntry? lastCompletedEntry;
      for (final entry in sortedHistory) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (entry.doneToday && entryDate.isBefore(todayDate)) {
          lastCompletedEntry = entry;
          break;
        }
      }

      if (lastCompletedEntry != null) {
        final lastCompletedDate = DateTime(lastCompletedEntry.date.year, lastCompletedEntry.date.month, lastCompletedEntry.date.day);
        final daysSinceLastCompleted = todayDate.difference(lastCompletedDate).inDays;
        
        _logger.info('Last completed entry: target=${lastCompletedEntry.targetValue}, date=$lastCompletedDate');
        _logger.info('Days since last completed: $daysSinceLastCompleted');

        // Check frequency - if not due yet, don't increment
        if (daysSinceLastCompleted < item.frequencyInDays) {
          _logger.info('Not due yet (frequency: ${item.frequencyInDays}), returning last completed value');
          return lastCompletedEntry.targetValue;
        }

        // CORE LOGIC: Check if we should apply increment or penalty
        // Special case: for DECREASING progressions only, if last completion was exactly 2 days ago, 
        // yesterday was missed, AND frequency is 1 (daily), don't increment
        if (item.startValue > item.endValue && daysSinceLastCompleted == 2 && item.frequencyInDays == 1) {
          final yesterday = todayDate.subtract(const Duration(days: 1));
          bool yesterdayCompleted = false;
          for (final entry in item.history) {
            final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
            if (entryDate == yesterday && entry.doneToday) {
              yesterdayCompleted = true;
              break;
            }
          }
          
          if (!yesterdayCompleted) {
            _logger.info('DECREASING progression: last completion was 2 days ago, yesterday missed, and frequency is 1, returning last completed value without increment');
            return lastCompletedEntry.targetValue;
          }
        }
        
        // Special case: for INCREASING progressions with explicit missed day entries, apply one-day decrement penalty
        // Only apply penalty if more than one day was missed (grace period for one missed day)
        if (item.startValue < item.endValue && daysSinceLastCompleted > 2) {
          bool hasExplicitMissedDays = false;
          final lastCompletedDate = DateTime(lastCompletedEntry.date.year, lastCompletedEntry.date.month, lastCompletedEntry.date.day);
          
          for (final entry in item.history) {
            final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
            if (entryDate.isAfter(lastCompletedDate) && entryDate.isBefore(todayDate) && !entry.doneToday) {
              hasExplicitMissedDays = true;
              break;
            }
          }
          
          if (hasExplicitMissedDays) {
            _logger.info('INCREASING progression with explicit missed day entries, applying one-day decrement penalty');
            // Apply penalty: subtract one increment (decrement by one day)
            double newValue = lastCompletedEntry.targetValue - increment;
            return newValue.clamp(item.startValue, item.endValue);
          }
        }
        
        // Special case: for DECREASING progressions with explicit missed day entries, apply one-day increment penalty
        // Only apply penalty if more than one day was missed (grace period for one missed day)
        if (item.startValue > item.endValue && daysSinceLastCompleted > 2) {
          bool hasExplicitMissedDays = false;
          final lastCompletedDate = DateTime(lastCompletedEntry.date.year, lastCompletedEntry.date.month, lastCompletedEntry.date.day);
          
          for (final entry in item.history) {
            final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
            if (entryDate.isAfter(lastCompletedDate) && entryDate.isBefore(todayDate) && !entry.doneToday) {
              hasExplicitMissedDays = true;
              break;
            }
          }
          
          if (hasExplicitMissedDays) {
            _logger.info('DECREASING progression with explicit missed day entries, applying one-day increment penalty');
            // Apply penalty: add one increment (increment by one day - penalty goes upward)
            double newValue = lastCompletedEntry.targetValue - increment; // increment is negative for decreasing, so subtracting it adds value
            return newValue.clamp(item.endValue, item.startValue);
          }
        }
        
        // For all other cases, apply one increment
        _logger.info('Applying one increment');
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
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isBefore(todayDate)) {
        lastEntry = entry;
        break;
      }
    }

    if (lastEntry == null) {
      // No history before today - return start value
      _logger.info('No history before today, returning start value: ${item.startValue}');
      return item.startValue;
    }

    final lastEntryDate = DateTime(lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    final daysMissed = calculateDaysMissed(lastEntryDate, todayDate);

    _logger.info('Last entry before today: target=${lastEntry.targetValue}, date=$lastEntryDate');
    _logger.info('Days since last entry: $daysSinceLastEntry, days missed: $daysMissed');

    // Check frequency - if not due yet, don't change value
    if (daysSinceLastEntry < item.frequencyInDays) {
      _logger.info('Not due yet (frequency: ${item.frequencyInDays}), returning last value');
      return lastEntry.targetValue;
    }

    // Handle missed days logic
    if (lastEntry.doneToday) {
      if (daysMissed >= 2) {
        // Two or more days missed - apply exactly one increment
        _logger.info('2+ days missed, applying one increment');
        return _applyIncrement(lastEntry.targetValue, increment, item);
      }
      // One day missed - no change to value
      _logger.info('1 day missed, no increment applied');
      return lastEntry.targetValue;
    }

    // If last entry was not done, apply same logic as missed days
    if (daysMissed >= 2) {
      _logger.info('2+ days missed with incomplete entry, applying one increment');
      return _applyIncrement(lastEntry.targetValue, increment, item);
    }
    
    _logger.info('No increment needed, returning last value');
    return lastEntry.targetValue;
  }

  /// Apply increment with proper direction handling
  static double _applyIncrement(double currentValue, double increment, DailyThing item) {
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
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
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