import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/graph_view.dart';
import 'package:daily_inc/src/views/settings_view.dart';
import 'package:daily_inc/src/views/timer_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:logging/logging.dart';

class DailyThingsView extends StatefulWidget {
  const DailyThingsView({super.key});

  @override
  State<DailyThingsView> createState() => _DailyThingsViewState();
}

class _DailyThingsViewState extends State<DailyThingsView> {
  final DataManager _dataManager = DataManager();
  List<DailyThing> _dailyThings = [];
  final Map<String, bool> _isExpanded = {};
  final Map<String, GlobalKey> _expansionTileKeys = {};
  final _log = Logger('DailyThingsView');
  bool _hasShownCompletionSnackbar = false;
  bool _allTasksCompleted = false;

  @override
  void initState() {
    super.initState();
    _log.info('initState called');
    _loadData();
  }

  @override
  void dispose() {
    _log.info('dispose called');
    _isExpanded.clear();
    _expansionTileKeys.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    _log.info('Loading data...');
    final items = await _dataManager.loadData();
    if (items.isNotEmpty) {
      _log.info('Loaded ${items.length} items.');
      setState(() {
        _dailyThings = items;
      });
    } else {
      _log.warning('No items to load.');
    }
  }

  void _refreshDisplay() {
    _log.info('Refreshing display.');
    _loadData();
  }

