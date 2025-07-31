import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';

final _logger = Logger('MissedDaysCalculator');

class MissedDaysCalculator {
  /// Calculate days missed since last entry
  static int calculateDaysMissed(DateTime lastEntryDate, DateTime todayDate) {
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    return daysSinceLastEntry - 1; // Subtract 1 to get missed days
  }

  /// Handle complex missed days logic for decreasing progressions
  static double? handleDecreasingProgression(
    DailyThing item,
    HistoryEntry lastCompletedEntry,
    DateTime todayDate,
  ) {
    final lastCompletedDate = DateTime(
      lastCompletedEntry.date.year,
      lastCompletedEntry.date.month,
      lastCompletedEntry.date.day,
    );

    // Special case: for DECREASING progressions only, if last completion was exactly 2 days ago,
    // yesterday was missed, AND frequency is 1 (daily), don't increment
    if (item.startValue > item.endValue &&
        todayDate.difference(lastCompletedDate).inDays == 2 &&
        item.frequencyInDays == 1) {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      bool yesterdayCompleted = false;

      for (final entry in item.history) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        if (entryDate == yesterday && entry.doneToday) {
          yesterdayCompleted = true;
          break;
        }
      }

      if (!yesterdayCompleted) {
        _logger.info(
          'DECREASING progression: last completion was 2 days ago, yesterday missed, and frequency is 1, returning last completed value without increment',
        );
        return lastCompletedEntry.targetValue;
      }
    }

    return null;
  }

  /// Handle complex missed days logic for increasing progressions
  static double? handleIncreasingProgression(
    DailyThing item,
    HistoryEntry lastCompletedEntry,
    DateTime todayDate,
    double increment,
  ) {
    final lastCompletedDate = DateTime(
      lastCompletedEntry.date.year,
      lastCompletedEntry.date.month,
      lastCompletedEntry.date.day,
    );

    // Special case: for INCREASING progressions with explicit missed day entries, apply one-day decrement penalty
    // Only apply penalty if more than one day was missed (grace period for one missed day)
    if (item.startValue < item.endValue &&
        todayDate.difference(lastCompletedDate).inDays > 2) {
      bool hasExplicitMissedDays = false;

      for (final entry in item.history) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        if (entryDate.isAfter(lastCompletedDate) &&
            entryDate.isBefore(todayDate) &&
            !entry.doneToday) {
          hasExplicitMissedDays = true;
          break;
        }
      }

      if (hasExplicitMissedDays) {
        _logger.info(
          'INCREASING progression with explicit missed day entries, applying one-day decrement penalty',
        );
        // Apply penalty: subtract one increment (decrement by one day)
        double newValue = lastCompletedEntry.targetValue - increment;
        return newValue.clamp(item.startValue, item.endValue);
      }
    }

    return null;
  }

  /// Handle missed days penalty for decreasing progressions
  static double? handleDecreasingPenalty(
    DailyThing item,
    HistoryEntry lastCompletedEntry,
    DateTime todayDate,
    double increment,
  ) {
    final lastCompletedDate = DateTime(
      lastCompletedEntry.date.year,
      lastCompletedEntry.date.month,
      lastCompletedEntry.date.day,
    );

    // Special case: for DECREASING progressions with explicit missed day entries, apply one-day increment penalty
    // Only apply penalty if more than one day was missed (grace period for one missed day)
    if (item.startValue > item.endValue &&
        todayDate.difference(lastCompletedDate).inDays > 2) {
      bool hasExplicitMissedDays = false;

      for (final entry in item.history) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        if (entryDate.isAfter(lastCompletedDate) &&
            entryDate.isBefore(todayDate) &&
            !entry.doneToday) {
          hasExplicitMissedDays = true;
          break;
        }
      }

      if (hasExplicitMissedDays) {
        _logger.info(
          'DECREASING progression with explicit missed day entries, applying one-day increment penalty',
        );
        // Apply penalty: add one increment (increment by one day - penalty goes upward)
        double newValue = lastCompletedEntry.targetValue - increment;
        return newValue.clamp(item.endValue, item.startValue);
      }
    }

    return null;
  }
}
