import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final _logger = Logger('DailyThing');

enum Status { green, red }

class DailyThing {
  final String id;
  final String? icon;
  final String name;
  final ItemType itemType;
  final DateTime startDate;
  final double startValue;
  final int duration;
  final double endValue;
  final List<HistoryEntry> history;
  final DateTime? nagTime;
  final String? nagMessage;
  final int frequencyInDays;
  final String category; // New category field
  double? actualTodayValue; // New property to store actual value entered today

  DailyThing({
    String? id,
    this.icon,
    required this.name,
    required this.itemType,
    required this.startDate,
    required this.startValue,
    required this.duration,
    required this.endValue,
    this.history = const [],
    this.nagTime,
    this.nagMessage,
    this.frequencyInDays = 1,
    this.category = 'None', // Default category
  }) : id = id ?? const Uuid().v4();

  double get increment {
    if (duration <= 0) return 0.0;
    return (endValue - startValue) / duration;
  }

  double get todayValue {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final sortedHistory = List<HistoryEntry>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Check for today's entry
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        if (itemType == ItemType.check) {
          return entry.doneToday ? 1.0 : 0.0;
        }

        if (entryDate == todayDate) {
          if (itemType == ItemType.check) {
            return entry.doneToday ? 1.0 : 0.0;
          }
          // Return calculated target for today based on last completed entry
          final lastCompleted = lastCompletedDate;
          if (lastCompleted != null && lastCompleted.isBefore(todayDate)) {
            return entry.targetValue + increment;
          }
          return entry.targetValue;
        }
      }
    }

    // For CHECK items, if no entry for today, it's unchecked.
    if (itemType == ItemType.check) {
      return 0.0;
    }

    // No entry for today, find the latest entry before today
    HistoryEntry? lastEntry;
    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isBefore(todayDate)) {
        lastEntry = entry;
        break; // since it's sorted, first one is the latest
      }
    }

    if (lastEntry == null) {
      // No history before today
      try {
        return startValue;
      } catch (e) {
        _logger.warning('Error with startValue: $e');
        return 0.0;
      }
    }

    final lastEntryDate =
        DateTime(lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);

    final lastCompleted = lastCompletedDate;
    if (lastCompleted != null) {
      final difference = todayDate.difference(lastCompleted).inDays;
      if (difference > 0 && difference < frequencyInDays) {
        // Not due yet, value stays the same as the last entry.
        return lastEntry.targetValue;
      }
    }

    if (lastEntry.doneToday) {
      final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
      final daysMissed =
          daysSinceLastEntry - 1; // Subtract 1 to get missed days

      if (daysMissed >= 2) {
        // Two or more days missed - apply exactly one increment
        final newValue = startValue < endValue
            ? lastEntry.targetValue -
                increment // Decreasing for increasing progressions
            : lastEntry.targetValue +
                increment; // Increasing for decreasing progressions
        // Handle both increasing and decreasing progressions
        if (startValue < endValue) {
          return newValue.clamp(startValue, endValue);
        } else {
          return newValue.clamp(endValue, startValue);
        }
      }
      // One day missed - no change to value
      return lastEntry.targetValue;
    }

    // If last entry was not done, apply same logic as missed days
    final daysSinceLastEntry = todayDate.difference(lastEntryDate).inDays;
    final daysMissed = daysSinceLastEntry - 1; // Subtract 1 to get missed days

    if (daysMissed >= 2) {
      final newValue = startValue < endValue
          ? lastEntry.targetValue -
              increment // Decreasing for increasing progressions
          : lastEntry.targetValue +
              increment; // Increasing for decreasing progressions
      if (startValue < endValue) {
        return newValue.clamp(startValue, endValue);
      } else {
        return newValue.clamp(endValue, startValue);
      }
    }
    return lastEntry.targetValue;
  }