  void _openAddDailyItemPopup() {
    _log.info('Opening add daily item popup.');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDailyItemView(
          dataManager: _dataManager,
          onSubmitCallback: () {
            _log.info('Add item callback triggered.');
            _refreshDisplay();
          },
        ),
      ),
    );
  }

  void _editDailyThing(DailyThing item) async {
    _log.info('Editing daily thing: ${item.name}');
    final updatedItem = await Navigator.push<DailyThing>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDailyItemView(
          dataManager: _dataManager,
          dailyThing: item,
          onSubmitCallback: () {
            _log.info('Edit item callback triggered.');
          },
        ),
      ),
    );

    if (updatedItem != null) {
      _log.info('Item updated: ${updatedItem.name}');
      setState(() {
        final index =
            _dailyThings.indexWhere((element) => element.id == updatedItem.id);
        if (index != -1) {
          _log.info('Updating item in list.');
          _dailyThings[index] = updatedItem;
        } else {
          _log.warning('Could not find item to update in list.');
        }
      });
    } else {
      _log.info('Edit cancelled.');
    }
  }

  void _deleteDailyThing(DailyThing item) async {
    _log.info('Attempting to delete daily thing: ${item.name}');
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
                _log.info('Delete cancelled.');
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _log.info('Delete confirmed.');
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _log.info('Deleting item.');
      await _dataManager.deleteDailyThing(item);

      // Update the state directly to immediately remove the item from the display
      setState(() {
        _dailyThings.removeWhere((thing) => thing.id == item.id);
      });

      // Also refresh from storage to ensure consistency
      _refreshDisplay();

      if (mounted) {
        _log.info('Showing delete confirmation snackbar.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "${item.name}" deleted',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFullscreenTimer(DailyThing item) {
    _log.info('Showing fullscreen timer for: ${item.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerView(
          item: item,
          dataManager: _dataManager,
          onExitCallback: _refreshDisplay,
        ),
      ),
    ).then((_) {
      _checkAndShowCompletionSnackbar();
    });
  }

  String _formatValue(double value, ItemType itemType) {
    // No logging here as it's a pure formatting function called frequently.
    if (itemType == ItemType.minutes) {
      if (value.truncateToDouble() == value) {
        return '${value.toInt()}m';
      } else {
        final minutes = value.truncate();
        final seconds = ((value - minutes) * 60).round();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } else if (itemType == ItemType.reps) {
      return '${value.round()}x';
    } else {
      return value >= 1 ? '✅' : '❌';
    }
  }

  Widget _buildItemRow(DailyThing item) {
    // No logging here as it's part of the build method and called frequently.
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
                    color: isCompletedToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8), // Add some spacing
                  if (item.icon != null)
                    Text(
                      item.icon!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(width: 8), // Add some spacing
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
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
                    _checkAndShowCompletionSnackbar();
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment
                        .center, // Center the text vertically and horizontally
                    child: item.itemType == ItemType.check
                        ? Icon(
                            item.todayValue == 1.0 ? Icons.check : Icons.close,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            _formatValue(item.todayValue, item.itemType),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14),
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
                // For CHECK items, don't show start/end values since they're irrelevant
                item.itemType == ItemType.check
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(
                            left:
                                32.0), // Add left padding to align with text above
                        child: Row(
                          children: [
                            Text(_formatValue(item.startValue, item.itemType)),
                            const Icon(Icons.trending_flat),
                            Text(_formatValue(item.endValue, item.itemType)),
                          ],
                        ),
                      ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.show_chart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GraphView(dailyThing: item),
                          ),
                        );
                      },
                    ),
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
    _log.info('Showing reps input dialog for: ${item.name}');
    final TextEditingController repsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('how many ${item.name.toLowerCase()}?'),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                autofocus: true, // Automatically focus the text field
                onSubmitted: (value) async {
                  _log.info('Reps submitted via keyboard: $value');
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
                      doneToday: item.isDone(reps.toDouble()),
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
                    _checkAndShowCompletionSnackbar();
                  } else {
                    _log.warning('Invalid reps value entered.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number of reps.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _log.info('Reps input dialog cancelled.');
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                _log.info('Reps submitted via button: ${repsController.text}');
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
                    doneToday: item.isDone(reps.toDouble()),
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
                  _checkAndShowCompletionSnackbar();
                } else {
                  _log.warning('Invalid reps value entered.');
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
    _log.info('Attempting to save history to file.');
    try {
      _log.info('Preparing history data for saving.');
      final jsonData = {
        'dailyThings': _dailyThings.map((thing) => thing.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonString);

      _log.info('Opening file picker to save file.');
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save History Data',
        fileName: 'daily_inc_history.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: bytes,
      );

      // On Android & iOS, outputFile will be null on success. On desktop, it will be the path.
      // On any platform, if the user cancels, it's null. There's an ambiguity here
      // on mobile platforms, but we'll show success if no error is thrown.
      if (outputFile != null || Platform.isAndroid || Platform.isIOS) {
        if (mounted) {
          _log.info('History saved successfully.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'History saved successfully',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _log.info('Save file operation cancelled.');
      }
    } catch (e, s) {
      _log.severe('Failed to save history', e, s);
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

  void _checkAndShowCompletionSnackbar() {
    final todayDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    bool allCompleted = _dailyThings.every((item) => item.history.any((entry) =>
        entry.date.year == todayDate.year &&
        entry.date.month == todayDate.month &&
        entry.date.day == todayDate.day &&
        entry.doneToday == true));

    if (allCompleted && !_hasShownCompletionSnackbar) {
      _log.info('All tasks completed, showing celebration snackbar.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Well done, all tasks done!'),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _hasShownCompletionSnackbar = true;
        _allTasksCompleted = true;
      });
    } else if (!allCompleted) {
      setState(() {
        _hasShownCompletionSnackbar = false;
        _allTasksCompleted = false;
      });
    }
  }

  Future<void> _loadHistoryFromFile() async {
    _log.info('Attempting to load history from file.');
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Load History Data',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        _log.info('Loading history from: ${result.files.single.path}');
        final file = File(result.files.single.path!);
        _log.info('Reading file content.');
        final jsonString = await file.readAsString();
        _log.info('Decoding JSON data.');
        final jsonData = jsonDecode(jsonString);

        if (jsonData['dailyThings'] != null) {
          _log.info('Mapping JSON to DailyThing objects.');
          final List<dynamic> thingsJson = jsonData['dailyThings'];
          final List<DailyThing> loadedThings =
              thingsJson.map((json) => DailyThing.fromJson(json)).toList();

          setState(() {
            _dailyThings = loadedThings;
          });

          // Save the loaded data to the default storage
          await _dataManager.saveData(_dailyThings);
          _log.info(
              'History loaded and saved to default storage successfully.');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'History loaded successfully',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor:
                    Theme.of(context).snackBarTheme.backgroundColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _log.severe('Invalid file format for loading history.');
          throw Exception('Invalid file format');
        }
      } else {
        _log.info('Load file operation cancelled.');
      }
    } catch (e, s) {
      _log.severe('Failed to load history', e, s);
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
    _log.info('build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Inc',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _allTasksCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.headlineSmall?.color,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add an item',
            icon: const Icon(Icons.add),
            onPressed: _openAddDailyItemPopup,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsView(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Save and Load History',
            icon: const Icon(Icons.history),
            onSelected: (value) {
              if (value == 'load_history') {
                _loadHistoryFromFile();
              } else if (value == 'save_history') {
                _saveHistoryToFile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'load_history',
                child: Row(
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 8),
                    Text('Load History'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'save_history',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save History'),
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
            child: Tooltip(
              message: 'Add an item',
              child: ElevatedButton(
                onPressed: _openAddDailyItemPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.cardBackground,
                  foregroundColor: ColorPalette.primaryBlue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
