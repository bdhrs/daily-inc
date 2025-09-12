import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/core/time_converter.dart';

/// Helper class containing pure functions for timer calculations
class TimerLogicHelper {
  /// Calculates the current elapsed time in minutes based on timer state
  static double calculateCurrentElapsedTimeInMinutes({
    required bool isOvertime,
    required bool hasStarted,
    required double todaysTargetMinutes,
    required double remainingSeconds,
    required double overtimeSeconds,
    required DailyThing currentItem,
  }) {
    if (isOvertime) {
      final overtimeMinutes = overtimeSeconds / 60.0;
      return todaysTargetMinutes + overtimeMinutes;
    }

    if (hasStarted) {
      final elapsedSeconds = (todaysTargetMinutes * 60) - remainingSeconds;
      final sessionElapsedMinutes = elapsedSeconds / 60.0;
      return sessionElapsedMinutes;
    }

    // For non-started case, we need to check persisted value
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    HistoryEntry? todaysEntry;
    for (final entry in currentItem.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        todaysEntry = entry;
        break;
      }
    }

    return todaysEntry?.actualValue ?? 0.0;
  }

  /// Formats minutes to MM:SS string representation
  static String formatMinutesToMmSs(double minutesValue) {
    return TimeConverter.toMmSsString(minutesValue, padZeroes: true);
  }

  /// Calculates elapsed minutes in current subdivision
  static double calculateElapsedMinutesInCurrentSubdivision({
    required double currentElapsedTimeInMinutes,
    required int completedSubdivisions,
    required double todaysTargetMinutes,
    required int? subdivisions,
  }) {
    if (subdivisions == null || subdivisions <= 1) {
      return 0.0;
    }

    final double subdivisionDurationInMinutes =
        todaysTargetMinutes / subdivisions;
    final double elapsedMinutesInCompletedSubdivisions =
        completedSubdivisions * subdivisionDurationInMinutes;
    return currentElapsedTimeInMinutes - elapsedMinutesInCompletedSubdivisions;
  }

  /// Calculates total minutes in current subdivision
  static double calculateTotalMinutesInCurrentSubdivision({
    required double todaysTargetMinutes,
    required int? subdivisions,
  }) {
    if (subdivisions == null || subdivisions <= 1) {
      return 0.0;
    }

    return todaysTargetMinutes / subdivisions;
  }

  /// Calculates overtime minutes in current subdivision
  static double calculateOvertimeMinutesInCurrentSubdivision({
    required double overtimeSeconds,
    required double todaysTargetMinutes,
    required int? subdivisions,
  }) {
    if (subdivisions == null || subdivisions <= 1) {
      return 0.0;
    }

    final double subdivisionDurationInMinutes =
        todaysTargetMinutes / subdivisions;
    final double overtimeMinutes = overtimeSeconds / 60.0;
    return overtimeMinutes % subdivisionDurationInMinutes;
  }

  /// Finds today's history entry for the current item
  static HistoryEntry? findTodaysEntry(DailyThing currentItem) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final entry in currentItem.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        return entry;
      }
    }
    return null;
  }

  /// Calculates completed subdivisions based on elapsed time and target
  static int calculateCompletedSubdivisions({
    required double elapsedSeconds,
    required double totalSeconds,
    required int? subdivisions,
    required bool isOvertime,
  }) {
    if (subdivisions == null || subdivisions <= 1) {
      return 0;
    }

    final subdivisionInterval = totalSeconds / subdivisions;
    if (subdivisionInterval <= 0) {
      return 0;
    }

    if (isOvertime) {
      // In overtime mode, we can have more subdivisions than the original count
      final currentSubdivision = (elapsedSeconds / subdivisionInterval).floor();
      return currentSubdivision.clamp(
          0, subdivisions * 2); // Allow for overtime
    } else {
      // In normal mode, clamp to the original subdivision count minus 1
      final currentSubdivision = (elapsedSeconds / subdivisionInterval).floor();
      return currentSubdivision.clamp(0, subdivisions - 1);
    }
  }

  /// Calculates precise subdivision interval
  static double calculatePreciseSubdivisionInterval({
    required double totalSeconds,
    required int? subdivisions,
  }) {
    if (subdivisions == null || subdivisions <= 1) {
      return 0.0;
    }

    return totalSeconds / subdivisions;
  }

  /// Calculates last triggered subdivision
  static int calculateLastTriggeredSubdivision({
    required double preciseElapsedSeconds,
    required double preciseSubdivisionInterval,
  }) {
    if (preciseSubdivisionInterval <= 0) {
      return -1;
    }

    return (preciseElapsedSeconds / preciseSubdivisionInterval).floor();
  }
}
