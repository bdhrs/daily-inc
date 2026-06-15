import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/core/sequence_helper.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DailyThing dailyCheckChild(String id, {bool doneToday = false}) {
    return DailyThing(
      id: id,
      name: 'Check $id',
      itemType: ItemType.check,
      startDate: today.subtract(const Duration(days: 30)),
      startValue: 0,
      duration: 1,
      endValue: 1,
      intervalType: IntervalType.byDays,
      intervalValue: 1,
      history: doneToday
          ? [
              HistoryEntry(
                date: today,
                targetValue: 1,
                doneToday: true,
                actualValue: 1,
              ),
            ]
          : const [],
    );
  }

  DailyThing sequence(List<DailyThing> children,
      {IntervalType intervalType = IntervalType.byDays,
      List<int> weekdays = const []}) {
    return DailyThing(
      id: 'seq',
      name: 'Weekly Sequence',
      itemType: ItemType.sequence,
      startDate: today.subtract(const Duration(days: 30)),
      startValue: 0,
      duration: 1,
      endValue: 1,
      intervalType: intervalType,
      intervalWeekdays: weekdays,
      childIds: children.map((c) => c.id).toList(),
    );
  }

  group('sequenceCompletedForToday', () {
    test('1 of 3 children done → not completed', () {
      final children = [
        dailyCheckChild('a', doneToday: true),
        dailyCheckChild('b'),
        dailyCheckChild('c'),
      ];
      final seq = sequence(children);
      final all = [seq, ...children];

      expect(SequenceHelper.sequenceCompletedForToday(seq, all), isFalse);
    });

    test('all 3 children done → completed', () {
      final children = [
        dailyCheckChild('a', doneToday: true),
        dailyCheckChild('b', doneToday: true),
        dailyCheckChild('c', doneToday: true),
      ];
      final seq = sequence(children);
      final all = [seq, ...children];

      expect(SequenceHelper.sequenceCompletedForToday(seq, all), isTrue);
    });

    test(
        'regression: sequence not due by its own schedule does not mask '
        'undone children', () {
      // Weekday-based sequence scheduled for a weekday that is NOT today,
      // so seq.isDueToday is false. This is the exact condition that
      // previously force-returned "completed" regardless of child state.
      final notToday = (today.weekday % 7) + 1; // any weekday != today
      final children = [
        dailyCheckChild('a', doneToday: true),
        dailyCheckChild('b'),
        dailyCheckChild('c'),
      ];
      final seq = sequence(
        children,
        intervalType: IntervalType.byWeekdays,
        weekdays: [notToday],
      );
      final all = [seq, ...children];

      expect(seq.isDueToday, isFalse,
          reason: 'sequence should not be due today by its own schedule');
      expect(SequenceHelper.sequenceCompletedForToday(seq, all), isFalse);
    });

    test('empty sequence → not completed', () {
      final seq = sequence(const []);
      expect(SequenceHelper.sequenceCompletedForToday(seq, [seq]), isFalse);
    });
  });

  group('sequenceIsUndoneToday cross-check', () {
    test('undone while children remain, done only when all complete', () {
      final partial = [
        dailyCheckChild('a', doneToday: true),
        dailyCheckChild('b'),
        dailyCheckChild('c'),
      ];
      final partialSeq = sequence(partial);
      expect(
          SequenceHelper.sequenceIsUndoneToday(
              partialSeq, [partialSeq, ...partial]),
          isTrue);

      final complete = [
        dailyCheckChild('a', doneToday: true),
        dailyCheckChild('b', doneToday: true),
        dailyCheckChild('c', doneToday: true),
      ];
      final completeSeq = sequence(complete);
      expect(
          SequenceHelper.sequenceIsUndoneToday(
              completeSeq, [completeSeq, ...complete]),
          isFalse);
    });
  });
}
