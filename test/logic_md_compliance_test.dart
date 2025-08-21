import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncrementCalculator logic.md Compliance: Start Value < End Value', () {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    test(
        'when start date is today and 1 day has passed since last completion, value should be start value',
        () {
      // Arrange: Last entry was yesterday with a value of 15, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 1));
      final item = DailyThing(
        id: '1',
        name: 'Meditation',
        startDate: todayDate,
        startValue: 10,
        endValue: 20,
        duration: 10,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 15, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 10.0);
    });

    test(
        'when start date is today and 2 days have passed, value should be start value',
        () {
      // Arrange: Last entry was 2 days ago with a value of 15, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 2));
      final item = DailyThing(
        id: '1',
        name: 'Meditation',
        startDate: todayDate,
        startValue: 10,
        endValue: 20,
        duration: 10,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 15, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 10.0);
    });

    test(
        'when start date is today and 3 days have passed, value should be start value',
        () {
      // Arrange: Last entry was 3 days ago with a value of 15, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 3));
      final item = DailyThing(
        id: '1',
        name: 'Meditation',
        startDate: todayDate,
        startValue: 10,
        endValue: 20,
        duration: 10,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 15, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 10.0);
    });
  });

  group('IncrementCalculator logic.md Compliance: Start Value > End Value', () {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    test(
        'when start date is today and 1 day has passed, value should be start value',
        () {
      // Arrange: Last entry was yesterday with a value of 50, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 1));
      final item = DailyThing(
        id: '2',
        name: 'Reduce Screen Time',
        startDate: todayDate,
        startValue: 60,
        endValue: 30,
        duration: 30,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 50, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 60.0);
    });

    test(
        'when start date is today and 2 days have passed, value should be start value',
        () {
      // Arrange: Last entry was 2 days ago with a value of 50, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 2));
      final item = DailyThing(
        id: '2',
        name: 'Reduce Screen Time',
        startDate: todayDate,
        startValue: 60,
        endValue: 30,
        duration: 30,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 50, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 60.0);
    });

    test(
        'when start date is today and 3 days have passed, value should be start value',
        () {
      // Arrange: Last entry was 3 days ago with a value of 50, but start date is today
      final lastEntryDate = todayDate.subtract(const Duration(days: 3));
      final item = DailyThing(
        id: '2',
        name: 'Reduce Screen Time',
        startDate: todayDate,
        startValue: 60,
        endValue: 30,
        duration: 30,
        itemType: ItemType.minutes,
        intervalValue: 1,
        history: [
          HistoryEntry(date: lastEntryDate, targetValue: 50, doneToday: true)
        ],
      );

      // Act
      final newValue = IncrementCalculator.calculateTodayValue(item);

      // Assert: When start date is today, return start value regardless of history
      expect(newValue, 60.0);
    });
  });
}
