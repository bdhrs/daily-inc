import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:logging/logging.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class PercentageInputDialog extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onSuccess;

  const PercentageInputDialog({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onSuccess,
  });

  @override
  State<PercentageInputDialog> createState() => _PercentageInputDialogState();
}

class _PercentageInputDialogState extends State<PercentageInputDialog> {
  final _percentageController = TextEditingController();
  final _commentController = TextEditingController();
  final _log = Logger('PercentageInputDialog');
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with today's value if it exists, otherwise use 0
    final todayEntry = widget.item.todayHistoryEntry;
    if (todayEntry != null && todayEntry.actualValue != null) {
      _sliderValue = todayEntry.actualValue!;
      _percentageController.text = _sliderValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter ${widget.item.name} percentage'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What percentage of ${widget.item.name.toLowerCase()} did you complete today?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Slider for percentage selection
          Slider(
            value: _sliderValue,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_sliderValue.toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
                _percentageController.text = value.toStringAsFixed(0);
              });
            },
            activeColor: ColorPalette.primaryBlue,
          ),
          const SizedBox(height: 8),
          // Numeric input field
          TextField(
            controller: _percentageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Percentage (0-100)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final double? parsedValue = double.tryParse(value);
              if (parsedValue != null &&
                  parsedValue >= 0 &&
                  parsedValue <= 100) {
                setState(() {
                  _sliderValue = parsedValue;
                });
              }
            },
            onSubmitted: (value) => _handleSubmit(
              context,
              _percentageController.text,
              _commentController.text,
              widget.onSuccess,
            ),
          ),
          const SizedBox(height: 16),
          // Comment field
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _handleSubmit(
              context,
              _percentageController.text,
              _commentController.text,
              widget.onSuccess,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _log.info('Percentage input dialog cancelled.');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _handleSubmit(
            context,
            _percentageController.text,
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
    String percentageInput,
    String commentInput,
    VoidCallback onSuccess,
  ) async {
    _log.info('Percentage submitted: $percentageInput, Comment: $commentInput');
    final double? percentage = double.tryParse(percentageInput);

    if (percentage != null && percentage >= 0 && percentage <= 100) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final actualValue = percentage;
      widget.item.actualTodayValue = actualValue;
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
      _log.warning('Invalid percentage value entered.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid percentage between 0 and 100.'),
        ),
      );
    }
  }
}
