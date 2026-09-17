import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final numberFormat = NumberFormat('0.##');

  // The grace period is static global state on IncrementCalculator; pin it so
  // this file does not inherit a value set by another test file.
  setUp(() {
    IncrementCalculator.setGracePeriod(1);
  });
  tearDown(() {
    IncrementCalculator.setGracePeriod(1);
  });

  DailyThing buildItem() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DailyThing(
      name: 'Diverging Item',
      itemType: ItemType.minutes,
      startDate: today.subtract(const Duration(days: 200)),
      startValue: 1.0,
      duration: 66,
      endValue: 20.0,
      history: [
        HistoryEntry(
          date: today.subtract(const Duration(days: 10)),
          targetValue: 5.0,
          doneToday: false,
        ),
      ],
    );
  }

  Future<void> pumpHistoryView(WidgetTester tester, DailyThing item) async {
    await tester.pumpWidget(MaterialApp(
      home: HistoryView(item: item, onHistoryUpdated: () {}),
    ));
    await tester.pumpAndSettle();
  }

  // The add-row is the first DataRow, so its four TextFormFields come first.
  TextFormField fieldAt(WidgetTester tester, int index) =>
      tester.widgetList<TextFormField>(find.byType(TextFormField)).elementAt(index);

  // The fixture is deliberately one whose pure calendar projection (20.0, the
  // end value) is far from its real target (1.0), so a regression back to the
  // old calculation fails loudly rather than coincidentally matching.
  test('fixture has the target the main list would show', () {
    expect(buildItem().todayValue, 1.0);
  });

  testWidgets('add-row Target pre-fills with today\'s real target',
      (WidgetTester tester) async {
    final item = buildItem();
    await pumpHistoryView(tester, item);

    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.add),
    ));
    await tester.pumpAndSettle();

    // Without this the index-based lookup below would silently read an
    // existing row's field if the add-row ever stopped rendering.
    expect(find.byIcon(Icons.close), findsOneWidget);

    expect(
      fieldAt(tester, 1).controller!.text,
      numberFormat.format(item.todayValue),
    );
  });

  testWidgets('ticking Done copies Target into Actual',
      (WidgetTester tester) async {
    final item = buildItem();
    await pumpHistoryView(tester, item);

    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.add),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    final target = fieldAt(tester, 1).controller!.text;
    final actual = fieldAt(tester, 2).controller!.text;
    expect(target, numberFormat.format(item.todayValue));
    expect(actual, target);
  });

  testWidgets('a past date blanks Target, returning to today restores it',
      (WidgetTester tester) async {
    final item = buildItem();
    await pumpHistoryView(tester, item);

    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.add),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    final today = DateTime.now();
    final past = today.subtract(const Duration(days: 3));
    final dateFormat = DateFormat('yy/MM/dd');

    await tester.enterText(
        find.byWidget(fieldAt(tester, 0)), dateFormat.format(past));
    await tester.pumpAndSettle();
    expect(fieldAt(tester, 1).controller!.text, '');

    await tester.enterText(
        find.byWidget(fieldAt(tester, 0)), dateFormat.format(today));
    await tester.pumpAndSettle();
    expect(
      fieldAt(tester, 1).controller!.text,
      numberFormat.format(item.todayValue),
    );
  });

  testWidgets('a hand-typed Target survives further editing of the date',
      (WidgetTester tester) async {
    final item = buildItem();
    await pumpHistoryView(tester, item);

    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.add),
    ));
    await tester.pumpAndSettle();

    final dateFormat = DateFormat('yy/MM/dd');
    final past = DateTime.now().subtract(const Duration(days: 3));

    await tester.enterText(
        find.byWidget(fieldAt(tester, 0)), dateFormat.format(past));
    await tester.pumpAndSettle();

    await tester.enterText(find.byWidget(fieldAt(tester, 1)), '7.5');
    await tester.pumpAndSettle();

    // Editing the date again, still in the past, must not wipe the entry.
    await tester.enterText(
        find.byWidget(fieldAt(tester, 0)),
        dateFormat.format(DateTime.now().subtract(const Duration(days: 4))));
    await tester.pumpAndSettle();

    expect(fieldAt(tester, 1).controller!.text, '7.5');
  });
}
