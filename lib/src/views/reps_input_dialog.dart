import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';

class RepsInputDialog extends StatelessWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onSuccess;
  final _log = Logger('RepsInputDialog');

  RepsInputDialog({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController repsController = TextEditingController();

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('how many ${item.name.toLowerCase()}?'),
          TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (value) => _handleSubmit(
              context,
              repsController.text,
              onSuccess,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _log.info('Reps input dialog cancelled.');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _handleSubmit(
            context,
            repsController.text,
            onSuccess,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void _handleSubmit(
    BuildContext context,
    String input,
    VoidCallback onSuccess,
  ) async {
    _log.info('Reps submitted: $input');
    final int? reps = int.tryParse(input);

    if (reps != null && reps >= 0) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final actualValue = reps.toDouble();
      item.actualTodayValue =
          actualValue; // Update actualTodayValue with actual value
      final newEntry = HistoryEntry(
        date: today,
        targetValue: item.todayValue,
        doneToday: item.isDone(actualValue),
        actualValue: actualValue,
      );

      final existingEntryIndex = item.history.indexWhere(
        (entry) =>
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day,
      );

      if (existingEntryIndex != -1) {
        item.history[existingEntryIndex] = newEntry;
      } else {
        item.history.add(newEntry);
      }

      await dataManager.updateDailyThing(item);
      if (context.mounted) {
        Navigator.of(context).pop();
        onSuccess();
      }
    } else if (context.mounted) {
      _log.warning('Invalid reps value entered.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of reps.'),
        ),
      );
    }
  }
}
