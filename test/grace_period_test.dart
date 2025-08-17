import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';

void main() {
  // Create a test task: going from 10 to 20, +1 per day
  final testTask = DailyThing(
    name: 'Test Task',
    itemType: ItemType.reps,
    startDate: DateTime(2025, 8, 10), // Start date
    startValue: 10.0,
    duration: 10, // 10 days to go from 10 to 20
    endValue: 20.0,
  );

  // Simulate history: done days 10, 11, 12, 13, then 2 missed days
  final history = <HistoryEntry>[
    HistoryEntry(
      date: DateTime(2025, 8, 10),
      targetValue: 10.0,
      doneToday: true,
    ),
    HistoryEntry(
      date: DateTime(2025, 8, 11),
      targetValue: 11.0,
      doneToday: true,
    ),
    HistoryEntry(
      date: DateTime(2025, 8, 12),
      targetValue: 12.0,
      doneToday: true,
    ),
    HistoryEntry(
      date: DateTime(2025, 8, 13),
      targetValue: 13.0,
      doneToday: true,
    ),
    // Two missed days (14 and 15)
  ];

  // Create a task with this history
  final taskWithHistory = testTask.copyWith(history: history);

  print('Test scenario:');
  print('Task: Going from 10 to 20, +1 per day');
  print('Done days: Aug 10 (10), Aug 11 (11), Aug 12 (12), Aug 13 (13)');
  print('Missed days: Aug 14, Aug 15');
  print('Today: Aug 16 (3 days since last done)\n');

  // Test with grace period 0
  IncrementCalculator.setGracePeriod(0);
  final valueWithGrace0 =
      IncrementCalculator.calculateTodayValue(taskWithHistory);
  print('With grace period 0: $valueWithGrace0 (penalty applied immediately)');

  // Test with grace period 1
  IncrementCalculator.setGracePeriod(1);
  final valueWithGrace1 =
      IncrementCalculator.calculateTodayValue(taskWithHistory);
  print(
      'With grace period 1: $valueWithGrace1 (no penalty on first missed day)');

  // Test with grace period 2
  IncrementCalculator.setGracePeriod(2);
  final valueWithGrace2 =
      IncrementCalculator.calculateTodayValue(taskWithHistory);
  print(
      'With grace period 2: $valueWithGrace2 (no penalty for two missed days)');

  print('\nExplanation:');
  print('- Grace period 0: Penalty applied immediately (13 - 1*2 = 11)');
  print('- Grace period 1: No penalty for first missed day (13 + 1 = 14)');
  print('- Grace period 2: No penalty for first two missed days (13 + 1 = 14)');
}
