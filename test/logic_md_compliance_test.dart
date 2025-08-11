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
        'when 1 day has passed since last completion, value should increase by increment',
        () {
      // Arrange: Last entry was yesterday with a value of 15
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

      // Assert: According to logic.md, it should increment.
      // Expected: 15 (last value) + 1 (increment) = 16
      expect(newValue, 16.0);
    });

    test('when 2 days have passed, value should not change', () {
      // Arrange: Last entry was 2 days ago with a value of 15
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

      // Assert: According to logic.md, there's no change.
      // Expected: 15 (last value)
      expect(newValue, 15.0);
    });

    test('when 3 days have passed, value should decrease by penalty', () {
      // Arrange: Last entry was 3 days ago with a value of 15
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

      // Assert: According to logic.md, penalty is decrement * (missed_days - 1)
      // Missed days = 3. Penalty days = 3 - 1 = 2.
      // Penalty = 1.0 (increment) * 2 = 2.0
      // Expected: 15 (last value) - 2.0 (penalty) = 13.0
      // Note: logic.md says "penalty decrement", assuming it's same as increment
      expect(newValue, 13.0);
    });
  });

  group('IncrementCalculator logic.md Compliance: Start Value > End Value', () {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    test('when 1 day has passed, value should decrease by increment (inverted)',
        () {
      // Arrange: Last entry was yesterday with a value of 50
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

      // Assert: Logic is reversed. "increment" for decreasing is a decrement.
      // Expected: 50 (last value) + (-1.0 increment) = 49.0
      expect(newValue, 49.0);
    });

    test('when 2 days have passed, value should not change', () {
      // Arrange: Last entry was 2 days ago with a value of 50
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

      // Assert: No change, same as increasing logic.
      // Expected: 50 (last value)
      expect(newValue, 50.0);
    });

    test('when 3 days have passed, value should increase by penalty (inverted)',
        () {
      // Arrange: Last entry was 3 days ago with a value of 50
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

      // Assert: Penalty is reversed. A decrement becomes an increment.
      // Missed days = 3. Penalty days = 3 - 1 = 2.
      // Penalty = -1.0 (increment) * 2 = -2.0
      // The logic says decrement, so we subtract the penalty.
      // Expected: 50 (last value) - (-2.0 penalty) = 52.0
      expect(newValue, 52.0);
    });
  });
}
