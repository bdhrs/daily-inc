import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/settings_view.dart';
import 'package:daily_inc/src/views/timer_view.dart';
import 'package:daily_inc/src/views/daily_thing_item.dart';
import 'package:daily_inc/src/views/reps_input_dialog.dart';
import 'package:daily_inc/src/views/help_view.dart';
import 'package:daily_inc/src/views/category_graph_view.dart';
import 'package:daily_inc/src/views/widgets/pulse.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:logging/logging.dart';

class DailyThingsView extends StatefulWidget {
  const DailyThingsView({super.key});

  @override
  State<DailyThingsView> createState() => _DailyThingsViewState();
}

class _DailyThingsViewState extends State<DailyThingsView>
    with WidgetsBindingObserver {
  final DataManager _dataManager = DataManager();
  List<DailyThing> _dailyThings = [];
  final Map<String, bool> _isExpanded = {};
  final Map<String, GlobalKey> _expansionTileKeys = {};
  final _log = Logger('DailyThingsView');
  bool _hasShownCompletionSnackbar = false;
  bool _allTasksCompleted = false;
  bool _showOnlyDueItems = true;
  bool _hideWhenDone = false;
  bool _motivationCheckedThisBuild = false;
  bool _allExpanded = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _log.info('initState called');
    // Load settings first to ensure they're available for first build
    _loadHideWhenDoneSetting().then((_) {
      _loadData();
    });
  }

  Future<void> _loadHideWhenDoneSetting() async {
    final prefs = await SharedPreferences.getInstance();
    // Update state immediately without setState to ensure value is available for first build
    _hideWhenDone = prefs.getBool('hideWhenDone') ?? false;
    _log.info('Initial hideWhenDone setting: $_hideWhenDone');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshHideWhenDoneSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideWhenDone = prefs.getBool('hideWhenDone') ?? false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      // Check if all tasks are already completed when app loads
      _checkAndShowCompletionSnackbar();
    } else {
      _log.warning('No items to load.');
      setState(() {
        _allTasksCompleted = false;
        _hasShownCompletionSnackbar = false;
      });
    }
  }

  void _refreshDisplay() {
    _maybeShowMotivation();
    _log.info('Refreshing display.');
    // Ensure a rebuild occurs immediately before async reload,
    // so UI reflects updated completion state without needing a second tap.
    if (mounted) {
      setState(() {});
    }
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
      _checkAndShowCompletionSnackbar();
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
                  style: TextStyle(color: ColorPalette.warningOrange)),
              onPressed: () {
                _log.info('Delete cancelled.');
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete',
                  style: TextStyle(color: ColorPalette.warningOrange)),
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

  Future<void> _maybeShowMotivation() async {
    try {
      final today = DateTime.now();
      final ymd =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final last = await _dataManager.getLastMotivationShownDate();
      if (last == ymd || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      final acknowledged = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('Finish all your things today!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("I'll do my very best"),
            ),
          ],
        ),
      );
      if (acknowledged == true) {
        await _dataManager.setLastMotivationShownDate(ymd);
      }
    } catch (e, s) {
      _log.severe('Error showing motivation dialog', e, s);
    }
  }

  Widget _buildItemRow(DailyThing item, int index, int nextUndoneIndex) {
    // Initialize expansion state if not already set - always start closed
    _isExpanded.putIfAbsent(item.id, () => false);

    final dailyThingItem = DailyThingItem(
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
      onItemChanged: _refreshDisplay,
    );

    // Wrap with Pulse animation if this is the next undone item
    if (index == nextUndoneIndex) {
      return Pulse(
        child: dailyThingItem,
      );
    }

    return dailyThingItem;
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

  int _getNextUndoneIndex(List<DailyThing> items) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.itemType == ItemType.check && !item.completedForToday) {
        return i;
      } else if (item.itemType == ItemType.reps) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final hasActualValueToday = item.history.any((entry) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate == todayDate && entry.actualValue != null;
        });
        if (!hasActualValueToday) {
          return i;
        }
      } else if (item.itemType == ItemType.minutes) {
        if (!item.completedForToday) {
          return i;
        }
      }
    }
    return -1; // All items are done
  }

  void _expandAllVisibleItems() {
    _log.info('Toggling expansion of all visible items');
    setState(() {
      // Get the list of displayed items (same filtering as in build method)
      List<DailyThing> displayedItems = _showOnlyDueItems
          ? _dailyThings
              .where(
                  (item) => item.isDueToday || item.hasBeenDoneLiterallyToday)
              .toList()
          : _dailyThings;

      if (_hideWhenDone) {
        displayedItems = displayedItems.where((item) {
          // For REPS items, hide when any actual value has been entered today
          if (item.itemType == ItemType.reps) {
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);

            // Check if there's any entry for today with actual value
            final hasActualValueToday = item.history.any((entry) {
              final entryDate =
                  DateTime(entry.date.year, entry.date.month, entry.date.day);
              return entryDate == todayDate && entry.actualValue != null;
            });

            return !hasActualValueToday;
          }

          // For MINUTES and CHECK items, maintain existing behavior
          return !item.completedForToday;
        }).toList();
      }

      // Check if all visible items are currently expanded
      bool allExpanded =
          displayedItems.every((item) => _isExpanded[item.id] ?? false);

      // Toggle expansion state for all visible items
      _allExpanded = !allExpanded;
      for (final item in displayedItems) {
        _isExpanded[item.id] = _allExpanded;
      }

      _log.info('Setting all visible items to expanded: $_allExpanded');
    });
  }

  void _checkAndShowCompletionSnackbar() {
    bool allCompleted = _dailyThings.every((item) => item.completedForToday);

    if (allCompleted && !_hasShownCompletionSnackbar) {
      _log.info('All tasks completed, showing celebration snackbar.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Well done, all tasks done!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _hasShownCompletionSnackbar = true;
        _allTasksCompleted = true;
      });
      // ignore: use_build_context_synchronously
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('Well done! You did it!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("I'll do it again tomorrow"),
            ),
          ],
        ),
      );
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeShowMotivation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_motivationCheckedThisBuild) {
      _motivationCheckedThisBuild = true;
      _maybeShowMotivation();
    }
    _log.info('build called');
    List<DailyThing> displayedItems = _showOnlyDueItems
        ? _dailyThings
            .where((item) => item.isDueToday || item.hasBeenDoneLiterallyToday)
            .toList()
        : _dailyThings;

    if (_hideWhenDone) {
      displayedItems = displayedItems.where((item) {
        // For REPS items, hide when any actual value has been entered today
        if (item.itemType == ItemType.reps) {
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          // Check if there's any entry for today with actual value
          final hasActualValueToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate && entry.actualValue != null;
          });

          return !hasActualValueToday;
        }

        // For MINUTES and CHECK items, maintain existing behavior
        return !item.completedForToday;
      }).toList();
    }

    // Compute next undone index for the displayed list (after filters)
    final nextUndoneIndex = _getNextUndoneIndex(displayedItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Inc'),
        actions: [
          // Essential actions that should always be visible
          IconButton(
            tooltip:
                _hideWhenDone ? 'Show Completed Items' : 'Hide Completed Items',
            icon: Icon(
              _hideWhenDone ? Icons.filter_list : Icons.filter_list_off,
            ),
            onPressed: () async {
              final newValue = !_hideWhenDone;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hideWhenDone', newValue);
              setState(() {
                _hideWhenDone = newValue;
              });
            },
          ),

          IconButton(
            tooltip: _allExpanded ? 'Collapse all items' : 'Expand all items',
            icon: Icon(_allExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: _expandAllVisibleItems,
          ),
          IconButton(
            tooltip: 'Add an item',
            icon: Icon(
              Icons.add,
              color: _allTasksCompleted
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _openAddDailyItemPopup,
          ),
          // All other actions in a single overflow menu to prevent title cropping
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'toggle_due':
                  setState(() {
                    _showOnlyDueItems = !_showOnlyDueItems;
                  });
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsView(),
                    ),
                  ).then((_) => _refreshHideWhenDoneSetting());
                  break;
                case 'help':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpView(),
                    ),
                  );
                  break;
                case 'graphs':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryGraphView(dailyThings: _dailyThings),
                    ),
                  );
                  break;
                case 'load_history':
                  _loadHistoryFromFile();
                  break;
                case 'save_history':
                  _saveHistoryToFile();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_due',
                child: Row(
                  children: [
                    Icon(_showOnlyDueItems
                        ? Icons.visibility
                        : Icons.visibility_off),
                    const SizedBox(width: 8),
                    Text(_showOnlyDueItems
                        ? 'Show All Items'
                        : 'Show Due Items Only'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'graphs',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Category Graphs'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
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
                    Icon(Icons.save_alt),
                    SizedBox(width: 8),
                    Text('Save History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = displayedItems.removeAt(oldIndex);
            final originalIndex = _dailyThings.indexOf(item);
            _dailyThings.removeAt(originalIndex);

            if (newIndex < displayedItems.length) {
              final itemAtNewIndex = displayedItems[newIndex];
              final originalNewIndex = _dailyThings.indexOf(itemAtNewIndex);
              _dailyThings.insert(originalNewIndex, item);
            } else {
              _dailyThings.add(item);
            }
          });
          _dataManager.saveData(_dailyThings);
        },
        children: displayedItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            key: ValueKey(item.id),
            child: _buildItemRow(item, index, nextUndoneIndex),
          );
        }).toList(),
      ),
    );
  }
}
