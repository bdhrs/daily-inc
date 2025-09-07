import 'package:daily_inc/src/data/data_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/timer_view.dart';
import 'package:daily_inc/src/views/daily_thing_item.dart';
import 'package:daily_inc/src/views/reps_input_dialog.dart';
import 'package:daily_inc/src/views/percentage_input_dialog.dart';
import 'package:daily_inc/src/views/trend_input_dialog.dart';
import 'package:daily_inc/src/views/app_bar.dart';
import 'package:daily_inc/src/views/widgets/pulse.dart';
import 'package:daily_inc/src/views/widgets/reorder_helpers.dart';
import 'package:daily_inc/src/views/widgets/daily_things_helpers.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/views/widgets/visibility_and_expand_helpers.dart';
import 'package:daily_inc/src/views/widgets/filtering_helpers.dart';
import 'package:daily_inc/src/services/update_service.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

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
  bool _backupPromptCheckedThisBuild = false;
  bool _showArchivedItems =
      false; // New state variable for showing archived items

  // Motivational message settings
  bool _showStartOfDayMessage = false;
  String _startOfDayMessageText = 'Finish all your things today!';
  bool _showCompletionMessage = false;
  String _completionMessageText = 'Well done! You did it!';

  void _toggleShowOnlyDueItems() {
    setState(() {
      _showOnlyDueItems = !_showOnlyDueItems;
    });
  }

  /// Toggles between showing and hiding archived items
  void _toggleShowArchivedItems() {
    setState(() {
      _showArchivedItems = !_showArchivedItems;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _log.info('initState called');
    // Load settings first to ensure they're available for first build
    _loadHideWhenDoneSetting().then((_) {
      _loadMotivationalMessageSettings().then((_) {
        _loadData();
      });
    });
    _updateService.isUpdateAvailable().then((isAvailable) {
      _log.info('Update check completed. Result: $isAvailable');
      if (isAvailable && mounted) {
        _log.info('Update is available. Setting state to show indicator.');
        setState(() {
          _updateAvailable = true;
        });
      } else {
        _log.info('No update available or view is not mounted.');
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

  Future<void> _loadMotivationalMessageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showStartOfDayMessage = prefs.getBool('showStartOfDayMessage') ?? false;
    _startOfDayMessageText = prefs.getString('startOfDayMessageText') ??
        'Finish all your things today!';
    _showCompletionMessage = prefs.getBool('showCompletionMessage') ?? false;
    _completionMessageText =
        prefs.getString('completionMessageText') ?? 'Well done! You did it!';
    _log.info(
        'Loaded motivational message settings: startOfDay=$_showStartOfDayMessage, completion=$_showCompletionMessage');
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
    _loadMotivationalMessageSettings().then((_) {
      _maybeShowMotivation();
      _log.info('Refreshing display.');
      // Ensure a rebuild occurs immediately before async reload,
      // so UI reflects updated completion state without needing a second tap.
      if (mounted) {
        setState(() {});
      }
      _loadData();
    });
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
      // Set start date to today
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);

      final duplicatedItem = DailyThing(
        name: item.name,
        itemType: item.itemType,
        startDate:
            startDate, // Use today's date instead of the original item's start date
        startValue: item.startValue,
        duration: item.duration,
        endValue: item.endValue,
        icon: item.icon,
        nagTime: item.nagTime,
        nagMessage: item.nagMessage,
        history: [], // Empty history as required
        category: item.category,
        isPaused: item.isPaused,
        intervalType: item.intervalType,
        intervalValue: item.intervalValue,
        intervalWeekdays: item.intervalWeekdays,
        bellSoundPath: item.bellSoundPath,
        subdivisions: item.subdivisions,
        subdivisionBellSoundPath: item.subdivisionBellSoundPath,
      );

      // Instead of just adding to the end, insert right after the original item
      final items = await _dataManager.loadData();
      final originalIndex =
          items.indexWhere((element) => element.id == item.id);
      if (originalIndex != -1) {
        // Insert right after the original item
        items.insert(originalIndex + 1, duplicatedItem);
      } else {
        // If original item not found, add to the end (fallback)
        items.add(duplicatedItem);
      }
      await _dataManager.saveData(items);
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

  Future<bool> _handleSnooze(DailyThing item) {
    _log.info('Handling snooze for: ${item.name}');

    final itemIndex = _dailyThings.indexWhere((d) => d.id == item.id);
    if (itemIndex == -1) return Future.value(false);

    final currentItem = _dailyThings[itemIndex];
    final todayEntry = currentItem.todayHistoryEntry;

    final bool wasSnoozed = todayEntry?.snoozed ?? false;

    HistoryEntry updatedEntry;
    if (todayEntry != null) {
      updatedEntry = todayEntry.copyWith(snoozed: !wasSnoozed);
    } else {
      updatedEntry = HistoryEntry(
        date: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        targetValue: currentItem.todayValue,
        doneToday: false,
        snoozed: true,
      );
    }

    setState(() {
      final history = List<HistoryEntry>.from(currentItem.history);
      final entryIndex = history.indexWhere((e) => e.date == updatedEntry.date);

      if (entryIndex != -1) {
        history[entryIndex] = updatedEntry;
      } else {
        history.add(updatedEntry);
      }
      _dailyThings[itemIndex] = currentItem.copyWith(history: history);
    });

    _dataManager.updateDailyThing(_dailyThings[itemIndex]);
    _checkAndShowCompletionSnackbar();

    final bool willBeSnoozed = !wasSnoozed;
    if (willBeSnoozed && _hideWhenDone) {
      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }

  Future<void> _showFullscreenTimer(DailyThing item,
      {bool startInOvertime = false}) async {
    _log.info('Showing fullscreen timer for: ${item.name}');

    // Load minimalist mode preference
    final prefs = await SharedPreferences.getInstance();
    final minimalistMode = prefs.getBool('minimalistMode') ?? false;

    // Enable immersive mode when entering timer view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Find the index of the current item in the list
    final currentIndex =
        _dailyThings.indexWhere((thing) => thing.id == item.id);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerView(
          item: item,
          dataManager: _dataManager,
          onExitCallback: () {
            // Restore normal UI mode when exiting timer view
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            _refreshDisplay();
          },
          startInOvertime: startInOvertime,
          allItems: _dailyThings,
          currentItemIndex: currentIndex,
          initialMinimalistMode: minimalistMode,
        ),
      ),
    );
    _checkAndShowCompletionSnackbar();
  }

  void _showAboutDialog() async {
    _log.info('Showing about dialog.');
    final packageInfo = await PackageInfo.fromPlatform();
    final versionText = 'v${packageInfo.version}+${packageInfo.buildNumber}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Daily Inc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              versionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
                'Do the important things daily, and increase incrementally over time.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Vibe coded by bdhrs.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final url =
                    Uri.parse('https://github.com/bdhrs/daily-inc-timer');
                if (await launchUrl(url)) {
                  _log.info('Opened GitHub URL in browser');
                } else {
                  _log.warning('Could not launch GitHub URL');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open GitHub page.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'github.com/bdhrs/daily-inc-timer',
                style: TextStyle(
                  color: ColorPalette.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Licensed under Creative Commons',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                    'https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en');
                if (await launchUrl(url)) {
                  _log.info('Opened license URL in browser');
                } else {
                  _log.warning('Could not launch license URL');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open license page.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: NetworkImage(
                        'https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png'),
                    width: 88,
                    height: 31,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CC BY-NC-SA 4.0',
                    style: TextStyle(
                      color: ColorPalette.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowMotivation() async {
    // Check if start of day message is enabled
    if (!_showStartOfDayMessage) return;

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
          content: Text(_startOfDayMessageText),
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

  Future<void> _maybeShowBackupPrompt() async {
    // This functionality is removed for now.
  }

  Future<void> _resetAllData() async {
    _log.info('Resetting all data from main view...');
    try {
      await _dataManager.resetAllData();
      // Clear the in-memory list
      setState(() {
        _dailyThings = [];
      });
      _log.info('Data reset completed and UI cleared');
    } catch (e, s) {
      _log.severe('Error resetting data from main view', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting data: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
      onConfirmSnooze: _handleSnooze,
      showFullscreenTimer: _showFullscreenTimer,
      showRepsInputDialog: _showRepsInputDialog,
      showPercentageInputDialog: _showPercentageInputDialog,
      showTrendInputDialog: _showTrendInputDialog,
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

  void _showPercentageInputDialog(DailyThing item) {
    _log.info('Showing percentage input dialog for: ${item.name}');
    showDialog(
      context: context,
      builder: (context) => PercentageInputDialog(
        item: item,
        dataManager: _dataManager,
        onSuccess: _checkAndShowCompletionSnackbar,
      ),
    );
  }

  void _showTrendInputDialog(DailyThing item) {
    _log.info('Showing trend input dialog for: ${item.name}');
    showDialog(
      context: context,
      builder: (context) => TrendInputDialog(
        item: item,
        dataManager: _dataManager,
        onSuccess: _refreshDisplay,
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

  Future<void> _saveTemplateToFile() async {
    _log.info('Attempting to save template to file.');
    try {
      final ok = await _dataManager.saveTemplateToFile();
      if (!ok) {
        _log.info('Save template operation cancelled or failed.');
      }
    } catch (e, s) {
      _log.severe('Failed to save template', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
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
        showItemsDueToday: _showOnlyDueItems,
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
    // Exclude archived items from the completion check
    bool allCompleted = _dailyThings
        .where((item) => !item.isArchived)
        .every((item) => item.completedForToday);

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

      // Show completion dialog only if enabled and once per day
      _maybeShowCompletionDialog();
    } else if (!allCompleted) {
      setState(() {
        _hasShownCompletionSnackbar = false;
      });
    }
  }

  Future<void> _maybeShowCompletionDialog() async {
    // Check if completion message is enabled
    if (!_showCompletionMessage) return;

    try {
      final today = DateTime.now();
      final ymd =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final last = await _dataManager.getLastCompletionShownDate();
      if (last == ymd || !mounted) return;
      // ignore: use_build_context_synchronously
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(_completionMessageText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("I'll do it again tomorrow"),
            ),
          ],
        ),
      ).then((_) async {
        // Set the completion shown date after dialog is closed
        if (mounted) {
          await _dataManager.setLastCompletionShownDate(ymd);
        }
      });
    } catch (e, s) {
      _log.severe('Error showing completion dialog', e, s);
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

  Future<void> _loadTemplateFromFile() async {
    _log.info('Attempting to load template from file.');
    try {
      // Use DataManager's loadFromFile method which includes the fix for missing actual_value
      final loadedTemplateThings = await _dataManager.loadFromFile();

      if (loadedTemplateThings.isNotEmpty) {
        // Ask user whether to add or replace
        if (mounted) {
          final choice = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Load Template'),
              content: const Text(
                  'Do you want to add the template items to your existing items, or replace all your current items with the template?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('add'),
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('replace'),
                  child: const Text('Replace'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );

          if (choice == 'cancel' || choice == null) {
            _log.info('User cancelled template loading.');
            return;
          }

          // Create new items with today's date and no history
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          final newItems = loadedTemplateThings.map((templateItem) {
            return templateItem.copyWith(
              id: null, // Generate new IDs
              startDate: todayDate, // Set start date to today
              history: [], // Clear history
            );
          }).toList();

          setState(() {
            if (choice == 'replace') {
              _dailyThings = newItems;
            } else {
              // add
              _dailyThings.addAll(newItems);
            }
          });

          // Save the loaded data to the default storage
          await _dataManager.saveData(_dailyThings);
          _log.info(
              'Template loaded and saved to default storage successfully.');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Template ${choice == 'replace' ? 'replaced' : 'added'} successfully'),
                duration: const Duration(seconds: 2),
                backgroundColor:
                    Theme.of(context).snackBarTheme.backgroundColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        _log.info(
            'No template items loaded from file or file selection was cancelled.');
      }
    } catch (e, s) {
      _log.severe('Failed to load template', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load template: $e'),
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
    if (!_backupPromptCheckedThisBuild) {
      _backupPromptCheckedThisBuild = true;
      _maybeShowBackupPrompt();
    }
    _log.info('build called');
    // First, determine all items that are due today. This list is used to calculate the "all done" status.
    final List<DailyThing> dueItems = calculateDueItems(
      allItems: _dailyThings,
      showItemsDueToday: _showOnlyDueItems,
    );

    // Filter items based on archived status
    final List<DailyThing> filteredDueItems = _showArchivedItems
        ? dueItems
            .where((item) => item.isArchived)
            .toList() // Show only archived items
        : dueItems
            .where((item) => !item.isArchived)
            .toList(); // Show only non-archived items

    // The "all completed" status should be based on all due items, excluding archived items
    final allTasksCompleted = filteredDueItems.isNotEmpty &&
        filteredDueItems.every((item) => item.completedForToday);

    // Now, create the list of items to actually display, applying the "hide when done" filter.
    List<DailyThing> displayedItems = filteredDueItems;
    if (_hideWhenDone) {
      displayedItems = filteredDueItems.where((item) {
        if (item.isSnoozedForToday) {
          return false; // Always hide snoozed items when this filter is on
        }

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
        }

        // For CHECK items and fallback for others, use the original logic
        return !item.completedForToday;
      }).toList();
    }

    // Compute next undone index for the displayed list (after filters)
    final nextUndoneIndex = _getNextUndoneIndex(displayedItems);

    return Scaffold(
      appBar: DailyThingsAppBar(
        updateAvailable: _updateAvailable,
        onOpenAddDailyItemPopup: _openAddDailyItemPopup,
        onRefreshHideWhenDoneSetting: _refreshHideWhenDoneSetting,
        onRefreshDisplay: _refreshDisplay,
        onExpandAllVisibleItems: _expandAllVisibleItems,
        onLoadHistoryFromFile: _loadHistoryFromFile,
        onSaveHistoryToFile: _saveHistoryToFile,
        onLoadTemplateFromFile: _loadTemplateFromFile,
        onSaveTemplateToFile: _saveTemplateToFile,
        onResetAllData: _resetAllData,
        dailyThings: _dailyThings,
        hideWhenDone: _hideWhenDone,
        allExpanded: _allExpanded,
        showOnlyDueItems: _showOnlyDueItems,
        showArchivedItems: _showArchivedItems, // New parameter
        onShowAboutDialog: _showAboutDialog,
        onToggleShowOnlyDueItems: _toggleShowOnlyDueItems,
        onToggleShowArchivedItems: _toggleShowArchivedItems, // New parameter
        log: _log,
      ),
      body: SafeArea(
        child: ReorderableListView(
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
              child: _buildItemRow(
                  item, index, nextUndoneIndex, allTasksCompleted),
            );
          }).toList(),
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
        ),
      ),
    );
  }
}
