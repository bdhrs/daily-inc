class HistoryEntry {
  final DateTime date;
  final double value;
  final bool doneToday;

  HistoryEntry({
    required this.date,
    required this.value,
    required this.doneToday,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'done_today': doneToday,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      doneToday: json['done_today'] as bool,
    );
  }
}
