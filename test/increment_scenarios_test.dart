import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';

void main() {
  group('Increment Scenarios', () {
    group('Minutes - Increasing Progression (10 to 60)', () {
      late DailyThing baseItem;

      setUp(() {
        baseItem = DailyThing(
          name: 'Increasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50, // 50 days to go from 10 to 60
          endValue: 60,
        );
      });

      test('increment calculation', () {
        final increment = IncrementCalculator.calculateIncrement(baseItem);
        expect(increment, equals(1.0)); // (60-10)/50 = 1.0
      });

      test('no history - returns start value', () {
        final todayValue = IncrementCalculator.calculateTodayValue(baseItem);
        expect(todayValue, equals(10.0));
      });

      test('yesterday completed - should increment', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Increasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 25,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(26.0)); // 25 + 1 increment
      });

      test('yesterday not completed - should not increment', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Increasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 25,
              doneToday: false,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(
            todayValue,
            equals(
                21.0)); // Spec: daysSinceDone == 2 -> no change from baseTarget which is lastEntry.targetValue (21 in this setup)
      });

      test('multiple days missed - should apply penalty', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final threeDaysAgoDate =
            DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day);

        final item = DailyThing(
          name: 'Increasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: threeDaysAgoDate,
              targetValue: 20,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(18.0)); // 20 - (1 * 2) = 18
      });
    });

    group('Minutes - Decreasing Progression (60 to 10)', () {
      late DailyThing baseItem;

      setUp(() {
        baseItem = DailyThing(
          name: 'Decreasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50, // 50 days to go from 60 to 10
          endValue: 10,
        );
      });

      test('increment calculation', () {
        final increment = IncrementCalculator.calculateIncrement(baseItem);
        expect(increment, equals(-1.0)); // (10-60)/50 = -1.0
      });

      test('no history - returns start value', () {
        final todayValue = IncrementCalculator.calculateTodayValue(baseItem);
        expect(todayValue, equals(60.0));
      });

      test('yesterday completed - should decrement', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Decreasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 45,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(44.0)); // 45 + (-1) = 44
      });

      test('yesterday not completed - should not decrement', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Decreasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 45,
              doneToday: false,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(
            todayValue,
            equals(
                49.0)); // Spec: daysSinceDone == 2 -> no change from baseTarget which is lastEntry.targetValue (49 in this setup)
      });

      test('multiple days missed - should apply penalty', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final threeDaysAgoDate =
            DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day);

        final item = DailyThing(
          name: 'Decreasing Minutes',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: threeDaysAgoDate,
              targetValue: 50,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(52.0)); // 50 - (-1 * 2) = 52
      });
    });

    group('Reps - Increasing Progression (10 to 60)', () {
      late DailyThing baseItem;

      setUp(() {
        baseItem = DailyThing(
          name: 'Increasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50, // 50 days to go from 10 to 60
          endValue: 60,
        );
      });

      test('increment calculation', () {
        final increment = IncrementCalculator.calculateIncrement(baseItem);
        expect(increment, equals(1.0)); // (60-10)/50 = 1.0
      });

      test('no history - returns start value', () {
        final todayValue = IncrementCalculator.calculateTodayValue(baseItem);
        expect(todayValue, equals(10.0));
      });

      test('yesterday completed - should increment', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Increasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 25,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(26.0)); // 25 + 1 increment
      });

      test('display value shows actual value when entered today', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Increasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 26,
              doneToday: true,
              actualValue: 30, // User actually did 30 reps
            ),
          ],
        );

        final displayValue = IncrementCalculator.calculateDisplayValue(item);
        expect(displayValue, equals(30.0)); // Shows actual value, not target
      });

      test('isDone with actual value meeting target', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Increasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 26,
              doneToday: false,
              actualValue: 30, // User did 30, target is 26
            ),
          ],
        );

        final isDone = IncrementCalculator.isDone(item, 30);
        expect(isDone, isTrue); // 30 >= 26, so done
      });

      test('isDone with actual value not meeting target', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Increasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 50,
          endValue: 60,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 26,
              doneToday: false,
              actualValue: 24, // User did 24, target is 26
            ),
          ],
        );

        final isDone = IncrementCalculator.isDone(item, 24);
        expect(isDone, isFalse); // 24 < 26, so not done
      });
    });

    group('Reps - Decreasing Progression (60 to 10)', () {
      late DailyThing baseItem;

      setUp(() {
        baseItem = DailyThing(
          name: 'Decreasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50, // 50 days to go from 60 to 10
          endValue: 10,
        );
      });

      test('increment calculation', () {
        final increment = IncrementCalculator.calculateIncrement(baseItem);
        expect(increment, equals(-1.0)); // (10-60)/50 = -1.0
      });

      test('no history - returns start value', () {
        final todayValue = IncrementCalculator.calculateTodayValue(baseItem);
        expect(todayValue, equals(60.0));
      });

      test('yesterday completed - should decrement', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Decreasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 45,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(44.0)); // 45 + (-1) = 44
      });

      test('display value shows actual value when entered today', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Decreasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 44,
              doneToday: true,
              actualValue: 40, // User actually did 40 reps
            ),
          ],
        );

        final displayValue = IncrementCalculator.calculateDisplayValue(item);
        expect(displayValue, equals(40.0)); // Shows actual value, not target
      });

      test('isDone with actual value meeting target (decreasing)', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Decreasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 44,
              doneToday: false,
              actualValue: 40, // User did 40, target is 44 (decreasing)
            ),
          ],
        );

        final isDone = IncrementCalculator.isDone(item, 40);
        expect(isDone, isTrue); // 40 <= 44, so done for decreasing
      });

      test('isDone with actual value not meeting target (decreasing)', () {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final item = DailyThing(
          name: 'Decreasing Reps',
          itemType: ItemType.reps,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 60,
          duration: 50,
          endValue: 10,
          history: [
            HistoryEntry(
              date: todayDate,
              targetValue: 44,
              doneToday: false,
              actualValue: 48, // User did 48, target is 44 (decreasing)
            ),
          ],
        );

        final isDone = IncrementCalculator.isDone(item, 48);
        expect(isDone, isFalse); // 48 > 44, so not done for decreasing
      });
    });

    group('Edge Cases', () {
      test('frequencyInDays respected - not due yet', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Every 2 Days',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 10,
          endValue: 20,
          intervalValue: 2, // Every 2 days
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 15,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(15.0)); // Not due yet, no increment
      });

      test('frequencyInDays respected - due today', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final twoDaysAgoDate =
            DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);

        final item = DailyThing(
          name: 'Every 2 Days',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 10,
          endValue: 20,
          intervalValue: 2, // Every 2 days
          history: [
            HistoryEntry(
              date: twoDaysAgoDate,
              targetValue: 15,
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(15.0));
      });

      test('bounds clamping - increasing progression', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Near End',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 10,
          duration: 10,
          endValue: 20,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 19.5, // Very close to end
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(20.0)); // Clamped to endValue
      });

      test('bounds clamping - decreasing progression', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        final item = DailyThing(
          name: 'Near End',
          itemType: ItemType.minutes,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          startValue: 20,
          duration: 10,
          endValue: 10,
          history: [
            HistoryEntry(
              date: yesterdayDate,
              targetValue: 10.5, // Very close to end
              doneToday: true,
            ),
          ],
        );

        final todayValue = IncrementCalculator.calculateTodayValue(item);
        expect(todayValue, equals(10.0)); // Clamped to endValue
      });
    });
  });
}
