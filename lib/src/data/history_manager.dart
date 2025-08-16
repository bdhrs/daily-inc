import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';

final _logger = Logger('HistoryManager');

class HistoryManager {
  /// Update history entries with new progression parameters
  ///
  /// IMPORTANT: This method preserves historical target values and only updates
  /// target values for future dates. Historical target values should NEVER be
  /// rewritten as they represent what the target was on that specific day.
  static List<HistoryEntry> updateHistoryEntriesWithNewParameters({
    required List<HistoryEntry> history,
    required double newStartValue,
    required double newEndValue,
    required int newDuration,
    required DateTime newStartDate,
  }) {
    _logger.info('Updating history entries with new progression parameters');

    // Get today's date (without time) to determine what's historical vs future
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Calculate new increment
    final newIncrement =
        newDuration > 0 ? (newEndValue - newStartValue) / newDuration : 0.0;

    // Create updated history entries
    return history.map((entry) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);

      // Preserve historical entries unchanged - these should NEVER be rewritten
      if (entryDate.isBefore(todayDate)) {
        _logger.fine(
            'Preserving historical entry for ${entry.date} - target value: ${entry.targetValue}');
        return entry; // Return the original entry unchanged
      }

      // For today and future dates, update target values based on new parameters
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

      _logger.fine(
          'Updating future entry for ${entry.date} - old target: ${entry.targetValue}, new target: $newTargetValue');

      return HistoryEntry(
        date: entry.date,
        targetValue: newTargetValue,
        doneToday: entry.doneToday,
        actualValue: entry.actualValue,
        comment: entry.comment,
      );
    }).toList();
  }
}
