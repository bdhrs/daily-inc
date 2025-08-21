import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';

void main() {
  group('Start Date Today', () {
    test('start date is today - should return start value without increment',
        () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: todayDate, // Start date is today
        startValue: 10,
        duration: 10,
        endValue: 20,
        // No history entries
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(
          todayValue,
          equals(
              10.0)); // Should return start value, not startValue + increment
    });

    test(
        'start date is today with existing history - should return start value without increment',
        () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));

      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: todayDate, // Start date is today (changed from yesterday)
        startValue: 15, // New start value
        duration: 10,
        endValue: 25, // New end value
        history: [
          HistoryEntry(
            date: yesterday,
            targetValue: 12,
            doneToday: true,
          ),
        ],
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(
          todayValue,
          equals(
              15.0)); // Should return new start value, ignoring previous history
    });

    test(
        'start date is in future - should return start value without increment',
        () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final tomorrow = todayDate.add(const Duration(days: 1));

      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: tomorrow, // Start date is in future
        startValue: 10,
        duration: 10,
        endValue: 20,
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(todayValue, equals(10.0)); // Should return start value
    });

    test('start date was yesterday - should apply normal increment logic', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));

      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: yesterday, // Start date was yesterday
        startValue: 10,
        duration: 10,
        endValue: 20,
        history: [
          HistoryEntry(
            date: yesterday,
            targetValue: 10,
            doneToday: true, // Yesterday was completed
          ),
        ],
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(todayValue, equals(11.0)); // Should apply increment: 10 + 1 = 11
    });
  });
}
