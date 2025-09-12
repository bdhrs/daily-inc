import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:flutter/material.dart';

/// Helper class for managing complex state transitions in the timer
class TimerStateHelper {
  /// Initializes timer state based on today's history entry
  static Map<String, dynamic> initializeTimerState({
    required DailyThing item,
    required bool startInOvertime,
    required TextEditingController commentController,
    required DailyThing currentItem,
  }) {
    // Initialize target values first
    final double todaysTargetMinutes = item.todayValue;
    final double initialTargetSeconds = todaysTargetMinutes * 60;

    // Initialize state variables
    bool isOvertime = false;
    bool isPaused = true;
    bool hasStarted = false;
    double remainingSeconds = initialTargetSeconds;
    double overtimeSeconds = 0.0;
    int completedSubdivisions = 0;

    if (startInOvertime) {
      isOvertime = true;
      isPaused = true;
      hasStarted = true;
    }

    final todayDate = DateUtils.dateOnly(DateTime.now());
    HistoryEntry? todayEntry;
    for (final entry in currentItem.history) {
      final entryDate = DateUtils.dateOnly(entry.date);
      if (entryDate == todayDate) {
        // Find any entry for today, regardless of completion state.
        // This is crucial for correctly resuming overtime.
        todayEntry = entry;
        break;
      }
    }

    if (todayEntry != null) {
      // Load existing comment
      if (todayEntry.comment != null && todayEntry.comment!.isNotEmpty) {
        commentController.text = todayEntry.comment!;
      }

      final dailyTarget = todaysTargetMinutes;
      final completedMinutes = todayEntry.actualValue ?? 0.0;
      // Use epsilon comparison to handle floating-point precision issues
      final epsilon = 0.0001; // Small tolerance for floating-point comparison
      if (startInOvertime ||
          (completedMinutes - dailyTarget).abs() < epsilon ||
          completedMinutes > dailyTarget) {
        isOvertime = true;
        isPaused = true;
        hasStarted = true;
        final overtimeMinutes = completedMinutes - dailyTarget;
        overtimeSeconds = (overtimeMinutes > 0) ? (overtimeMinutes * 60) : 0.0;
        remainingSeconds = 0.0;

        // Calculate completed subdivisions for overtime mode using precise floating-point
        if (currentItem.subdivisions != null && currentItem.subdivisions! > 1) {
          final totalSeconds = (todaysTargetMinutes * 60);
          final subdivisionInterval = totalSeconds / currentItem.subdivisions!;
          if (subdivisionInterval > 0) {
            final elapsedSeconds = totalSeconds + overtimeSeconds;
            // Use precise calculation to match the new timer logic
            completedSubdivisions = (elapsedSeconds / subdivisionInterval)
                .floor()
                .clamp(0, currentItem.subdivisions! * 2); // Allow for overtime
          }
        }
      } else {
        final remainingMinutes = dailyTarget - completedMinutes;
        remainingSeconds = (remainingMinutes * 60);
      }

      // Calculate already completed subdivisions using precise floating-point
      if (currentItem.subdivisions != null && currentItem.subdivisions! > 1) {
        final totalSeconds = (todaysTargetMinutes * 60);
        final subdivisionInterval = totalSeconds / currentItem.subdivisions!;
        if (subdivisionInterval > 0) {
          final elapsedSeconds = totalSeconds - remainingSeconds;
          // Use precise calculation to match the new timer logic
          completedSubdivisions = (elapsedSeconds / subdivisionInterval)
              .floor()
              .clamp(0, currentItem.subdivisions! - 1);
        }
      }
    }

    return {
      'todaysTargetMinutes': todaysTargetMinutes,
      'initialTargetSeconds': initialTargetSeconds,
      'isOvertime': isOvertime,
      'isPaused': isPaused,
      'hasStarted': hasStarted,
      'remainingSeconds': remainingSeconds,
      'overtimeSeconds': overtimeSeconds,
      'completedSubdivisions': completedSubdivisions,
    };
  }

