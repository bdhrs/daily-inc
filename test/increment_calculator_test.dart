import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';

void main() {
  group('IncrementCalculator', () {
    test('calculateIncrement returns correct value', () {
      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: DateTime.now(),
        startValue: 10,
        duration: 10,
        endValue: 20,
      );

      final increment = IncrementCalculator.calculateIncrement(item);
      expect(increment, equals(1.0));
    });

    test('calculateTodayValue applies increment when previous day completed', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        startValue: 10,
        duration: 10,
        endValue: 20,
        history: [
          HistoryEntry(
            date: yesterdayDate,
            targetValue: 12,
            doneToday: true, // Yesterday was completed
          ),
        ],
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(todayValue, equals(13.0)); // 12 + 1 increment
    });

    test('calculateTodayValue does not increment when previous day not completed', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        startValue: 10,
        duration: 10,
        endValue: 20,
        history: [
          HistoryEntry(
            date: yesterdayDate,
            targetValue: 12,
            doneToday: false, // Yesterday was not completed
          ),
        ],
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);
      expect(todayValue, equals(12.0)); // No increment applied
    });

    test('calculateTodayValue handles decreasing progression', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      final item = DailyThing(
        name: 'Test Item',
        itemType: ItemType.minutes,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        startValue: 20,
        duration: 10,
        endValue: 10, // Decreasing progression
        history: [
          HistoryEntry(
            date: yesterdayDate,
            targetValue: 18,
            doneToday: true, // Yesterday was completed
          ),
        ],
      );

      final increment = IncrementCalculator.calculateIncrement(item);
      print('Increment: $increment'); // Debug: should be -1.0
      
      final todayValue = IncrementCalculator.calculateTodayValue(item);
      print('Today value: $todayValue'); // Debug
      
      // For decreasing progression: 20 -> 10 over 10 days = -1.0 increment
      // Yesterday was 18, so today should be 18 + (-1.0) = 17.0
      expect(todayValue, equals(17.0)); // 18 - 1 increment
    });

    test('getLastCompletedDate returns correct date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final twoDaysAgoDate = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);
      
      final history = [
        HistoryEntry(
          date: twoDaysAgoDate,
          targetValue: 11,
          doneToday: true,
        ),
        HistoryEntry(
          date: yesterdayDate,
          targetValue: 12,
          doneToday: true,
        ),
      ];

      final lastCompleted = IncrementCalculator.getLastCompletedDate(history);
      expect(lastCompleted, equals(yesterdayDate));
    });

    test('getLastCompletedDate returns null when no completed entries', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      final history = [
        HistoryEntry(
          date: yesterdayDate,
          targetValue: 12,
          doneToday: false, // Not completed
        ),
      ];

      final lastCompleted = IncrementCalculator.getLastCompletedDate(history);
      expect(lastCompleted, isNull);
    });
  });
}