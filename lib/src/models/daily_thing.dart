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
        try {
          return entry.targetValue;
        } catch (e) {
          _logger.severe('Error getting targetValue from entry: $e');
          return 0.0;
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

    final yesterday = todayDate.subtract(const Duration(days: 1));
    final lastEntryDate =
        DateTime(lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);

    if (lastEntryDate == yesterday) {
      if (lastEntry.doneToday) {
        final newValue = lastEntry.targetValue + increment;
        // For decreasing items, today's target is the minimum of:
        // 1. Previous value + increment (decreasing)
        // 2. But not less than endValue
        if (increment < 0) {
          return newValue.clamp(endValue, startValue);
        }
        // For increasing items, today's target is the maximum of:
        // 1. Previous value + increment (increasing)
        // 2. But not more than endValue
        return newValue.clamp(startValue, endValue);
      }
    }

    // If last entry was not yesterday, or was yesterday but not done, value stays the same.
    return lastEntry.targetValue;
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

  bool get isDoneToday {
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
      // Use the isDone method with the actual or target value from today's entry
      // This will correctly apply the specific logic for REPS, MINUTES, and CHECK
      return isDone(todayEntry.actualValue ?? todayEntry.targetValue);
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
    );
  }
}
