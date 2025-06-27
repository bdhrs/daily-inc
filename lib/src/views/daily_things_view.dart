import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_inc_timer_flutter/src/data/data_manager.dart';
import 'package:daily_inc_timer_flutter/src/models/daily_thing.dart';
import 'package:daily_inc_timer_flutter/src/models/item_type.dart';
import 'package:daily_inc_timer_flutter/src/views/add_daily_item_popup.dart';
import 'package:daily_inc_timer_flutter/src/views/timer_view.dart';

class DailyThingsView extends StatefulWidget {
  const DailyThingsView({super.key});

  @override
  State<DailyThingsView> createState() => _DailyThingsViewState();
}

class _DailyThingsViewState extends State<DailyThingsView> {
  final DataManager _dataManager = DataManager();
  List<DailyThing> _dailyThings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await _dataManager.loadData();
    setState(() {
      _dailyThings = items;
    });
  }

  void _refreshDisplay() {
    _loadData();
  }

  void _openAddDailyItemPopup() {
    showDialog(
      context: context,
      builder: (context) => AddDailyItemPopup(
        dataManager: _dataManager,
        onSubmitCallback: _refreshDisplay,
      ),
    );
  }

  void _editDailyThing(DailyThing item) {
    showDialog(
      context: context,
      builder: (context) => AddDailyItemPopup(
        dataManager: _dataManager,
        dailyThing: item,
        onSubmitCallback: _refreshDisplay,
      ),
    );
  }

  void _deleteDailyThing(DailyThing item) async {
    await _dataManager.deleteDailyThing(item);
    _refreshDisplay();
  }

  void _showFullscreenTimer(DailyThing item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerView(
          item: item,
          dataManager: _dataManager,
          onExitCallback: _refreshDisplay,
        ),
      ),
    );
  }

  String _formatValue(double value, ItemType itemType) {
    if (itemType == ItemType.minutes) {
      if (value.truncateToDouble() == value) {
        return '${value.toInt()}m';
      } else {
        final minutes = value.truncate();
        final seconds = ((value - minutes) * 60).round();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } else if (itemType == ItemType.reps) {
      if (value.truncateToDouble() == value) {
        return '${value.toInt()}x';
      } else {
        return '${value}x';
      }
    } else {
      return value >= 1 ? '✅' : '❌';
    }
  }

  Widget _buildItemRow(DailyThing item) {
    final todayDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isCompletedToday = item.history
        .any((entry) => entry.date == todayDate && entry.doneToday == true);
    final hasTodayEntry = item.history.any(
      (entry) =>
          entry.date.year == todayDate.year &&
          entry.date.month == todayDate.month &&
          entry.date.day == todayDate.day &&
          entry.doneToday,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          trailing:
              const SizedBox.shrink(), // Explicitly remove the trailing icon
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          collapsedShape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_drop_down),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: (item.itemType == ItemType.minutes && !isCompletedToday)
                    ? () => _showFullscreenTimer(item)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasTodayEntry ? Colors.green[900] : Colors.red[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatValue(item.todayValue, item.itemType),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_formatValue(item.startValue, item.itemType)),
                    const Icon(Icons.arrow_forward),
                    Text(_formatValue(item.endValue, item.itemType)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editDailyThing(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDailyThing(item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHistoryToFile() async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save History Data',
        fileName: 'daily_inc_timer_history.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        final jsonData = {
          'dailyThings': _dailyThings.map((thing) => thing.toJson()).toList(),
          'savedAt': DateTime.now().toIso8601String(),
        };
        await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(jsonData));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'History saved successfully',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.grey.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save history: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Inc. Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {}, // Dummy handler
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddDailyItemPopup,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHistoryToFile,
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _dailyThings.removeAt(oldIndex);
            _dailyThings.insert(newIndex, item);
          });
          await _dataManager.saveData(_dailyThings);
        },
        children: [
          for (var item in _dailyThings)
            ReorderableDragStartListener(
              key: Key(item.name),
              index: _dailyThings.indexOf(item),
              child: _buildItemRow(item),
            ),
        ],
      ),
    );
  }
}