  /// Updates timer state when timer completes
  static Map<String, dynamic> updateStateOnTimerComplete({
    required bool isOvertime,
    required int? subdivisions,
    required bool isPaused,
    required bool shouldFadeUI,
    required bool showNextTaskArrow,
    required int completedSubdivisions,
  }) {
    // Update UI state immediately to show completion
    isPaused = true;
    shouldFadeUI = false;
    if (subdivisions != null && subdivisions > 1) {
      completedSubdivisions = subdivisions;
    }

    // Show the next task arrow when timer completes
    showNextTaskArrow = true;

    return {
      'isPaused': isPaused,
      'shouldFadeUI': shouldFadeUI,
      'completedSubdivisions': completedSubdivisions,
      'showNextTaskArrow': showNextTaskArrow,
    };
  }

  /// Updates timer state when exiting timer display
  static Map<String, dynamic> updateStateOnExitTimerDisplay({
    required bool isPaused,
    required bool isOvertime,
    required bool hasStarted,
    required double remainingSeconds,
  }) {
    // Pause the timer and update the UI before showing any dialogs
    if (!isPaused) {
      isPaused = true;
    }

    return {
      'isPaused': isPaused,
    };
  }

  /// Updates timer state when toggling timer
  static Map<String, dynamic> updateStateOnToggleTimer({
    required bool isPaused,
    required bool hasStarted,
    required bool isOvertime,
    required double remainingSeconds,
    required bool dimScreenMode,
  }) {
    // Toggle the paused state
    isPaused = !isPaused;

    if (!isPaused) {
      hasStarted = true;

      final bool isFinished = remainingSeconds <= 0 && !isOvertime;
      if (isFinished && !isOvertime) {
        // Timer is finished, start overtime mode
        isOvertime = true;
      }
    }

    return {
      'isPaused': isPaused,
      'hasStarted': hasStarted,
      'isOvertime': isOvertime,
    };
  }

  /// Updates timer state when running countdown
  static Map<String, dynamic> updateStateOnRunCountdown({
    required double remainingSeconds,
    required double preciseElapsedSeconds,
    required double initialTargetSeconds,
  }) {
    // Decrement remaining seconds
    remainingSeconds -= 0.1; // 10ms decrements
    preciseElapsedSeconds = initialTargetSeconds - remainingSeconds;

    return {
      'remainingSeconds': remainingSeconds,
      'preciseElapsedSeconds': preciseElapsedSeconds,
    };
  }

  /// Updates timer state when running overtime
  static Map<String, dynamic> updateStateOnRunOvertime({
    required double overtimeSeconds,
    required double preciseElapsedSeconds,
    required double todaysTargetMinutes,
  }) {
    // Increment overtime seconds
    overtimeSeconds += 0.1; // 100ms increments
    preciseElapsedSeconds = (todaysTargetMinutes * 60) + overtimeSeconds;

    return {
      'overtimeSeconds': overtimeSeconds,
      'preciseElapsedSeconds': preciseElapsedSeconds,
    };
  }

  /// Finds the next undone task in the list
  static DailyThing? findNextUndoneTask({
    required List<DailyThing>? allItems,
    required int? currentItemIndex,
  }) {
    // If we don't have the full list or current index, we can't navigate
    if (allItems == null || currentItemIndex == null) {
      return null;
    }

    // Start from the next item
    for (int i = currentItemIndex + 1; i < allItems.length; i++) {
      final item = allItems[i];

      // Check if the item is undone based on its type
      switch (item.itemType) {
        case ItemType.check:
          if (!item.completedForToday) {
            return item;
          }
          break;
        case ItemType.reps:
          // For reps, check if no actual value has been entered today
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final hasActualValueToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate && entry.actualValue != null;
          });
          if (!hasActualValueToday) {
            return item;
          }
          break;
        case ItemType.minutes:
          // For minutes, check if not completed
          if (!item.completedForToday) {
            return item;
          }
          break;
        case ItemType.percentage:
          // For percentage, check if no entry for today or entry has 0 value
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final todayEntry = item.history.cast<HistoryEntry?>().firstWhere(
                (entry) =>
                    entry != null &&
                    DateTime(entry.date.year, entry.date.month,
                            entry.date.day) ==
                        todayDate,
                orElse: () => null,
              );
          if (todayEntry == null || (todayEntry.actualValue ?? 0) == 0) {
            return item;
          }
          break;
        case ItemType.trend:
          // For trend, check if no entry for today
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final hasEntryToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate;
          });
          if (!hasEntryToday) {
            return item;
          }
          break;
      }
    }

    // No more undone tasks
    return null;
  }
}
