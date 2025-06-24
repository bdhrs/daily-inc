class HistoryEntry {
  final DateTime date;
  final double value;
  final bool done_today;

  HistoryEntry({
    required this.date,
    required this.value,
    required this.done_today,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'done_today': done_today,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      done_today: json['done_today'] as bool,
    );
  }
}
