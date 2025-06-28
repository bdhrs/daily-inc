import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:uuid/uuid.dart';

class DailyThing {
  final String id;
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
    final historyUpToToday = history
        .where((entry) => !entry.date.isAfter(todayDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double currentValueBase = startValue;
    DateTime lastRecordedDate = startDate;

    if (historyUpToToday.isNotEmpty) {
      final latestEntry = historyUpToToday.first;
      currentValueBase = latestEntry.value;
      lastRecordedDate = latestEntry.date;
      if (lastRecordedDate == todayDate) {
        return latestEntry.value;
      }
    }

    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (lastRecordedDate == yesterday) {
      final yesterdaysActualValue = currentValueBase;
      final yesterdaysTargetValue = _getTargetValueForDate(yesterday);
      final isIncreasing = endValue > startValue;
      final goalMet = isIncreasing
          ? yesterdaysActualValue >= yesterdaysTargetValue
          : yesterdaysActualValue <= yesterdaysTargetValue;
      return goalMet
          ? yesterdaysActualValue + increment
          : yesterdaysActualValue;
    }

    final daysSinceLastDoing = todayDate.difference(lastRecordedDate).inDays;
    double calculatedValue;

    if (daysSinceLastDoing <= 1) {
      calculatedValue = currentValueBase;
    } else if (daysSinceLastDoing == 2) {
      calculatedValue = currentValueBase;
    } else {
      calculatedValue =
          currentValueBase - (increment * (daysSinceLastDoing - 2));
    }

    return calculatedValue > startValue ? calculatedValue : startValue;
  }

  double _getTargetValueForDate(DateTime specificDate) {
    if (specificDate.isBefore(startDate)) return startValue;
    if (duration <= 0) return endValue;

    final daysSinceStart = specificDate.difference(startDate).inDays;
    if (daysSinceStart >= duration) return endValue;

    return startValue + (increment * daysSinceStart);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
