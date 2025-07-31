import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/history_entry.dart';

void main() {
  group('Decreasing Progression Missed Days Test', () {
    test(
        'minutes type, start value 60 end value 5, duration 55, 3 days ago entry was 15, 2 days ago missed, yesterday missed. whats today\'s value?',
        () {
      // Create history entries
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // 3 days ago was 15 (completed)
      final threeDaysAgoEntry = HistoryEntry(
        date: threeDaysAgo,
        targetValue: 15,
        doneToday: true,
        actualValue: 15,
      );

      // 2 days ago was missed
      final twoDaysAgoEntry = HistoryEntry(
        date: twoDaysAgo,
        targetValue: 14, // Would have been 14 if completed
        doneToday: false,
        actualValue: null,
      );

      // Yesterday was missed
      final yesterdayEntry = HistoryEntry(
        date: yesterday,
        targetValue: 13, // Would have been 13 if completed
        doneToday: false,
        actualValue: null,
      );

      // Create the daily thing with the specified parameters and history
      final dailyThing = DailyThing(
        id: 'test',
        name: 'Test Minutes',
        startValue: 60,
        endValue: 5,
        duration: 55,
        itemType: ItemType.minutes,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        history: [threeDaysAgoEntry, twoDaysAgoEntry, yesterdayEntry],
      );

      // Calculate what today's value should be
      final todayValue = dailyThing.todayValue;
      final increment = dailyThing.increment;

      // Analysis: This is a DECREASING progression (60 > 5)
      // For decreasing progressions with missed days, we apply a one-day increment penalty (penalty goes upward)
      // Last completed was 3 days ago with value 15
      // Since there are missed days (2 days ago and yesterday), we apply penalty: 15 - (-1.0) = 16
      // (increment is -1.0 for decreasing, so subtracting it adds 1.0)

      // Expected: 16 (15 - (-1.0) increment penalty, since it's decreasing with missed days)
      expect(todayValue, 16);
      expect(increment, -1.0);
    });
  });
}
