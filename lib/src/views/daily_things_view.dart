import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/settings_view.dart';
import 'package:daily_inc/src/views/timer_view.dart';
import 'package:daily_inc/src/views/daily_thing_item.dart';
import 'package:daily_inc/src/views/reps_input_dialog.dart';
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
              child: const Text('Cancel',
                  style: TextStyle(color: ColorPalette.errorRed)),
              onPressed: () {
                _log.info('Delete cancelled.');
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete',
                  style: TextStyle(color: ColorPalette.errorRed)),
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

  void _duplicateItem(DailyThing item) async {
    _log.info('Duplicating daily thing: ${item.name}');
    try {
      final duplicatedItem = DailyThing(
        name: item.name,
        itemType: item.itemType,
        startDate: item.startDate,
        startValue: item.startValue,
        duration: item.duration,
        endValue: item.endValue,
        icon: item.icon,
        nagTime: item.nagTime,
        nagMessage: item.nagMessage,
        history: [],
      );
      await _dataManager.addDailyThing(duplicatedItem);
      _refreshDisplay();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicated "${item.name}"'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, s) {
      _log.severe('Error duplicating item', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  Widget _buildItemRow(DailyThing item) {
    return DailyThingItem(
      item: item,
      dataManager: _dataManager,
      allTasksCompleted: _allTasksCompleted,
      onEdit: _editDailyThing,
      onDelete: _deleteDailyThing,
      onDuplicate: _duplicateItem,
      showFullscreenTimer: _showFullscreenTimer,
      showRepsInputDialog: _showRepsInputDialog,
      checkAndShowCompletionSnackbar: _checkAndShowCompletionSnackbar,
      isExpanded: _isExpanded[item.id] ?? false,
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded[item.id] = expanded;
        });
      },
    );
  }

  void _showRepsInputDialog(DailyThing item) {
    _log.info('Showing reps input dialog for: ${item.name}');
    showDialog(
      context: context,
      builder: (context) => RepsInputDialog(
        item: item,
        dataManager: _dataManager,
        onSuccess: _checkAndShowCompletionSnackbar,
      ),
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
            icon: const Icon(Icons.save),
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
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _dailyThings.length,
              itemBuilder: (context, index) {
                final item = _dailyThings[index];
                return LongPressDraggable<DailyThing>(
                  data: item,
                  feedback: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Material(
                      elevation: 4.0,
                      child: _buildItemRow(item),
                    ),
                  ),
                  childWhenDragging: Container(
                    height: 80, // Adjust height to match item height
                    color: Colors.grey[200],
                  ),
                  onDragStarted: () {
                    // Optional: Add feedback when dragging starts
                  },
                  child: DragTarget<DailyThing>(
                    onWillAcceptWithDetails: (details) {
                      return details.data != item;
                    },
                    onAcceptWithDetails: (details) {
                      final droppedItem = details.data;
                      setState(() {
                        final oldIndex = _dailyThings.indexOf(droppedItem);
                        final newIndex = index;
                        if (newIndex > oldIndex) {
                          _dailyThings.insert(newIndex, droppedItem);
                          _dailyThings.removeAt(oldIndex);
                        } else {
                          _dailyThings.removeAt(oldIndex);
                          _dailyThings.insert(newIndex, droppedItem);
                        }
                      });
                      _dataManager.saveData(_dailyThings);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return _buildItemRow(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
