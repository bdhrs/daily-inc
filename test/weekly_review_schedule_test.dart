import 'package:daily_inc/src/services/weekly_review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeeklyReviewSettings', () {
    test('loads default schedule when no preferences are saved', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await WeeklyReviewSettings.load();

      expect(settings.enabled, isTrue);
      expect(settings.weekday, DateTime.sunday);
      expect(settings.time.hour, 19);
      expect(settings.time.minute, 0);
      expect(settings.showOnStartup, isTrue);
    });
  });

  group('WeeklyReviewSchedule', () {
    test('returns current week occurrence when scheduled time already passed',
        () {
      final settings = WeeklyReviewSettings(
        enabled: true,
        weekday: DateTime.sunday,
        time: const TimeOfDay(hour: 19, minute: 0),
        showOnStartup: true,
      );

      final now = DateTime(2026, 4, 5, 20, 15);

      expect(
        WeeklyReviewSchedule.currentOrMostRecentOccurrence(settings, now),
        DateTime(2026, 4, 5, 19),
      );
    });

    test('returns previous week occurrence before the configured time', () {
      final settings = WeeklyReviewSettings(
        enabled: true,
        weekday: DateTime.sunday,
        time: const TimeOfDay(hour: 19, minute: 0),
        showOnStartup: true,
      );

      final now = DateTime(2026, 4, 5, 18, 45);

      expect(
        WeeklyReviewSchedule.currentOrMostRecentOccurrence(settings, now),
        DateTime(2026, 3, 29, 19),
      );
    });

    test('returns the next configured occurrence', () {
      final settings = WeeklyReviewSettings(
        enabled: true,
        weekday: DateTime.sunday,
        time: const TimeOfDay(hour: 19, minute: 0),
        showOnStartup: true,
      );

      final now = DateTime(2026, 4, 3, 10, 0);

      expect(
        WeeklyReviewSchedule.nextOccurrence(settings, now),
        DateTime(2026, 4, 5, 19),
      );
    });

    test('blocks showing the same occurrence twice', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = WeeklyReviewSettings(
        enabled: true,
        weekday: DateTime.sunday,
        time: const TimeOfDay(hour: 19, minute: 0),
        showOnStartup: true,
      );
      final service = WeeklyReviewService();
      final now = DateTime(2026, 4, 5, 20, 0);

      expect(await service.shouldOpenReview(now: now, settings: settings),
          isTrue);

      await service.markOccurrenceShown(
        WeeklyReviewSchedule.currentOrMostRecentOccurrence(settings, now),
      );

      expect(await service.shouldOpenReview(now: now, settings: settings),
          isFalse);
    });

    test('startup open can stay enabled after the scheduled review was shown',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = WeeklyReviewSettings(
        enabled: true,
        weekday: DateTime.sunday,
        time: const TimeOfDay(hour: 19, minute: 0),
        showOnStartup: true,
      );
      final service = WeeklyReviewService();
      final now = DateTime(2026, 4, 5, 20, 0);

      await service.markOccurrenceShown(
        WeeklyReviewSchedule.currentOrMostRecentOccurrence(settings, now),
      );

      expect(await service.shouldOpenReviewOnStartup(settings: settings),
          isTrue);
      expect(await service.shouldOpenReview(now: now, settings: settings),
          isFalse);
    });
  });
}
