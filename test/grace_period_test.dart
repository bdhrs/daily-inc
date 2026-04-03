import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncrementCalculator grace period behavior', () {
    tearDown(() {
      IncrementCalculator.setGracePeriod(1);
    });

    DailyThing buildItem({
      required int daysSinceLastCompletion,
      required double previousTargetValue,
    }) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final completionDate =
          todayDate.subtract(Duration(days: daysSinceLastCompletion));

      return DailyThing(
        name: 'Grace Period Task',
        itemType: ItemType.reps,
        startDate: todayDate.subtract(const Duration(days: 10)),
        startValue: 10.0,
        duration: 10,
        endValue: 20.0,
        history: [
          HistoryEntry(
            date: completionDate,
            targetValue: previousTargetValue,
            doneToday: true,
          ),
        ],
      );
    }

    test('default grace period keeps value unchanged after one missed day', () {
      final item = buildItem(
        daysSinceLastCompletion: 2,
        previousTargetValue: 13.0,
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);

      expect(todayValue, 13.0);
    });

    test('grace period zero applies penalty on the first missed day', () {
      IncrementCalculator.setGracePeriod(0);
      final item = buildItem(
        daysSinceLastCompletion: 2,
        previousTargetValue: 13.0,
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);

      expect(todayValue, 12.0);
    });

    test('grace period two keeps value unchanged after two missed days', () {
      IncrementCalculator.setGracePeriod(2);
      final item = buildItem(
        daysSinceLastCompletion: 3,
        previousTargetValue: 13.0,
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);

      expect(todayValue, 13.0);
    });

    test(
        'by-days items still increment on the exact interval boundary during grace period',
        () {
      IncrementCalculator.setGracePeriod(2);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final item = DailyThing(
        name: 'Every 2 Days Task',
        itemType: ItemType.reps,
        startDate: todayDate.subtract(const Duration(days: 10)),
        startValue: 10.0,
        duration: 10,
        endValue: 20.0,
        intervalType: IntervalType.byDays,
        intervalValue: 2,
        history: [
          HistoryEntry(
            date: todayDate.subtract(const Duration(days: 2)),
            targetValue: 13.0,
            doneToday: true,
          ),
        ],
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);

      expect(todayValue, 15.0);
    });

    test(
        'once grace period is exceeded, penalty still uses total days since completion',
        () {
      IncrementCalculator.setGracePeriod(2);
      final item = buildItem(
        daysSinceLastCompletion: 4,
        previousTargetValue: 13.0,
      );

      final todayValue = IncrementCalculator.calculateTodayValue(item);

      expect(todayValue, 10.0);
    });
  });
}
