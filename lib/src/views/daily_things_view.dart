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
import 'package:daily_inc/src/views/widgets/reorder_helpers.dart';
import 'package:daily_inc/src/views/widgets/daily_things_helpers.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/views/widgets/visibility_and_expand_helpers.dart';
import 'package:daily_inc/src/services/update_service.dart';
import 'package:logging/logging.dart';

class DailyThingsView extends StatefulWidget {
  const DailyThingsView({super.key});

  @override
  State<DailyThingsView> createState() => _DailyThingsViewState();
}

class _DailyThingsViewState extends State<DailyThingsView>
    with WidgetsBindingObserver {
  final UpdateService _updateService = UpdateService();
  final DataManager _dataManager = DataManager();
  List<DailyThing> _dailyThings = [];
  final Map<String, bool> _isExpanded = {};
  final Map<String, GlobalKey> _expansionTileKeys = {};
  final _log = Logger('DailyThingsView');
  bool _hasShownCompletionSnackbar = false;
  bool _showOnlyDueItems = true;
  bool _hideWhenDone = false;
  bool _motivationCheckedThisBuild = false;
  bool _allExpanded = false;
  bool _updateAvailable = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _log.info('initState called');
    // Load settings first to ensure they're available for first build
    _loadHideWhenDoneSetting().then((_) {
      _loadData();
    });
    _updateService.isUpdateAvailable().then((isAvailable) {
      if (isAvailable && mounted) {
        _log.info('Update is available.');
        setState(() {
          _updateAvailable = true;
        });
      } else {
        _log.info('No update available.');
      }
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
    final bool shouldDelete = await confirmDeleteDialog(context, item.name);

    if (shouldDelete) {
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

  void _showFullscreenTimer(DailyThing item, {bool startInOvertime = false}) {
    _log.info('Showing fullscreen timer for: ${item.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerView(
          item: item,
          dataManager: _dataManager,
          onExitCallback: _refreshDisplay,
          startInOvertime: startInOvertime,
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
        _refreshDisplay();
      }
    } catch (e, s) {
      _log.severe('Error showing motivation dialog', e, s);
    }
  }

  Widget _buildItemRow(
      DailyThing item, int index, int nextUndoneIndex, bool allTasksCompleted) {
    // Initialize expansion state if not already set - always start closed
    _isExpanded.putIfAbsent(item.id, () => false);

    final dailyThingItem = DailyThingItem(
      item: item,
      dataManager: _dataManager,
      allTasksCompleted: allTasksCompleted,
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
      // Derive the exact Card radius from theme when available
      final ShapeBorder? cardShape = Theme.of(context).cardTheme.shape;
      final BorderRadiusGeometry? radius =
          cardShape is RoundedRectangleBorder ? cardShape.borderRadius : null;

      return Pulse(
        borderRadius: radius,
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
      final jsonData = {
        'dailyThings': _dailyThings.map((thing) => thing.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      final ok = await saveJsonToFile(context: context, json: jsonData);
      if (!ok) {
        _log.info('Save file operation cancelled or failed.');
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
    return getNextUndoneIndex(items);
  }

  void _expandAllVisibleItems() {
    _log.info('Toggling expansion of all visible items');
    setState(() {
      final displayedItems = filterDisplayedItems(
        allItems: _dailyThings,
        showOnlyDueItems: _showOnlyDueItems,
        hideWhenDone: _hideWhenDone,
      );

      _allExpanded = toggleExpansionForVisibleItems(
        visibleItems: displayedItems,
        isExpanded: _isExpanded,
        currentAllExpanded: _allExpanded,
      );

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
      });
    }
  }

  Future<void> _loadHistoryFromFile() async {
    _log.info('Attempting to load history from file.');
    try {
      // Use DataManager's loadFromFile method which includes the fix for missing actual_value
      final loadedThings = await _dataManager.loadFromFile();

      if (loadedThings.isNotEmpty) {
        setState(() {
          _dailyThings = loadedThings;
        });

        // Save the loaded data to the default storage
        await _dataManager.saveData(_dailyThings);
        _log.info('History loaded and saved to default storage successfully.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('History loaded successfully'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _log.info('No items loaded from file or file selection was cancelled.');
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
    // First, determine all items that are due today. This list is used to calculate the "all done" status.
    final List<DailyThing> dueItems = _showOnlyDueItems
        ? _dailyThings
            .where((item) => item.isDueToday || item.hasBeenDoneLiterallyToday)
            .toList()
        : _dailyThings;

    // The "all completed" status should be based on all due items, regardless of visibility.
    final allTasksCompleted =
        dueItems.isNotEmpty && dueItems.every((item) => item.completedForToday);

    // Now, create the list of items to actually display, applying the "hide when done" filter.
    List<DailyThing> displayedItems = dueItems;
    if (_hideWhenDone) {
      displayedItems = dueItems.where((item) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        // For REPS items, hide when any actual value has been entered today
        if (item.itemType == ItemType.reps) {
          final hasActualValueToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate && entry.actualValue != null;
          });

          return !hasActualValueToday;
        }

        // For MINUTES items, hide when there is any progress today (partial or completed)
        if (item.itemType == ItemType.minutes) {
          final hasProgressToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            if (entryDate != todayDate) return false;
            final actual = entry.actualValue ?? 0.0;
            return actual > 0.0 || entry.doneToday;
          });
          if (hasProgressToday) return false; // hide minutes if partial or done
          return !item.completedForToday;
        }

        // For CHECK items, maintain existing behavior
        return !item.completedForToday;
      }).toList();
    }

    // Compute next undone index for the displayed list (after filters)
    final nextUndoneIndex = _getNextUndoneIndex(displayedItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Inc',
          style: TextStyle(
            color: allTasksCompleted
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        actions: [
          if (_updateAvailable)
            Pulse(
              pulseColor: Theme.of(context).primaryColor,
              child: IconButton(
                tooltip: 'Update available',
                icon: const Icon(Icons.download),
                onPressed: () async {
                  final url = await _updateService.getDownloadUrl();
                  if (url != null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download started...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    final filePath = await _updateService.downloadUpdate(url);
                    if (filePath != null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Download finished!'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'Install',
                              onPressed: () async {
                                try {
                                  await _updateService.installUpdate(filePath);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Installation started...'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Installation failed: $e'),
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download failed.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not get download URL.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          // Essential actions that should always be visible
          IconButton(
            tooltip:
                _hideWhenDone ? 'Show Completed Items' : 'Hide Completed Items',
            icon: Icon(
              _hideWhenDone ? Icons.filter_list : Icons.filter_list_off,
              color: allTasksCompleted
                  ? Theme.of(context).colorScheme.primary
                  : null,
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
            icon: Icon(
              _allExpanded ? Icons.expand_less : Icons.expand_more,
              color: allTasksCompleted
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _expandAllVisibleItems,
          ),
          IconButton(
            tooltip: 'Add an item',
            icon: Icon(
              Icons.add,
              color: allTasksCompleted
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _openAddDailyItemPopup,
          ),
          // All other actions in a single overflow menu to prevent title cropping
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: Icon(
              Icons.more_vert,
              color: allTasksCompleted
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
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
      // Provide a proxyDecorator to ensure the dragged item keeps its identity by key
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            _dailyThings = reorderDailyThings(
              fullList: _dailyThings,
              displayedItems: displayedItems,
              oldIndex: oldIndex,
              newIndex: newIndex,
            );
          });
          _dataManager.saveData(_dailyThings);
        },
        children: displayedItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child:
                _buildItemRow(item, index, nextUndoneIndex, allTasksCompleted),
          );
        }).toList(),
      ),
    );
  }
}
