import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeeklyReviewSettings {
  static const String enabledKey = 'weeklyReviewEnabled';
  static const String weekdayKey = 'weeklyReviewWeekday';
  static const String hourKey = 'weeklyReviewHour';
  static const String minuteKey = 'weeklyReviewMinute';
  static const String showOnStartupKey = 'weeklyReviewShowOnStartup';
  static const String lastShownKey = 'weeklyReviewLastShownAt';

  final bool enabled;
  final int weekday;
  final TimeOfDay time;
  final bool showOnStartup;

  const WeeklyReviewSettings({
    required this.enabled,
    required this.weekday,
    required this.time,
    required this.showOnStartup,
  });

  factory WeeklyReviewSettings.defaults() {
    return const WeeklyReviewSettings(
      enabled: true,
      weekday: DateTime.sunday,
      time: TimeOfDay(hour: 19, minute: 0),
      showOnStartup: true,
    );
  }

  static Future<WeeklyReviewSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = WeeklyReviewSettings.defaults();

    return WeeklyReviewSettings(
      enabled: prefs.getBool(enabledKey) ?? defaults.enabled,
      weekday: prefs.getInt(weekdayKey) ?? defaults.weekday,
      time: TimeOfDay(
        hour: prefs.getInt(hourKey) ?? defaults.time.hour,
        minute: prefs.getInt(minuteKey) ?? defaults.time.minute,
      ),
      showOnStartup:
          prefs.getBool(showOnStartupKey) ?? defaults.showOnStartup,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    await prefs.setInt(weekdayKey, weekday);
    await prefs.setInt(hourKey, time.hour);
    await prefs.setInt(minuteKey, time.minute);
    await prefs.setBool(showOnStartupKey, showOnStartup);
  }

  WeeklyReviewSettings copyWith({
    bool? enabled,
    int? weekday,
    TimeOfDay? time,
    bool? showOnStartup,
  }) {
    return WeeklyReviewSettings(
      enabled: enabled ?? this.enabled,
      weekday: weekday ?? this.weekday,
      time: time ?? this.time,
      showOnStartup: showOnStartup ?? this.showOnStartup,
    );
  }
}

class WeeklyReviewSchedule {
  static DateTime currentOrMostRecentOccurrence(
    WeeklyReviewSettings settings,
    DateTime now,
  ) {
    final scheduledToday = DateTime(
      now.year,
      now.month,
      now.day,
      settings.time.hour,
      settings.time.minute,
    );
    final daysSinceWeekday = (now.weekday - settings.weekday + 7) % 7;
    var occurrence = scheduledToday.subtract(Duration(days: daysSinceWeekday));

    if (daysSinceWeekday == 0 && now.isBefore(occurrence)) {
      occurrence = occurrence.subtract(const Duration(days: 7));
    }

    return occurrence;
  }

  static DateTime nextOccurrence(
    WeeklyReviewSettings settings,
    DateTime now,
  ) {
    final mostRecent = currentOrMostRecentOccurrence(settings, now);
    if (now.isBefore(mostRecent)) {
      return mostRecent;
    }
    return mostRecent.add(const Duration(days: 7));
  }
}

class WeeklyReviewService {
  Future<bool> shouldOpenReview({
    required DateTime now,
    WeeklyReviewSettings? settings,
  }) async {
    final effectiveSettings = settings ?? await WeeklyReviewSettings.load();
    if (!effectiveSettings.enabled) {
      return false;
    }

    final occurrence = WeeklyReviewSchedule.currentOrMostRecentOccurrence(
      effectiveSettings,
      now,
    );
    if (occurrence.isAfter(now)) {
      return false;
    }

    final lastShown = await _loadLastShownOccurrence();
    return lastShown == null || !lastShown.isAtSameMomentAs(occurrence);
  }

  Future<bool> shouldOpenReviewOnStartup({
    WeeklyReviewSettings? settings,
  }) async {
    final effectiveSettings = settings ?? await WeeklyReviewSettings.load();
    return effectiveSettings.enabled && effectiveSettings.showOnStartup;
  }

  Future<void> markOccurrenceShown(DateTime occurrence) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      WeeklyReviewSettings.lastShownKey,
      occurrence.toIso8601String(),
    );
  }

  Future<DateTime?> loadLastShownOccurrence() {
    return _loadLastShownOccurrence();
  }

  Future<DateTime?> _loadLastShownOccurrence() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(WeeklyReviewSettings.lastShownKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
