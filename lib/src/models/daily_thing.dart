import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/models/status.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final _logger = Logger('DailyThing');

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
  final String category; // New category field
  final bool isPaused; // Whether increment progression is paused
  double? actualTodayValue; // New property to store actual value entered today
  final IntervalType intervalType;
  final int intervalValue;
  final List<int> intervalWeekdays;
  final String? bellSoundPath; // New field for bell sound path
  final int? subdivisions;
  final String? subdivisionBellSoundPath;
  final String? notes;
  final bool isArchived; // New field for archive status
  final bool notificationEnabled; // Enable nag notifications

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
    this.category = 'None',
    this.isPaused = false,
    this.intervalType = IntervalType.byDays,
    this.intervalValue = 1,
    this.intervalWeekdays = const [],
    this.bellSoundPath, // Initialize new field
    this.subdivisions,
    this.subdivisionBellSoundPath,
    this.notes,
    this.isArchived = false, // Default to false
    this.notificationEnabled = false, // Default to false
  }) : id = id ?? const Uuid().v4();

  double get increment {
    return IncrementCalculator.calculateIncrement(this);
  }

  double get todayValue {
    return IncrementCalculator.calculateTodayValue(this);
  }

  double get displayValue {
    return IncrementCalculator.calculateDisplayValue(this);
  }

  Status determineStatus(double currentValue) {
    return IncrementCalculator.determineStatus(this, currentValue);
  }

  bool isDone(double currentValue) {
    return IncrementCalculator.isDone(this, currentValue);
  }

  DateTime? get lastCompletedDate {
    return IncrementCalculator.getLastCompletedDate(history);
  }

  HistoryEntry? get todayHistoryEntry {
    final todayDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return history.cast<HistoryEntry?>().firstWhere(
          (entry) =>
              entry != null &&
              DateTime(entry.date.year, entry.date.month, entry.date.day) ==
                  todayDate,
          orElse: () => null,
        );
  }

  bool get isSnoozedForToday {
    return todayHistoryEntry?.snoozed ?? false;
  }

  bool get isDueToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDone = lastCompletedDate;

    if (intervalType == IntervalType.byDays) {
      if (lastDone == null) {
        // If it's never been done, it's due if the start date is today or in the past.
        return !todayDate.isBefore(startDate);
      }

      final difference = todayDate.difference(lastDone).inDays;
      return difference >= intervalValue;
    } else {
      // For weekday-based items, check if today is one of the selected weekdays
      if (!intervalWeekdays.contains(todayDate.weekday)) {
        return false; // Not scheduled for today
      }

      // If it's never been done, it's due if the start date is today or in the past
      if (lastDone == null) {
        return !todayDate.isBefore(startDate);
      }

      // Find the most recent completion date that matches one of the selected weekdays
      DateTime? lastMatchingWeekdayCompletion;
      for (final entry in history.where((e) => e.doneToday)) {
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (intervalWeekdays.contains(entryDate.weekday)) {
          if (lastMatchingWeekdayCompletion == null ||
              entryDate.isAfter(lastMatchingWeekdayCompletion)) {
            lastMatchingWeekdayCompletion = entryDate;
          }
        }
      }

      // If never completed on a matching weekday, it's due today
      if (lastMatchingWeekdayCompletion == null) {
        return true;
      }

      // Check if at least one week has passed since the last completion on a matching weekday
      final weeksSinceLastCompletion =
          todayDate.difference(lastMatchingWeekdayCompletion).inDays ~/ 7;
      return weeksSinceLastCompletion >= 1;
    }
  }

  bool get completedForToday {
    // If it's due today, check if it has been done today
    if (isDueToday) {
      return hasBeenDoneLiterallyToday;
    }

    // If it's not due today, check if it was due previously but not completed
    // For items that were due previously but not completed, they should not be considered "completed for today"
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (IncrementCalculator.isDue(this, todayDate)) {
      // It was due previously but not completed, so it's not completed for today
      return false;
    }

    // If it's not due today and was not due previously, then it's completed for today
    return true;
  }

  bool get hasBeenDoneLiterallyToday {
    return todayHistoryEntry?.doneToday ?? false;
  }

  /// Determines if this item should be shown in the list.
  ///
  /// An item should be shown if:
  /// 1. It is due today ([isDueToday])
  /// 2. It has been done today ([hasBeenDoneLiterallyToday])
  /// 3. It was due previously but not yet completed (carry-over items)
  bool get shouldShowInList {
    // If it's due today or has been done today, it should be shown
    if (isDueToday || hasBeenDoneLiterallyToday) {
      return true;
    }

    // For items that were due previously but not completed, they should also be shown
    // We'll use the isDue method from IncrementCalculator to check this
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return IncrementCalculator.isDue(this, todayDate);
  }

  Map<String, dynamic> toJson({bool includeHistory = true}) {
    return {
      'id': id,
      'icon': icon,
      'name': name,
      'itemType': itemType.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'startValue': startValue,
      'duration': duration,
      'endValue': endValue,
      if (includeHistory)
        'history': history.map((entry) => entry.toJson()).toList(),
      'nagTime': nagTime?.toIso8601String(),
      'nagMessage': nagMessage,
      'category': category,
      'isPaused': isPaused,
      'intervalType': intervalType.toString().split('.').last,
      'intervalValue': intervalValue,
      'intervalWeekdays': intervalWeekdays,
      'bellSoundPath': bellSoundPath, // Add to toJson
      'subdivisions': subdivisions,
      'subdivisionBellSoundPath': subdivisionBellSoundPath,
      'notes': notes,
      'isArchived': isArchived, // Add to toJson
      'notificationEnabled': notificationEnabled,
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
      category:
          json['category'] as String? ?? 'None', // Backwards compatibility
      isPaused: json['isPaused'] as bool? ?? false,
      intervalType: json['intervalType'] == null
          ? IntervalType.byDays
          : IntervalType.values.firstWhere(
              (e) => e.toString().split('.').last == json['intervalType']),
      intervalValue:
          json['intervalValue'] as int? ?? json['frequencyInDays'] as int? ?? 1,
      intervalWeekdays: json['intervalWeekdays'] == null
          ? []
          : List<int>.from(json['intervalWeekdays']),
      bellSoundPath: json['bellSoundPath'] as String?, // Add to fromJson
      subdivisions: json['subdivisions'] as int?,
      subdivisionBellSoundPath: json['subdivisionBellSoundPath'] as String?,
      notes: json['notes'] as String?,
      isArchived:
          json['isArchived'] as bool? ?? false, // Add to fromJson with default
      notificationEnabled:
          json['notificationEnabled'] as bool? ?? false, // Backwards compatible
    );
  }

  DailyThing copyWith({
    String? id,
    String? icon,
    String? name,
    ItemType? itemType,
    DateTime? startDate,
    double? startValue,
    int? duration,
    double? endValue,
    List<HistoryEntry>? history,
    DateTime? nagTime,
    String? nagMessage,
    String? category,
    bool? isPaused,
    IntervalType? intervalType,
    int? intervalValue,
    List<int>? intervalWeekdays,
    String? bellSoundPath, // Add to copyWith
    int? subdivisions,
    String? subdivisionBellSoundPath,
    String? notes,
    bool? isArchived, // Add to copyWith
    bool? notificationEnabled,
  }) {
    return DailyThing(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      startDate: startDate ?? this.startDate,
      startValue: startValue ?? this.startValue,
      duration: duration ?? this.duration,
      endValue: endValue ?? this.endValue,
      history: history ?? this.history,
      nagTime: nagTime ?? this.nagTime,
      nagMessage: nagMessage ?? this.nagMessage,
      category: category ?? this.category,
      isPaused: isPaused ?? this.isPaused,
      intervalType: intervalType ?? this.intervalType,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalWeekdays: intervalWeekdays ?? this.intervalWeekdays,
      bellSoundPath: bellSoundPath ?? this.bellSoundPath, // Use new field
      subdivisions: subdivisions ?? this.subdivisions,
      subdivisionBellSoundPath:
          subdivisionBellSoundPath ?? this.subdivisionBellSoundPath,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived, // Use new field
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
