import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/views/add_daily_item_popup.dart';
import 'package:daily_inc/src/views/timer_view.dart';
import 'package:daily_inc/src/services/notification_service.dart';

class DailyThingsView extends StatefulWidget {
  const DailyThingsView({super.key});

  @override
  State<DailyThingsView> createState() => _DailyThingsViewState();
}

class _DailyThingsViewState extends State<DailyThingsView> {
  final DataManager _dataManager = DataManager();
  final NotificationService _notificationService = NotificationService();
  List<DailyThing> _dailyThings = [];
  final Map<String, bool> _isExpanded = {};
  final Map<String, GlobalKey> _expansionTileKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _isExpanded.clear();
    _expansionTileKeys.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await _dataManager.loadData();
    if (items.isNotEmpty) {
      setState(() {
        _dailyThings = items;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Data loaded successfully',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void _refreshDisplay() {
    _loadData();
  }

  void _openAddDailyItemPopup() {
    showDialog(
      context: context,
      builder: (context) => AddDailyItemPopup(
        dataManager: _dataManager,
        onSubmitCallback: () {
          _refreshDisplay();
        },
      ),
    );
  }

  void _editDailyThing(DailyThing item) async {
    final updatedItem = await showDialog<DailyThing>(
      context: context,
      builder: (context) => AddDailyItemPopup(
        dataManager: _dataManager,
        dailyThing: item,
        onSubmitCallback: () {},
      ),
    );

    if (updatedItem != null) {
      setState(() {
        final index =
            _dailyThings.indexWhere((element) => element.id == updatedItem.id);
        if (index != -1) {
          _dailyThings[index] = updatedItem;
        }
      });
    }
  }

  void _deleteDailyThing(DailyThing item) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete "${item.name}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _notificationService.cancelNotification(item.id.hashCode);
      await _dataManager.deleteDailyThing(item);

      // Update the state directly to immediately remove the item from the display
      setState(() {
        _dailyThings.removeWhere((thing) => thing.id == item.id);
      });

      // Also refresh from storage to ensure consistency
      _refreshDisplay();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "${item.name}" deleted',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        return '${value.round()}x';
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
    final isCompletedToday = item.history.any((entry) =>
        entry.date.year == todayDate.year &&
        entry.date.month == todayDate.month &&
        entry.date.day == todayDate.day &&
        entry.doneToday == true);
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
          key: _expansionTileKeys.putIfAbsent(item.id, () => GlobalKey()),
          initiallyExpanded: _isExpanded[item.id] ?? false,
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded[item.id] = expanded;
            });
          },
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
                  Icon(
                    isCompletedToday ? Icons.check : Icons.close,
                    color: isCompletedToday ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8), // Add some spacing
                  if (item.icon != null)
                    Text(
                      item.icon!,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(width: 8), // Add some spacing
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  if (item.itemType == ItemType.minutes) {
                    if (isCompletedToday) {
                      setState(() {
                        _isExpanded[item.id] = !(_isExpanded[item.id] ?? false);
                      });
                    } else {
                      _showFullscreenTimer(item);
                    }
                  } else if (item.itemType == ItemType.check) {
                    final today = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );
                    final newValue = item.todayValue == 1.0 ? 0.0 : 1.0;
                    final newEntry = HistoryEntry(
                      date: today,
                      value: newValue,
                      doneToday: newValue == 1.0,
                    );
                    final existingEntryIndex = item.history.indexWhere(
                      (entry) =>
                          entry.date.year == today.year &&
                          entry.date.month == today.month &&
                          entry.date.day == today.day,
                    );

                    setState(() {
                      if (existingEntryIndex != -1) {
                        item.history[existingEntryIndex] = newEntry;
                      } else {
                        item.history.add(newEntry);
                      }
                      _dataManager.updateDailyThing(item);
                    });
                  } else if (item.itemType == ItemType.reps) {
                    _showRepsInputDialog(item);
                  }
                },
                child: SizedBox(
                  width: 70.0, // Fixed width for alignment
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (item.itemType == ItemType.check &&
                                  item.todayValue == 1) ||
                              (item.itemType != ItemType.check && hasTodayEntry)
                          ? Colors.green[900]
                          : Colors.red[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment
                        .center, // Center the text vertically and horizontally
                    child: item.itemType == ItemType.check
                        ? Icon(
                            item.todayValue == 1.0 ? Icons.check : Icons.close,
                            color: Colors.white,
                          )
                        : Text(
                            _formatValue(item.todayValue, item.itemType),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                item.itemType == ItemType.check
                    ? Text(item.startValue == 1 ? '✅' : '❌',
                        style: const TextStyle(fontSize: 16))
                    : Row(
                        children: [
                          Text(_formatValue(item.startValue, item.itemType)),
                          const Icon(Icons.trending_flat),
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

  void _showRepsInputDialog(DailyThing item) {
    final TextEditingController repsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            autofocus: true, // Automatically focus the text field
            onSubmitted: (value) async {
              final int? reps = int.tryParse(value);
              if (reps != null && reps > 0) {
                final today = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                );
                final newEntry = HistoryEntry(
                  date: today,
                  value: reps.toDouble(),
                  doneToday: true,
                );

                final existingEntryIndex = item.history.indexWhere(
                  (entry) =>
                      entry.date.year == today.year &&
                      entry.date.month == today.month &&
                      entry.date.day == today.day,
                );

                setState(() {
                  if (existingEntryIndex != -1) {
                    item.history[existingEntryIndex] = newEntry;
                  } else {
                    item.history.add(newEntry);
                  }
                  _dataManager.updateDailyThing(item);
                });
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number of reps.'),
                  ),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final int? reps = int.tryParse(repsController.text);
                if (reps != null && reps > 0) {
                  final today = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  final newEntry = HistoryEntry(
                    date: today,
                    value: reps.toDouble(),
                    doneToday: true,
                  );

                  final existingEntryIndex = item.history.indexWhere(
                    (entry) =>
                        entry.date.year == today.year &&
                        entry.date.month == today.month &&
                        entry.date.day == today.day,
                  );

                  setState(() {
                    if (existingEntryIndex != -1) {
                      item.history[existingEntryIndex] = newEntry;
                    } else {
                      item.history.add(newEntry);
                    }
                    _dataManager.updateDailyThing(item);
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number of reps.'),
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
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
              content: const Text(
                'History saved successfully',
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

  Future<void> _loadHistoryFromFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Load History Data',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);

        if (jsonData['dailyThings'] != null) {
          final List<dynamic> thingsJson = jsonData['dailyThings'];
          final List<DailyThing> loadedThings =
              thingsJson.map((json) => DailyThing.fromJson(json)).toList();

          setState(() {
            _dailyThings = loadedThings;
          });

          // Save the loaded data to the default storage
          await _dataManager.saveData(_dailyThings);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'History loaded successfully',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.grey.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          throw Exception('Invalid file format');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
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
        title: const Text('Daily Inc.'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.save_outlined),
            onSelected: (value) {
              if (value == 'load') {
                _loadHistoryFromFile();
              } else if (value == 'save') {
                _saveHistoryToFile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'load',
                child: Row(
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 8),
                    Text('Load'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
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
                    key: Key(item.id),
                    index: _dailyThings.indexOf(item),
                    child: _buildItemRow(item),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openAddDailyItemPopup,
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