double get displayValue {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // For REPS items, show actual value if entered today
    if (itemType == ItemType.reps) {
      final todaysEntry = history.where((entry) {
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate == todayDate && entry.actualValue != null;
      }).toList();
      
      if (todaysEntry.isNotEmpty) {
        return todaysEntry.first.actualValue!;
      }
    }
    
    // For all item types, show today's target value when no actual progress is recorded
    return todayValue;
  }
  Status determineStatus(double currentValue) {
    // For CHECK items, simple logic: green if checked (1.0), red if unchecked (0.0)
    if (itemType == ItemType.check) {
      return currentValue >= 1.0 ? Status.green : Status.red;
    }

    if (increment > 0) {
      // Incrementing case - green if currentValue meets or exceeds today's target
      return currentValue >= todayValue ? Status.green : Status.red;
    } else if (increment < 0) {
      // Decrementing case - green if currentValue meets or is below today's target
      // For decreasing items, being above the target is bad (red)
      return currentValue <= todayValue ? Status.green : Status.red;
    } else {
      // No change case (increment == 0) - green if currentValue equals today's value
      return currentValue == todayValue ? Status.green : Status.red;
    }
  }

  bool isDone(double currentValue) {
    if (itemType == ItemType.reps) {
      if (increment > 0) {
        // For incrementing reps, done if current rounded is >= target rounded
        return currentValue.round() >= todayValue.round();
      } else if (increment < 0) {
        // For decrementing reps, done if current rounded is <= target rounded
        return currentValue.round() <= todayValue.round();
      } else {
        // No change case (increment == 0) - green if currentValue equals today's value
        return currentValue.round() == todayValue.round();
      }
    }
    return determineStatus(currentValue) == Status.green;
  }

  DateTime? get lastCompletedDate {
    final sortedHistory = List<HistoryEntry>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final entry in sortedHistory) {
      if (entry.doneToday) {
        return DateTime(entry.date.year, entry.date.month, entry.date.day);
      }
    }
    return null;
  }

  bool get isDueToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDone = lastCompletedDate;

    if (lastDone == null) {
      // If it's never been done, it's due if the start date is today or in the past.
      return !todayDate.isBefore(startDate);
    }

    final difference = todayDate.difference(lastDone).inDays;
    return difference >= frequencyInDays;
  }

  bool get completedForToday {
    if (!isDueToday) {
      return true;
    }
    return hasBeenDoneLiterallyToday;
  }

  bool get hasBeenDoneLiterallyToday {
    final todayDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Find the most recent entry for today
    HistoryEntry? todayEntry;
    for (final entry in history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        todayEntry = entry;
        break; // Found today's entry
      }
    }

    if (todayEntry != null) {
      return todayEntry.doneToday;
    }
    return false; // No entry for today, so not done today
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon,
      'name': name,
      'itemType': itemType.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'startValue': startValue,
      'duration': duration,
      'endValue': endValue,
      'history': history.map((entry) => entry.toJson()).toList(),
      'nagTime': nagTime?.toIso8601String(),
      'nagMessage': nagMessage,
      'frequencyInDays': frequencyInDays,
      'category': category,
    };
  }

  factory DailyThing.fromJson(Map<String, dynamic> json) {
    return DailyThing(
      id: json['id'] as String?,
      icon: json['icon'] as String?,
      name: json['name'] as String,
      itemType: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['itemType'],
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      startValue: (json['startValue'] as num).toDouble(),
      duration: json['duration'] as int,
      endValue: (json['endValue'] as num).toDouble(),
      history: () {
        try {
          final historyList = json['history'] as List<dynamic>? ?? [];
          return historyList.map((e) {
            try {
              return HistoryEntry.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              _logger.warning('Error parsing history entry: $e');
              return HistoryEntry(
                date: DateTime.now(),
                targetValue: 0.0,
                doneToday: false,
                actualValue: null,
              );
            }
          }).toList();
        } catch (e) {
          _logger.warning('Error parsing history list: $e');
          return <HistoryEntry>[];
        }
      }(),
      nagTime: json['nagTime'] == null
          ? null
          : DateTime.parse(json['nagTime'] as String),
      nagMessage: json['nagMessage'] as String?,
      frequencyInDays: json['frequencyInDays'] as int? ?? 1,
      category: json['category'] as String? ?? 'None', // Backwards compatibility
    );
  }
}
