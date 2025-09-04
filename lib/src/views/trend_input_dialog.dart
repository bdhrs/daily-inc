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
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadExistingComment();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _loadExistingComment() {
    final existingEntry = widget.item.todayHistoryEntry;
    if (existingEntry != null && existingEntry.comment != null) {
      _commentController.text = existingEntry.comment!;
    }
  }

  String _formatSentenceCase(String text) {
    if (text.isEmpty) return text;

    // Split into sentences and capitalize first letter of each
    final sentences = text.split('. ');
    final formattedSentences = sentences.map((sentence) {
      if (sentence.isEmpty) return sentence;
      return sentence[0].toUpperCase() + sentence.substring(1);
    }).toList();

    return formattedSentences.join('. ');
  }

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
          const SizedBox(height: 16),
          _buildCommentField(),
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

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      focusNode: _commentFocusNode,
      decoration: const InputDecoration(
        hintText: 'Add an optional comment',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
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
      comment: _commentController.text.isNotEmpty
          ? _formatSentenceCase(_commentController.text)
          : null,
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

    await widget.dataManager
        .updateDailyThing(widget.item.copyWith(history: history));
    widget.onSuccess();
    Navigator.of(context).pop();
  }
}
