import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';

class TrendInputDialog extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onSuccess;

  const TrendInputDialog({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onSuccess,
  });

  @override
  State<TrendInputDialog> createState() => _TrendInputDialogState();
}

class _TrendInputDialogState extends State<TrendInputDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Trend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrendButton(context, '↗️ Improving', 1.0),
          const SizedBox(height: 8),
          _buildTrendButton(context, '→ Same', 0.0),
          const SizedBox(height: 8),
          _buildTrendButton(context, '↘️ Worse', -1.0),
        ],
      ),
    );
  }

  Widget _buildTrendButton(BuildContext context, String text, double value) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSubmit(context, value),
        child: Text(text),
      ),
    );
  }

  void _handleSubmit(BuildContext context, double selectedValue) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final existingEntry = widget.item.todayHistoryEntry;

    final newEntry = HistoryEntry(
      date: todayDate,
      targetValue: widget.item.todayValue, // Keep target value for consistency
      actualValue: selectedValue,
      doneToday: true, // Any selection marks it as done
    );

    final history = List<HistoryEntry>.from(widget.item.history);
    if (existingEntry != null) {
      final index = history.indexWhere((e) => e.date == newEntry.date);
      if (index != -1) {
        history[index] = newEntry;
      } else {
        history.add(newEntry);
      }
    } else {
      history.add(newEntry);
    }

    await widget.dataManager.updateDailyThing(widget.item.copyWith(history: history));
    widget.onSuccess();
    Navigator.of(context).pop();
  }
}