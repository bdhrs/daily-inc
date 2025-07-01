import 'package:logging/logging.dart';

final Logger _logger = Logger('HistoryEntry');

class HistoryEntry {
  final DateTime date;
  final double targetValue; // Target value (non-nullable)
  final bool doneToday;
  final double? actualValue; // Actual performed value

  HistoryEntry({
    required this.date,
    required this.targetValue,
    required this.doneToday,
    this.actualValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'target_value': targetValue,
      'done_today': doneToday,
      'actual_value': actualValue,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    try {
      // Parse date with fallback to now
      DateTime date;
      try {
        date = DateTime.parse(json['date'] as String? ?? '');
      } catch (e) {
        date = DateTime.now();
      }

      // Parse targetValue with multiple fallbacks
      double targetValue;
      try {
        targetValue = double.tryParse(
                (json['target_value'] ?? json['value'] ?? 0.0).toString()) ??
            0.0;
      } catch (e) {
        targetValue = 0.0;
      }

      // Parse doneToday with fallback to false
      bool doneToday;
      try {
        doneToday = json['done_today'] as bool? ?? false;
      } catch (e) {
        doneToday = false;
      }

      // Parse actualValue (nullable)
      double? actualValue;
      try {
        actualValue = json['actual_value'] != null
            ? double.tryParse(json['actual_value'].toString())
            : null;
      } catch (e) {
        actualValue = null;
      }

      return HistoryEntry(
        date: date,
        targetValue: targetValue,
        doneToday: doneToday,
        actualValue: actualValue,
      );
    } catch (e) {
      _logger.warning('Error parsing HistoryEntry: $e');
      return HistoryEntry(
        date: DateTime.now(),
        targetValue: 0.0,
        doneToday: false,
        actualValue: null,
      );
    }
  }
}
