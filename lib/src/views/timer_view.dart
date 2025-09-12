import 'dart:async';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/views/helpers/audio_helper.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/helpers/timer_logic.dart';
import 'package:daily_inc/src/views/helpers/timer_state.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/widgets/next_task_arrow.dart';
import 'package:daily_inc/src/views/widgets/note_view.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/views/widgets/timer_display.dart';
import 'package:daily_inc/src/views/widgets/comment_input.dart';
import 'package:daily_inc/src/views/widgets/timer_controls.dart';
import 'package:daily_inc/src/views/widgets/subdivision_display.dart';
import 'package:daily_inc/src/views/widgets/dimming_overlay.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';

class TimerView extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onExitCallback;
  final bool startInOvertime;
  final List<DailyThing>? allItems; // All items in the list for navigation
  final int? currentItemIndex; // Index of current item in the list
  final String?
      nextTaskName; // Name of the next task (for display when navigating)
  final bool initialMinimalistMode;

  const TimerView({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onExitCallback,
    this.startInOvertime = false,
    this.allItems,
    this.currentItemIndex,
    this.nextTaskName,
    this.initialMinimalistMode = false,
  });

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late double _remainingSeconds;
  bool _isPaused = true;
  bool _hasStarted = false;
  Timer? _timer;
  bool _isOvertime = false;
  double _overtimeSeconds = 0.0;
  int _completedSubdivisions = 0;
  // High-resolution timing variables for precise subdivision synchronization
  double _preciseElapsedSeconds = 0.0;
  double _preciseSubdivisionInterval = 0.0;
  int _lastTriggeredSubdivision = -1;
  final AudioHelper _audioHelper = AudioHelper();
  final _log = Logger('TimerView');
  final _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  // No longer needed - subdivisions are always shown when set
  // bool _showSubdivisions = true;

  // Next task navigation variables
  bool _showNextTaskArrow = false;
  bool _showNextTaskName = false;
  String _nextTaskName = '';
  Timer? _nextTaskNameTimer;

  late double _todaysTargetMinutes;

  // Screen dimmer variables
  bool _dimScreenMode = false;
  bool _isDimming = false;
  Timer? _dimTimer;
  double _dimOpacity = 0.0;

  // Minimalist mode variable
  bool _minimalistMode = false;

  // Variables for fading out UI elements in minimalist mode
  bool _shouldFadeUI = false;
  Timer? _fadeUITimer;

  // Note view mode variable and current item reference
  bool _isNoteViewMode = false;
  late DailyThing _currentItem;

  Future<void> _loadDimScreenPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dimScreenMode = prefs.getBool('dimScreenMode') ?? false;
    });
  }

  Future<void> _saveDimScreenPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dimScreenMode', value);
  }

  Future<void> _loadMinimalistModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _minimalistMode = prefs.getBool('minimalistMode') ?? false;
    });
  }

  Future<void> _saveMinimalistModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('minimalistMode', value);
  }

  /// Shows the note dialog directly in edit mode for the Note View
  void _showNoteDialogInEditMode() {
    final notesController = TextEditingController(text: _currentItem.notes);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate a dynamic font size based on the available height
                final double fontSize = constraints.maxHeight / 20;

                return SingleChildScrollView(
                  child: TextField(
                    controller: notesController,
                    autofocus: true,
                    decoration:
                        const InputDecoration(hintText: 'Enter your note...'),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontSize: fontSize),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedItem =
                    _currentItem.copyWith(notes: notesController.text);
                await widget.dataManager.updateDailyThing(updatedItem);
                Navigator.of(context).pop();
                // Update the current item with the new notes and stay in note view mode
                if (mounted) {
                  setState(() {
                    _currentItem = updatedItem;
                    _isNoteViewMode = true;
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _toggleDimScreenMode() {
    setState(() {
      _dimScreenMode = !_dimScreenMode;
    });
    _saveDimScreenPreference(_dimScreenMode);

    // If the timer is running and we're now in dim mode, start dimming immediately
    if (!_isPaused && _dimScreenMode) {
      _startDimmingProcess();
    }
    // If we're turning off dim mode, restore screen brightness
    else if (!_dimScreenMode) {
      _restoreScreenBrightness();
    }
  }

  void _toggleMinimalistMode() {
    setState(() {
      _minimalistMode = !_minimalistMode;

      // Cancel fade UI timer when toggling minimalist mode
      _cancelFadeUITimer();

      // If turning off minimalist mode, make UI visible again
      if (!_minimalistMode) {
        _shouldFadeUI = false;
      }
    });
    _saveMinimalistModePreference(_minimalistMode);
  }

  void _toggleNoteViewMode() {
    setState(() {
      _isNoteViewMode = !_isNoteViewMode;
    });
  }

  void _startFadeUITimer() {
    // Cancel any existing fade timer
    _cancelFadeUITimer();

    // Start a new timer to fade UI after 1 second
    _fadeUITimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _shouldFadeUI = true;
        });
      }
    });
  }

  void _cancelFadeUITimer() {
    _fadeUITimer?.cancel();
    _fadeUITimer = null;

    // Make UI visible again when canceling
    if (_shouldFadeUI) {
      setState(() {
        _shouldFadeUI = false;
      });
    }
  }

  void _startDimmingProcess() {
    // Check if we should dim the screen
    if (!_dimScreenMode || _isDimming || _isPaused) return;

    _isDimming = true;
    // Reset opacity when starting dimming process
    setState(() {
      _dimOpacity = 0.0;
    });

    const totalDimmingTime = 10.0; // 10 seconds
    const updateInterval = 50; // milliseconds
    final opacityStep = 1.0 / (totalDimmingTime * 1000 / updateInterval);

    _dimTimer = Timer.periodic(Duration(milliseconds: updateInterval), (timer) {
      setState(() {
        _dimOpacity += opacityStep;
        if (_dimOpacity >= 1.0) {
          _dimOpacity = 1.0;
          _isDimming = false;
          timer.cancel();
        }
      });
    });
  }

  void _restoreScreenBrightness() {
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    _isDimming = false;
    _dimTimer?.cancel();
    setState(() {
      _dimOpacity = 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize the current item reference
    _currentItem = widget.item;

    // Set initial minimalist mode from parameter
    _minimalistMode = widget.initialMinimalistMode;

    // Load dim screen mode preference
    _loadDimScreenPreference();
    // Load minimalist mode preference (may override if different)
    _loadMinimalistModePreference();

    // Initialize next task name if provided
    if (widget.nextTaskName != null) {
      _nextTaskName = widget.nextTaskName!;
      _showNextTaskName = true;

      // Set timer to start fading out the name after 8 seconds, fully hidden by 10 seconds
      _nextTaskNameTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showNextTaskName =
                false; // This will trigger the fade-out animation
          });
        }
      });
    }

    // Initialize timer state using helper
    final initialState = TimerStateHelper.initializeTimerState(
      item: widget.item,
      startInOvertime: widget.startInOvertime,
      commentController: _commentController,
      currentItem: _currentItem,
    );

    // Update state variables with initialized values
    _todaysTargetMinutes = initialState['todaysTargetMinutes'] as double;
    _isOvertime = initialState['isOvertime'] as bool;
    _isPaused = initialState['isPaused'] as bool;
    _hasStarted = initialState['hasStarted'] as bool;
    _remainingSeconds = initialState['remainingSeconds'] as double;
    _overtimeSeconds = initialState['overtimeSeconds'] as double;
    _completedSubdivisions = initialState['completedSubdivisions'] as int;
    _commentFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _log.info('dispose called');
    _timer?.cancel();
    _dimTimer?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _audioHelper.dispose();
    _nextTaskNameTimer?.cancel();
    _fadeUITimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleTimer() {
    _log.info('toggleTimer called, isPaused is now ${!_isPaused}');
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _log.info('Timer started, enabling wakelock.');
        _hasStarted = true;
        WakelockPlus.enable();

        // Start dimming process if enabled
        if (_dimScreenMode) {
          _startDimmingProcess();
        }

        // Start fade UI timer if in minimalist mode
        if (_minimalistMode) {
          _startFadeUITimer();
        }

        final bool isFinished = _remainingSeconds <= 0 && !_isOvertime;
        // Only hide subdivisions when timer finishes, not in overtime mode
        if (isFinished && !_isOvertime) {
          setState(() {
            // No longer needed - subdivisions are always shown when set
          });
        }
        _log.info(
            'isFinished: $isFinished, _remainingSeconds: $_remainingSeconds, _isOvertime: $_isOvertime');
        if (isFinished) {
          _log.info('Timer is finished, starting overtime mode');
          // Timer is finished, start overtime mode
          _isOvertime = true;
          // Ensure subdivisions are visible in overtime mode
          setState(() {});
          _runOvertime();
        } else if (_isOvertime) {
          _log.info('Running overtime timer');
          _runOvertime();
        } else {
          _log.info('Running countdown timer');
          _runCountdown();
        }
      } else {
        _log.info('Timer paused, disabling wakelock.');
        _timer?.cancel();
        WakelockPlus.disable();

        // Ensure UI is visible when pausing
        _shouldFadeUI = false;
        _fadeUITimer?.cancel();
        _fadeUITimer = null;
      }
    });
  }

  void _runOvertime() {
    final subdivisions = _currentItem.subdivisions;
    final totalSeconds = (_todaysTargetMinutes * 60);

    // Calculate precise subdivision interval without rounding
    if (subdivisions != null && subdivisions > 1) {
      _preciseSubdivisionInterval = totalSeconds / subdivisions;
      _preciseElapsedSeconds = totalSeconds + _overtimeSeconds;
      _lastTriggeredSubdivision =
          (_preciseElapsedSeconds / _preciseSubdivisionInterval).floor();
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) {
        timer.cancel();
        return;
      }

      setState(() {
        _overtimeSeconds += 0.1; // 100ms increments
        _preciseElapsedSeconds = totalSeconds + _overtimeSeconds;

        // Check if we've crossed a subdivision boundary in overtime
        if (_preciseSubdivisionInterval > 0) {
          final currentSubdivision =
              (_preciseElapsedSeconds / _preciseSubdivisionInterval).floor();

          // Only play bell when we cross into a new subdivision
          if (currentSubdivision > _lastTriggeredSubdivision &&
              currentSubdivision > 0) {
            _audioHelper.playSubdivisionBell(_currentItem);
            _lastTriggeredSubdivision = currentSubdivision;
            _completedSubdivisions = currentSubdivision;
          }
        }
      });
    });
  }

  void _runCountdown() {
    _log.info('runCountdown called with $_remainingSeconds seconds remaining');

    // Check if timer is already at 0 and complete immediately
    if (_remainingSeconds <= 0) {
      _log.info('Timer already at zero, completing immediately.');
      _onTimerComplete();
      return;
    }

    final subdivisions = _currentItem.subdivisions;
    if (subdivisions != null && subdivisions > 1) {
      final totalSeconds = (_todaysTargetMinutes * 60);

      // Calculate precise subdivision interval without rounding
      _preciseSubdivisionInterval = totalSeconds / subdivisions;
      _preciseElapsedSeconds = totalSeconds - _remainingSeconds;
      _lastTriggeredSubdivision =
          (_preciseElapsedSeconds / _preciseSubdivisionInterval).floor();

      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds -= 0.1; // 100ms decrements
          _preciseElapsedSeconds = totalSeconds - _remainingSeconds;

          // Check for immediate completion when reaching 0
          if (_remainingSeconds <= 0) {
            _log.info('Timer completed at zero.');
            timer.cancel();
            _onTimerComplete();
            return;
          }

          // Check if we've crossed a subdivision boundary
          if (_preciseSubdivisionInterval > 0) {
            final currentSubdivision =
                (_preciseElapsedSeconds / _preciseSubdivisionInterval).floor();

            // Only play bell when we cross into a new subdivision (and not at the very start)
            if (currentSubdivision > _lastTriggeredSubdivision &&
                currentSubdivision > 0) {
              _audioHelper.playSubdivisionBell(_currentItem);
              _lastTriggeredSubdivision = currentSubdivision;
              _completedSubdivisions = currentSubdivision;
            }
          }
        });
      });
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds -= 0.1; // 100ms decrements

          // Check for immediate completion when reaching 0
          if (_remainingSeconds <= 0) {
            _log.info('Timer completed at zero.');
            timer.cancel();
            _onTimerComplete();
            return;
          }
        });
      });
    }
  }

  void _onTimerComplete() async {
    _log.info('onTimerComplete called');

    // Restore screen brightness when timer completes
    if (_dimScreenMode) {
      _restoreScreenBrightness();
    }

    // Play the bell sound immediately for instant feedback
    _audioHelper.playTimerCompleteNotification(_currentItem);

    // Update UI state immediately to show completion
    setState(() {
      _isPaused = true;
      _shouldFadeUI = false;
      if (_currentItem.subdivisions != null && _currentItem.subdivisions! > 1) {
        _completedSubdivisions = _currentItem.subdivisions!;
      }
      _log.info('Timer paused in onTimerComplete');

      // Show the next task arrow when timer completes
      _showNextTaskArrow = true;
    });

    // Cancel fade UI timer when timer completes
    _fadeUITimer?.cancel();
    _fadeUITimer = null;

    // Disable wakelock immediately
    WakelockPlus.disable();
    _log.info('Wakelock disabled.');

    // Perform heavy operations (file I/O) after the bell has started playing
    await _saveProgress();
    _log.info('Progress saved in onTimerComplete');
  }

  Future<void> _exitTimerDisplay() async {
    _log.info('exitTimerDisplay called');
    _log.info(
        'Conditions: _hasStarted=$_hasStarted, _remainingSeconds=$_remainingSeconds, _isOvertime=$_isOvertime');

    // Pause the timer and update the UI before showing any dialogs
    if (!_isPaused) {
      setState(() {
        _isPaused = true;
      });
    }

    _timer?.cancel();
    _dimTimer?.cancel(); // Cancel dimming timer if active
    _log.info('Timer stopped');
    WakelockPlus.disable();

    // Restore screen brightness when exiting
    if (_dimScreenMode) {
      _restoreScreenBrightness();
    }

    // If exiting during overtime, the 'done' state is already saved.
    // We just need to update with the final overtime value.
    if (_isOvertime) {
      await _saveProgress();
    }
    // If we have partial progress, show a confirmation dialog.
    else if (_hasStarted && _remainingSeconds > 0) {
      final shouldSave = await _showSaveDialog();
      if (shouldSave == true) {
        await _saveProgress();
      } else if (shouldSave == false) {
        await _saveCommentOnly();
      } else if (shouldSave == null) {
        return; // User cancelled, so don't exit.
      }
    }
    // If the timer finished but isn't in overtime yet, save it.
    else if (_hasStarted && _remainingSeconds <= 0 && !_isOvertime) {
      await _saveProgress();
    }
    // Otherwise, no progress needs to be saved.
    else {
      await _saveCommentOnly();
      _log.info('No save condition met, exiting.');
    }

    // Save the minimalist mode preference when exiting
    await _saveMinimalistModePreference(_minimalistMode);

    widget.onExitCallback();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showSaveDialog({bool isOvertime = false}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isOvertime ? 'Save Total Time?' : 'Save Progress?'),
          content: Text(
            isOvertime
                ? 'You have finished your goal and completed extra time. Would you like to save the total time?'
                : 'You have incomplete progress. Would you like to save your current time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Don't Save"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProgress() async {
    final today = DateUtils.dateOnly(DateTime.now());
    // Use epsilon comparison to handle floating-point precision issues
    final epsilon = 0.0001; // Small tolerance for floating-point comparison
    final elapsed = TimerLogicHelper.calculateCurrentElapsedTimeInMinutes(
      isOvertime: _isOvertime,
      hasStarted: _hasStarted,
      todaysTargetMinutes: _todaysTargetMinutes,
      remainingSeconds: _remainingSeconds,
      overtimeSeconds: _overtimeSeconds,
      currentItem: _currentItem,
    );
    final target = _todaysTargetMinutes;
    final isDone = (elapsed - target).abs() < epsilon || elapsed > target;

    _log.info(
        'Saving progress. Done: $isDone, Time: ${TimerLogicHelper.calculateCurrentElapsedTimeInMinutes(
      isOvertime: _isOvertime,
      hasStarted: _hasStarted,
      todaysTargetMinutes: _todaysTargetMinutes,
      remainingSeconds: _remainingSeconds,
      overtimeSeconds: _overtimeSeconds,
      currentItem: _currentItem,
    ).toStringAsFixed(2)} min');

    final newEntry = HistoryEntry(
      date: today,
      targetValue: _todaysTargetMinutes,
      doneToday: isDone,
      actualValue: TimerLogicHelper.calculateCurrentElapsedTimeInMinutes(
        isOvertime: _isOvertime,
        hasStarted: _hasStarted,
        todaysTargetMinutes: _todaysTargetMinutes,
        remainingSeconds: _remainingSeconds,
        overtimeSeconds: _overtimeSeconds,
        currentItem: _currentItem,
      ),
      comment: _commentController.text,
    );

    // Remove any existing entry for today to prevent duplicates.
    // This ensures we are always updating or creating the day's progress.
    final updatedHistory = _currentItem.history
        .where((entry) => !DateUtils.isSameDay(entry.date, today))
        .toList()
      ..add(newEntry);

    final updatedItem = _createUpdatedItem(updatedHistory);
    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info('Progress saved successfully.');
  }

  Future<void> _saveCommentOnly() async {
    final today = DateUtils.dateOnly(DateTime.now());
    HistoryEntry? todayEntry;
    int todayEntryIndex = -1;

    for (int i = 0; i < _currentItem.history.length; i++) {
      if (DateUtils.isSameDay(_currentItem.history[i].date, today)) {
        todayEntry = _currentItem.history[i];
        todayEntryIndex = i;
        break;
      }
    }

    final currentComment = _commentController.text;

    // If the comment is the same, no need to save.
    if (todayEntry != null && todayEntry.comment == currentComment) {
      return;
    }

    // If the comment is empty and there's no existing entry, no need to save.
    if (todayEntry == null && currentComment.isEmpty) {
      return;
    }

    final updatedHistory = List<HistoryEntry>.from(_currentItem.history);

    if (todayEntry != null) {
      // Update existing entry
      final updatedEntry = todayEntry.copyWith(comment: currentComment);
      updatedHistory[todayEntryIndex] = updatedEntry;
    } else {
      // Add new entry if comment is not empty
      if (currentComment.isNotEmpty) {
        final newEntry = HistoryEntry(
          date: today,
          targetValue: _todaysTargetMinutes,
          doneToday: false,
          actualValue: 0,
          comment: currentComment,
        );
        updatedHistory.add(newEntry);
      }
    }

    final updatedItem = _createUpdatedItem(updatedHistory);
    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info('Comment saved successfully.');
  }

  /// Navigates to the next task or exits to main UI
  void _navigateToNextTask() async {
    final nextTask = TimerStateHelper.findNextUndoneTask(
      allItems: widget.allItems,
      currentItemIndex: widget.currentItemIndex,
    );

    if (nextTask == null) {
      // No more tasks, exit to main UI
      await _exitTimerDisplay();
      return;
    }

    // Cancel any existing timer for showing task name
    _nextTaskNameTimer?.cancel();

    String? nextTaskName;
    // If it's another timer, prepare its name for display
    if (nextTask.itemType == ItemType.minutes) {
      nextTaskName = nextTask.name;
    }

    // Navigate to the next task
    if (mounted) {
      // Cancel current timer
      _timer?.cancel();
      _dimTimer?.cancel();
      WakelockPlus.disable();

      // Save current progress first
      await _saveProgress();

      if (nextTask.itemType == ItemType.minutes) {
        // Navigate to the next timer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerView(
              item: nextTask,
              dataManager: widget.dataManager,
              onExitCallback: widget.onExitCallback,
              allItems: widget.allItems,
              currentItemIndex: widget.allItems?.indexOf(nextTask),
              nextTaskName: nextTaskName, // Pass the next task name
              initialMinimalistMode: _minimalistMode,
            ),
          ),
        );
      } else {
        // For other task types, exit to main UI
        widget.onExitCallback();
        Navigator.of(context).pop();
      }
    }
  }

  DailyThing _createUpdatedItem(List<HistoryEntry> updatedHistory) {
    return DailyThing(
      id: _currentItem.id,
      icon: _currentItem.icon,
      name: _currentItem.name,
      itemType: _currentItem.itemType,
      startDate: _currentItem.startDate,
      startValue: _currentItem.startValue,
      duration: _currentItem.duration,
      endValue: _currentItem.endValue,
      history: updatedHistory,
      nagTime: _currentItem.nagTime,
      nagMessage: _currentItem.nagMessage,
      category: _currentItem.category,
      isPaused: _currentItem.isPaused,
      intervalType: _currentItem.intervalType,
      intervalValue: _currentItem.intervalValue,
      intervalWeekdays: _currentItem.intervalWeekdays,
      bellSoundPath: _currentItem.bellSoundPath, // Pass the bell sound path
      subdivisions: _currentItem.subdivisions,
      subdivisionBellSoundPath: _currentItem.subdivisionBellSoundPath,
      notes: _currentItem.notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If in note view mode, render the note view UI instead
    if (_isNoteViewMode) {
      return NoteViewWidget(
        currentItem: _currentItem,
        isOvertime: _isOvertime,
        isPaused: _isPaused,
        todaysTargetMinutes: _todaysTargetMinutes,
        overtimeSeconds: _overtimeSeconds,
        currentElapsedTimeInMinutes:
            TimerLogicHelper.calculateCurrentElapsedTimeInMinutes(
          isOvertime: _isOvertime,
          hasStarted: _hasStarted,
          todaysTargetMinutes: _todaysTargetMinutes,
          remainingSeconds: _remainingSeconds,
          overtimeSeconds: _overtimeSeconds,
          currentItem: _currentItem,
        ),
        completedSubdivisions: _completedSubdivisions,
        subdivisions: _currentItem.subdivisions,
        getButtonText: _getButtonText,
        toggleTimer: _toggleTimer,
        toggleNoteViewMode: _toggleNoteViewMode,
        showNoteDialogInEditMode: _showNoteDialogInEditMode,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        _log.info('System back button pressed');

        // If timer is running, pause it first, then exit.
        if (!_isPaused) {
          _toggleTimer();
        }
        await _exitTimerDisplay();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ColorPalette.darkBackground,
            appBar: AppBar(
              backgroundColor: ColorPalette.darkBackground,
              automaticallyImplyLeading: !(_minimalistMode && !_isPaused),
              leading: (_minimalistMode && !_isPaused)
                  ? AnimatedOpacity(
                      opacity: _shouldFadeUI ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          _log.info('Back button pressed');
                          // If timer is running, pause it first, then exit.
                          if (!_isPaused) {
                            _toggleTimer();
                          }
                          await _exitTimerDisplay();
                        },
                      ),
                    )
                  : null,
              actions: [
                if (!(_minimalistMode && !_isPaused))
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String result) {
                      if (result == 'toggle') {
                        _toggleDimScreenMode();
                      } else if (result == 'minimalist') {
                        _toggleMinimalistMode();
                      } else if (result == 'edit') {
                        _editItem();
                      } else if (result == 'show_note_view') {
                        _toggleNoteViewMode();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(_dimScreenMode
                                ? Icons.brightness_high
                                : Icons.brightness_low),
                            const SizedBox(width: 8),
                            Text(_dimScreenMode
                                ? 'Turn Dim Screen Off'
                                : 'Turn Dim Screen On'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'minimalist',
                        child: Row(
                          children: [
                            Icon(_minimalistMode
                                ? Icons.fullscreen
                                : Icons.aspect_ratio),
                            const SizedBox(width: 8),
                            Text(_minimalistMode
                                ? 'Turn Minimalist Mode Off'
                                : 'Turn Minimalist Mode On'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            const Text('Edit Item'),
                          ],
                        ),
                      ),
                      if (_currentItem.notes != null &&
                          _currentItem.notes!.isNotEmpty)
                        PopupMenuItem<String>(
                          value: 'show_note_view',
                          child: Row(
                            children: [
                              const Icon(Icons.note),
                              const SizedBox(width: 8),
                              const Text('Show Note View'),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  AnimatedOpacity(
                    opacity: _shouldFadeUI ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == 'toggle') {
                          _toggleDimScreenMode();
                        } else if (result == 'minimalist') {
                          _toggleMinimalistMode();
                        } else if (result == 'edit') {
                          _editItem();
                        } else if (result == 'show_note_view') {
                          _toggleNoteViewMode();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(_dimScreenMode
                                  ? Icons.brightness_high
                                  : Icons.brightness_low),
                              const SizedBox(width: 8),
                              Text(_dimScreenMode
                                  ? 'Turn Dim Screen Off'
                                  : 'Turn Dim Screen On'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'minimalist',
                          child: Row(
                            children: [
                              Icon(_minimalistMode
                                  ? Icons.fullscreen
                                  : Icons.aspect_ratio),
                              const SizedBox(width: 8),
                              Text(_minimalistMode
                                  ? 'Turn Minimalist Mode Off'
                                  : 'Turn Minimalist Mode On'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 8),
                              const Text('Edit Item'),
                            ],
                          ),
                        ),
                        if (_currentItem.notes != null &&
                            _currentItem.notes!.isNotEmpty)
                          PopupMenuItem<String>(
                            value: 'show_note_view',
                            child: Row(
                              children: [
                                const Icon(Icons.note),
                                const SizedBox(width: 8),
                                const Text('Show Note View'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              title: AnimatedOpacity(
                opacity: _minimalistMode && !_isPaused
                    ? (_shouldFadeUI ? 0.0 : 1.0)
                    : 1.0,
                duration: const Duration(milliseconds: 500),
                child: (widget.nextTaskName != null && _showNextTaskName
                    ? Text(
                        _nextTaskName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        _currentItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
              ),
              centerTitle: true,
              elevation: 0,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: !_minimalistMode
                          ? SubdivisionDisplayWidget(
                              key: const ValueKey('full_mode_subdivisions'),
                              isOvertime: _isOvertime,
                              completedSubdivisions: _completedSubdivisions,
                              totalSubdivisions: _currentItem.subdivisions,
                              todaysTargetMinutes: _todaysTargetMinutes,
                              overtimeSeconds: _overtimeSeconds,
                              currentElapsedTimeInMinutes: TimerLogicHelper
                                  .calculateCurrentElapsedTimeInMinutes(
                                isOvertime: _isOvertime,
                                hasStarted: _hasStarted,
                                todaysTargetMinutes: _todaysTargetMinutes,
                                remainingSeconds: _remainingSeconds,
                                overtimeSeconds: _overtimeSeconds,
                                currentItem: _currentItem,
                              ),
                              formatMinutesToMmSs:
                                  TimerLogicHelper.formatMinutesToMmSs,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('minimalist_mode')),
                    ),
                    Expanded(
                      child: TimerDisplayWidget(
                        totalTime: _todaysTargetMinutes,
                        elapsedTime: TimerLogicHelper
                            .calculateCurrentElapsedTimeInMinutes(
                          isOvertime: _isOvertime,
                          hasStarted: _hasStarted,
                          todaysTargetMinutes: _todaysTargetMinutes,
                          remainingSeconds: _remainingSeconds,
                          overtimeSeconds: _overtimeSeconds,
                          currentItem: _currentItem,
                        ),
                        subdivisions: _currentItem.subdivisions ?? 0,
                        onTap: _toggleTimer,
                        isOvertime: _isOvertime,
                      ),
                    ),
                    // Comment field - always present in layout but visibility controlled by logic
                    SizedBox(
                      height: 50, // Fixed height to prevent layout shifts
                      child: CommentInputWidget(
                        commentController: _commentController,
                        commentFocusNode: _commentFocusNode,
                        minimalistMode: _minimalistMode,
                        isOvertime: _isOvertime,
                        isPaused: _isPaused,
                        remainingSeconds: _remainingSeconds,
                        shouldFadeUI: _shouldFadeUI,
                        onTap: () {
                          FocusScope.of(context)
                              .requestFocus(_commentFocusNode);
                        },
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: !_minimalistMode
                          ? TimerControlsWidget(
                              key: const ValueKey('full_mode_controls'),
                              getButtonText: _getButtonText,
                              toggleTimer: _toggleTimer,
                              exitTimerDisplay: _exitTimerDisplay,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('minimalist_mode_controls')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dimming overlay
          DimmingOverlayWidget(
            dimScreenMode: _dimScreenMode,
            dimOpacity: _dimOpacity,
            isPaused: _isPaused,
            startDimmingProcess: _startDimmingProcess,
            restoreScreenBrightness: _restoreScreenBrightness,
          ),
          // Next task arrow button
          NextTaskArrow(
            onTap: _navigateToNextTask,
            isVisible: _showNextTaskArrow,
            isOvertime: _isOvertime,
            isMinimalistMode: _minimalistMode,
            isPaused: _isPaused,
            shouldFadeUI: _shouldFadeUI,
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_remainingSeconds <= 0 && !_isOvertime) {
      return 'Continue';
    }
    if (_isOvertime) {
      return _isPaused ? 'Continue' : 'Pause';
    }
    return _isPaused ? 'Start' : 'Pause';
  }

  void _editItem() async {
    _log.info('Editing item: ${_currentItem.name}');

    // Cancel any running timer
    _timer?.cancel();

    // Restore screen brightness if dimming is active
    if (_dimScreenMode) {
      _restoreScreenBrightness();
    }

    // Disable wakelock
    WakelockPlus.disable();

    final updatedItem = await Navigator.push<DailyThing>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDailyItemView(
          dataManager: widget.dataManager,
          dailyThing: _currentItem,
          onSubmitCallback: () {
            _log.info('Edit item callback triggered.');
          },
        ),
      ),
    );

    if (updatedItem != null) {
      _log.info('Item updated: ${updatedItem.name}');

      // Update the current item reference
      if (mounted) {
        setState(() {
          _currentItem = updatedItem;
        });
      }
    } else {
      _log.info('Edit cancelled.');

      // Resume timer if it was running before editing
      if (!_isPaused && mounted) {
        WakelockPlus.enable();
        if (_dimScreenMode) {
          _startDimmingProcess();
        }

        if (_isOvertime) {
          _runOvertime();
        } else {
          _runCountdown();
        }
      }
    }
  }
}
