import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_inc/src/core/sequence_helper.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';

void main() {
  // Read the shipped asset from disk rather than through rootBundle so the test
  // needs no binding, and so a broken hand edit fails here before it ships.
  final raw = jsonDecode(File('assets/default_items.json').readAsStringSync())
      as Map<String, dynamic>;
  final items = (raw['dailyThings'] as List<dynamic>)
      .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
      .toList();

  group('default items asset', () {
    test('parses into 9 items with unique ids', () {
      expect(items.length, 9);
      expect(items.map((i) => i.id).toSet().length, 9);
    });

    test('every ItemType appears exactly once at top level', () {
      final topLevel = items
          .where((i) => SequenceHelper.findParentSequence(i, items) == null)
          .toList();

      for (final type in ItemType.values) {
        expect(
          topLevel.where((i) => i.itemType == type).length,
          1,
          reason: 'expected exactly one top-level $type item',
        );
      }
    });

    test('every item has an emoji icon and a category', () {
      for (final item in items) {
        expect(item.icon, isNotNull, reason: '${item.name} has no icon');
        expect(item.icon!.trim(), isNotEmpty,
            reason: '${item.name} has a blank icon');
        expect(item.category, isNot('None'),
            reason: '${item.name} has no category');
      }
    });

    test('the sequence resolves both of its children', () {
      final sequence =
          items.firstWhere((i) => i.itemType == ItemType.sequence);
      expect(SequenceHelper.resolveChildren(sequence, items).length, 2);
      expect(sequence.autoPlay, isTrue);
    });

    test('every item starts with empty history and is due today', () {
      for (final item in items) {
        expect(item.history, isEmpty, reason: '${item.name} ships history');
        expect(item.isDueToday, isTrue,
            reason: '${item.name} is not due on first run');
      }
    });

    test('an untouched item shows its start value, not its end value', () {
      final meditation =
          items.firstWhere((i) => i.name == 'Meditation');
      expect(meditation.todayValue, 5.0);
      expect(meditation.displayValue, 5.0);
    });
  });
}
