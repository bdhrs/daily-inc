import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/daily_things_helpers.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DailyThing check(String id, {bool doneToday = false}) {
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

  DailyThing sequence(String id, List<DailyThing> children) {
    return DailyThing(
      id: id,
      name: 'Sequence $id',
      itemType: ItemType.sequence,
      startDate: today.subtract(const Duration(days: 30)),
      startValue: 0,
      duration: 1,
      endValue: 1,
      intervalType: IntervalType.byDays,
      intervalValue: 1,
      childIds: children.map((c) => c.id).toList(),
    );
  }

  group('getNextUndoneIndex', () {
    test('empty list returns -1', () {
      expect(getNextUndoneIndex(const [], const []), -1);
    });

    test('all items done returns -1', () {
      final items = [check('a', doneToday: true), check('b', doneToday: true)];
      expect(getNextUndoneIndex(items, items), -1);
    });

    test('sequence with an undone child is the next undone item', () {
      final children = [check('c1', doneToday: true), check('c2')];
      final seq = sequence('seq', children);
      final displayed = [check('a', doneToday: true), seq, check('b')];
      final all = [...displayed, ...children];

      expect(getNextUndoneIndex(displayed, all), 1);
    });

    test('fully completed sequence is skipped', () {
      final children = [
        check('c1', doneToday: true),
        check('c2', doneToday: true),
      ];
      final seq = sequence('seq', children);
      final displayed = [seq, check('b')];
      final all = [...displayed, ...children];

      expect(getNextUndoneIndex(displayed, all), 1);
    });

    test('undone non-sequence above an undone sequence wins', () {
      final children = [check('c1')];
      final seq = sequence('seq', children);
      final displayed = [check('a'), seq];
      final all = [...displayed, ...children];

      expect(getNextUndoneIndex(displayed, all), 0);
    });
  });
}
