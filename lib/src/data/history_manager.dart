import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';

final _logger = Logger('HistoryManager');

class HistoryManager {
  /// Update history entries with new progression parameters
  static List<HistoryEntry> updateHistoryEntriesWithNewParameters({
    required List<HistoryEntry> history,
    required double newStartValue,
    required double newEndValue,
    required int newDuration,
    required DateTime newStartDate,
  }) {
    _logger.info('Updating history entries with new progression parameters');

    // Calculate new increment
    final newIncrement =
        newDuration > 0 ? (newEndValue - newStartValue) / newDuration : 0.0;

    // Create updated history entries
    return history.map((entry) {
      // For entries that have actual values (reps), update their targetValue but keep actualValue
      if (entry.actualValue != null) {
        // Recalculate target value based on new parameters for this entry's date
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        final startDateOnly =
            DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
        final daysSinceStart = entryDate.difference(startDateOnly).inDays;

        double newTargetValue;
        if (daysSinceStart <= 0) {
          newTargetValue = newStartValue;
        } else if (daysSinceStart >= newDuration) {
          newTargetValue = newEndValue;
        } else {
          newTargetValue = newStartValue + (newIncrement * daysSinceStart);
        }

        return HistoryEntry(
          date: entry.date,
          targetValue: newTargetValue,
          doneToday: entry.doneToday,
          actualValue: entry.actualValue,
        );
      }

      // For entries without actual values, recalculate targetValue based on new parameters
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      final startDateOnly =
          DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
      final daysSinceStart = entryDate.difference(startDateOnly).inDays;

      double newTargetValue;
      if (daysSinceStart <= 0) {
        newTargetValue = newStartValue;
      } else if (daysSinceStart >= newDuration) {
        newTargetValue = newEndValue;
      } else {
        newTargetValue = newStartValue + (newIncrement * daysSinceStart);
      }

      return HistoryEntry(
        date: entry.date,
        targetValue: newTargetValue,
        doneToday: entry.doneToday,
        actualValue: entry.actualValue,
      );
    }).toList();
  }
}