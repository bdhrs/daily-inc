import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/history_entry.dart';

void main() {
  group('Specific Scenario Test', () {
    test(
        'type is reps, startvalue is 30, end value is 20, duration is 10, yesterday\'s was missed, the day before was 26. whats todays value',
        () {
      // Create history entries
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Day before yesterday was 26 (completed)
      final twoDaysAgoEntry = HistoryEntry(
        date: twoDaysAgo,
        targetValue: 26,
        doneToday: true,
        actualValue: 26,
      );

      // Yesterday was missed (no entry or completed: false)
      final yesterdayEntry = HistoryEntry(
        date: yesterday,
        targetValue: 25, // Would have been 25 if completed
        doneToday: false,
        actualValue: null,
      );

      // Create the daily thing with the specified parameters and history
      // Note: history should be in chronological order for proper sorting
      final dailyThing = DailyThing(
        id: 'test',
        name: 'Test Reps',
        startValue: 30,
        endValue: 20,
        duration: 10,
        itemType: ItemType.reps,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        history: [twoDaysAgoEntry, yesterdayEntry],
      );

      // Calculate what today's value should be
      final todayValue = dailyThing.todayValue;

      // Expected calculation:
      // - Start: 30, End: 20, Duration: 10 days
      // - Daily increment: (20 - 30) / 10 = -1 per day
      // - Day before yesterday: 26 (completed)
      // - Yesterday: missed (no increment applied due to missed day for decreasing progression)
      // - Today: should be 26 (same as last completed)

      expect(todayValue, 26);
      expect(dailyThing.increment, -1);
    });
  });
}
