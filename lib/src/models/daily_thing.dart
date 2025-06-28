import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:uuid/uuid.dart';

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
        return entry.value;
      }
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
      return startValue;
    }

    final yesterday = todayDate.subtract(const Duration(days: 1));
    final lastEntryDate =
        DateTime(lastEntry.date.year, lastEntry.date.month, lastEntry.date.day);

    if (lastEntryDate == yesterday) {
      if (lastEntry.doneToday) {
        final newValue = lastEntry.value + increment;
        // Clamp value within bounds
        if (endValue >= startValue) {
          return newValue.clamp(startValue, endValue);
        } else {
          return newValue.clamp(endValue, startValue);
        }
      }
    }

    // If last entry was not yesterday, or was yesterday but not done, value stays the same.
    return lastEntry.value;
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
      history: (json['history'] as List<dynamic>)
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      nagTime: json['nagTime'] == null
          ? null
          : DateTime.parse(json['nagTime'] as String),
      nagMessage: json['nagMessage'] as String?,
    );
  }
}
