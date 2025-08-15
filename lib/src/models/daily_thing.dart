import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
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

  bool get isDueToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDone = lastCompletedDate;

    if (lastDone == null) {
      // If it's never been done, it's due if the start date is today or in the past.
      return !todayDate.isBefore(startDate);
    }

    if (intervalType == IntervalType.byDays) {
      final difference = todayDate.difference(lastDone).inDays;
      return difference >= intervalValue;
    } else {
      return intervalWeekdays.contains(todayDate.weekday);
    }
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
      'category': category,
      'isPaused': isPaused,
      'intervalType': intervalType.toString().split('.').last,
      'intervalValue': intervalValue,
      'intervalWeekdays': intervalWeekdays,
      'bellSoundPath': bellSoundPath, // Add to toJson
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
    );
  }
}
