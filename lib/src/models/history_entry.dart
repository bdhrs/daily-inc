import 'package:logging/logging.dart';

final Logger _logger = Logger('HistoryEntry');

class HistoryEntry {
  final DateTime date;
  final double targetValue; // Target value (non-nullable)
  final bool doneToday;
  final double? actualValue; // Actual performed value
  final String? comment;
  final bool snoozed;

  HistoryEntry({
    required this.date,
    required this.targetValue,
    required this.doneToday,
    this.actualValue,
    this.comment,
    this.snoozed = false,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'date': date.toIso8601String(),
      'target_value': targetValue,
      'done_today': doneToday,
      'actual_value': actualValue,
      'comment': comment,
      'snoozed': snoozed,
    };
    _logger.fine('HistoryEntry toJson: $json');
    return json;
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

      // Parse comment (nullable)
      final String? comment = json['comment'] as String?;

      // Parse snoozed with fallback to false
      final bool snoozed = json['snoozed'] as bool? ?? false;

      return HistoryEntry(
        date: date,
        targetValue: targetValue,
        doneToday: doneToday,
        actualValue: actualValue,
        comment: comment,
        snoozed: snoozed,
      );
    } catch (e) {
      _logger.warning('Error parsing HistoryEntry: $e');
      return HistoryEntry(
        date: DateTime.now(),
        targetValue: 0.0,
        doneToday: false,
        actualValue: null,
        comment: null,
        snoozed: false,
      );
    }
  }

  HistoryEntry copyWith({
    DateTime? date,
    double? targetValue,
    bool? doneToday,
    double? actualValue,
    String? comment,
    bool? snoozed,
  }) {
    return HistoryEntry(
      date: date ?? this.date,
      targetValue: targetValue ?? this.targetValue,
      doneToday: doneToday ?? this.doneToday,
      actualValue: actualValue ?? this.actualValue,
      comment: comment ?? this.comment,
      snoozed: snoozed ?? this.snoozed,
    );
  }
}
