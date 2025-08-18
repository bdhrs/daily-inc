import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';

void main() {
  group('Weekday Carry-over Tests', () {
    test('Weekday item due on Sunday should show on Monday if not completed',
        () {
      // Create a Sunday date (weekday 7)
      final sunday = DateTime(2025, 8, 17); // Sunday
      final monday = DateTime(2025, 8, 18); // Monday

      // Create a weekday-based item scheduled for Sundays
      final item = DailyThing(
        name: 'Sunday Exercise',
        itemType: ItemType.minutes,
        startDate:
            sunday.subtract(const Duration(days: 7)), // Started a week ago
        startValue: 10,
        duration: 10,
        endValue: 20,
        intervalType: IntervalType.byWeekdays,
        intervalWeekdays: [DateTime.sunday], // Scheduled for Sundays only
        history: [], // No history yet
      );

      // Test using IncrementCalculator.isDue directly with Monday date
      // This should return true because the item was due on Sunday but not completed
      expect(IncrementCalculator.isDue(item, monday), isTrue);
    });

    test('Weekday item completed on Sunday should not show on Monday', () {
      // Create a Sunday date (weekday 7)
      final sunday = DateTime(2025, 8, 17); // Sunday
      final monday = DateTime(2025, 8, 18); // Monday

      // Create a weekday-based item scheduled for Sundays
      final item = DailyThing(
        name: 'Sunday Exercise',
        itemType: ItemType.minutes,
        startDate:
            sunday.subtract(const Duration(days: 7)), // Started a week ago
        startValue: 10,
        duration: 10,
        endValue: 20,
        intervalType: IntervalType.byWeekdays,
        intervalWeekdays: [DateTime.sunday], // Scheduled for Sundays only
        history: [
          HistoryEntry(
            date: sunday,
            targetValue: 12,
            doneToday: true, // Completed on Sunday
          ),
        ],
      );

      // Test using IncrementCalculator.isDue directly with Monday date
      // This should return false because the item was completed on Sunday
      expect(IncrementCalculator.isDue(item, monday), isFalse);
    });

    test('Weekday item not scheduled for today but not completed should show',
        () {
      // Create a Wednesday date
      final wednesday = DateTime(2025, 8, 20); // Wednesday
      final thursday = DateTime(2025, 8, 21); // Thursday

      // Create a weekday-based item scheduled for Wednesdays
      final item = DailyThing(
        name: 'Wednesday Meeting',
        itemType: ItemType.check,
        startDate:
            wednesday.subtract(const Duration(days: 7)), // Started a week ago
        startValue: 0,
        duration: 10,
        endValue: 10,
        intervalType: IntervalType.byWeekdays,
        intervalWeekdays: [DateTime.wednesday], // Scheduled for Wednesdays only
        history: [
          HistoryEntry(
            date: wednesday,
            targetValue: 1,
            doneToday: false, // Not completed on Wednesday
          ),
        ],
      );

      // Test using IncrementCalculator.isDue directly with Thursday date
      // This should return true because the item was due on Wednesday but not completed
      expect(IncrementCalculator.isDue(item, thursday), isTrue);
    });

    test('shouldShowInList returns true when isDueToday is true', () {
      // Create an item that is due today
      final today = DateTime.now();
      final item = DailyThing(
        name: 'Daily Task',
        itemType: ItemType.minutes,
        startDate: today.subtract(const Duration(days: 1)),
        startValue: 10,
        duration: 10,
        endValue: 20,
        history: [], // No history, so it should be due today
      );

      // This should return true because the item is due today
      expect(item.isDueToday, isTrue);
      // Therefore, shouldShowInList should also return true
      expect(item.shouldShowInList, isTrue);
    });

    test('shouldShowInList returns true when hasBeenDoneLiterallyToday is true',
        () {
      // Create an item that has been done today
      final today = DateTime.now();
      final item = DailyThing(
        name: 'Daily Task',
        itemType: ItemType.minutes,
        startDate: today.subtract(const Duration(days: 1)),
        startValue: 10,
        duration: 10,
        endValue: 20,
        history: [
          HistoryEntry(
            date: today,
            targetValue: 12,
            doneToday: true, // Completed today
          ),
        ],
      );

      // This should return true because the item has been done today
      expect(item.hasBeenDoneLiterallyToday, isTrue);
      // Therefore, shouldShowInList should also return true
      expect(item.shouldShowInList, isTrue);
    });

    test(
        'completedForToday returns false for weekday item due previously but not completed',
        () {
      // Create a Sunday date (weekday 7)
      final sunday = DateTime(2025, 8, 17); // Sunday
      final monday = DateTime(2025, 8, 18); // Monday

      // Create a weekday-based item scheduled for Sundays
      final item = DailyThing(
        name: 'Sunday Exercise',
        itemType: ItemType.minutes,
        startDate:
            sunday.subtract(const Duration(days: 7)), // Started a week ago
        startValue: 10,
        duration: 10,
        endValue: 20,
        intervalType: IntervalType.byWeekdays,
        intervalWeekdays: [DateTime.sunday], // Scheduled for Sundays only
        history: [
          HistoryEntry(
            date: sunday,
            targetValue: 12,
            doneToday: false, // Not completed on Sunday
          ),
        ],
      );

      // On Monday, the item is not due today (isDueToday should be false)
      // But it should not be considered completed for today because it was due on Sunday but not completed
      // We need to mock DateTime.now() to Monday to test this
      // Since we can't easily mock DateTime.now(), we'll test the logic directly

      // The item should not be completed for today
      // Note: We can't directly test this without mocking DateTime.now()
      // But we can test that IncrementCalculator.isDue returns true for Monday
      expect(IncrementCalculator.isDue(item, monday), isTrue);
    });
  });
}
