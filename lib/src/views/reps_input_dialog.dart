import 'dart:io';

import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';

class RepsInputDialog extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onSuccess;

  const RepsInputDialog({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onSuccess,
  });

  @override
  State<RepsInputDialog> createState() => _RepsInputDialogState();
}

class _RepsInputDialogState extends State<RepsInputDialog> {
  final _repsController = TextEditingController();
  final _commentController = TextEditingController();
  final _log = Logger('RepsInputDialog');

  @override
  void dispose() {
    _repsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('how many ${widget.item.name.toLowerCase()}?'),
          TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (value) => _handleSubmit(
              context,
              _repsController.text,
              _commentController.text,
              widget.onSuccess,
            ),
          ),
          TextField(
            controller: _commentController,
            textCapitalization: Platform.isAndroid
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            decoration: const InputDecoration(labelText: 'Comment'),
            onSubmitted: (value) => _handleSubmit(
              context,
              _repsController.text,
              _commentController.text,
              widget.onSuccess,
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
            _repsController.text,
            _commentController.text,
            widget.onSuccess,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void _handleSubmit(
    BuildContext context,
    String repsInput,
    String commentInput,
    VoidCallback onSuccess,
  ) async {
    _log.info('Reps submitted: $repsInput, Comment: $commentInput');
    final int? reps = int.tryParse(repsInput);

    if (reps != null && reps >= 0) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final actualValue = reps.toDouble();
      widget.item.actualTodayValue =
          actualValue; // Update actualTodayValue with actual value
      final newEntry = HistoryEntry(
        date: today,
        targetValue: widget.item.todayValue,
        doneToday: widget.item.isDone(actualValue),
        actualValue: actualValue,
        comment: commentInput,
      );

      final existingEntryIndex = widget.item.history.indexWhere(
        (entry) =>
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day,
      );

      if (existingEntryIndex != -1) {
        widget.item.history[existingEntryIndex] = newEntry;
      } else {
        widget.item.history.add(newEntry);
      }

      await widget.dataManager.updateDailyThing(widget.item);
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
