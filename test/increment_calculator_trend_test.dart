import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/history_entry.dart';

HistoryEntry entry(DateTime date, double value) => HistoryEntry(
      date: DateTime(date.year, date.month, date.day),
      targetValue: 0,
      doneToday: true,
      actualValue: value,
    );

void main() {
  group('IncrementCalculator.accumulatedTrendUpTo', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int n) => today.subtract(Duration(days: n));

    test('empty history returns 0', () {
      expect(IncrementCalculator.accumulatedTrendUpTo([], today), 0.0);
    });

    test('today entry counts but today is never decremented as missed', () {
      expect(
          IncrementCalculator.accumulatedTrendUpTo(
              [entry(today, 1.0)], today),
          1.0);
      // No entry today, no past history -> 0 (today not decremented)
      expect(IncrementCalculator.accumulatedTrendUpTo([], today), 0.0);
    });

    test('single past +1 yields 1', () {
      final history = [entry(daysAgo(1), 1.0)];
      expect(IncrementCalculator.accumulatedTrendUpTo(history, today), 1.0);
    });

    test('two +1 then five missed days floors at 0', () {
      final history = [
        entry(daysAgo(7), 1.0),
        entry(daysAgo(6), 1.0),
      ];
      expect(IncrementCalculator.accumulatedTrendUpTo(history, today), 0.0);
    });

    test('+1 then -1 yields 0', () {
      final history = [
        entry(daysAgo(2), 1.0),
        entry(daysAgo(1), -1.0),
      ];
      expect(IncrementCalculator.accumulatedTrendUpTo(history, today), 0.0);
    });

    test('consecutive -1 entries floor at 0', () {
      final history = [
        entry(daysAgo(3), -1.0),
        entry(daysAgo(2), -1.0),
        entry(daysAgo(1), -1.0),
      ];
      expect(IncrementCalculator.accumulatedTrendUpTo(history, today), 0.0);
    });

    test('missed days then +1 starts from floor', () {
      final history = [
        entry(daysAgo(5), 1.0),
        // 4 missed days here - floors to 0
        entry(daysAgo(1), 1.0),
      ];
      // day -5: +1 -> 1
      // day -4: missed -> 0 (floor)
      // day -3: missed -> 0
      // day -2: missed -> 0
      // day -1: +1 -> 1
      expect(IncrementCalculator.accumulatedTrendUpTo(history, today), 1.0);
    });

    test('asOfDate before first entry returns 0', () {
      final history = [entry(daysAgo(2), 1.0)];
      expect(
          IncrementCalculator.accumulatedTrendUpTo(history, daysAgo(5)), 0.0);
    });
  });

  group('IncrementCalculator.accumulatedTrendSeries', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int n) => today.subtract(Duration(days: n));

    test('returns 0 for all dates when history is empty', () {
      final dates = [daysAgo(2), daysAgo(1), today];
      final series =
          IncrementCalculator.accumulatedTrendSeries([], dates);
      for (final d in dates) {
        expect(series[d], 0.0);
      }
    });

    test('piecewise values across a gap', () {
      final history = [
        entry(daysAgo(5), 1.0),
        entry(daysAgo(4), 1.0),
        entry(daysAgo(1), 1.0),
      ];
      final dates = [
        daysAgo(5),
        daysAgo(4),
        daysAgo(3),
        daysAgo(2),
        daysAgo(1),
        today,
      ];
      final series =
          IncrementCalculator.accumulatedTrendSeries(history, dates);
      expect(series[daysAgo(5)], 1.0);
      expect(series[daysAgo(4)], 2.0);
      expect(series[daysAgo(3)], 1.0); // missed
      expect(series[daysAgo(2)], 0.0); // missed, floored
      expect(series[daysAgo(1)], 1.0); // +1
      expect(series[today], 1.0); // today not decremented
    });

    test('dates before first entry get 0', () {
      final history = [entry(daysAgo(1), 1.0)];
      final dates = [daysAgo(3), daysAgo(2), daysAgo(1)];
      final series =
          IncrementCalculator.accumulatedTrendSeries(history, dates);
      expect(series[daysAgo(3)], 0.0);
      expect(series[daysAgo(2)], 0.0);
      expect(series[daysAgo(1)], 1.0);
    });
  });
}
