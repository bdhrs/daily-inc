import 'dart:async';
import 'dart:io';

import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/services/notification_service.dart';
import 'package:daily_inc/src/views/helpers/audio_helper.dart';
import 'package:daily_inc/src/models/history_entry.dart';
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

class StopwatchView extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onExitCallback;
  final List<DailyThing>? allItems;
  final int? currentItemIndex;
  final String? nextTaskName;
  final bool initialMinimalistMode;

  const StopwatchView({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onExitCallback,
    this.allItems,
    this.currentItemIndex,
    this.nextTaskName,
    this.initialMinimalistMode = false,
  });

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView> {
  double _elapsedSeconds = 0.0;
  bool _isPaused = true;
  bool _hasStarted = false;
  Timer? _timer;
  int _completedSubdivisions = 0;
  double _preciseSubdivisionInterval = 0.0;
  int _lastTriggeredSubdivision = -1;
  final AudioHelper _audioHelper = AudioHelper();
  final _log = Logger('StopwatchView');
  final _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  final bool _showNextTaskArrow = false;
  bool _showNextTaskName = false;
  String _nextTaskName = '';
  Timer? _nextTaskNameTimer;

  bool _dimScreenMode = false;
  bool _isDimming = false;
  Timer? _dimTimer;
  double _dimOpacity = 0.0;

  bool _minimalistMode = false;
  bool _shouldFadeUI = false;
  Timer? _fadeUITimer;

  bool _isNoteViewMode = false;
  late DailyThing _currentItem;

  double _todaysAccumulatedMinutes = 0.0;

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
                final double fontSize = constraints.maxHeight / 20;

                return SingleChildScrollView(
                  child: TextField(
                    controller: notesController,
                    autofocus: true,
                    textCapitalization: Platform.isAndroid
                        ? TextCapitalization.words
                        : TextCapitalization.none,
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

    if (!_isPaused && _dimScreenMode) {
      _startDimmingProcess();
    } else if (!_dimScreenMode) {
      _restoreScreenBrightness();
    }
  }

  void _toggleMinimalistMode() {
    setState(() {
      _minimalistMode = !_minimalistMode;
      _cancelFadeUITimer();
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
    _cancelFadeUITimer();
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
    if (_shouldFadeUI) {
      setState(() {
        _shouldFadeUI = false;
      });
    }
  }

  void _startDimmingProcess() {
    if (!_dimScreenMode || _isDimming || _isPaused) return;

    _isDimming = true;
    setState(() {
      _dimOpacity = 0.0;
    });

    const totalDimmingTime = 10.0;
    const updateInterval = 50;
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
    _currentItem = widget.item;
    _minimalistMode = widget.initialMinimalistMode;

    _loadDimScreenPreference();
    _loadMinimalistModePreference();

    if (widget.nextTaskName != null) {
      _nextTaskName = widget.nextTaskName!;
      _showNextTaskName = true;
      _nextTaskNameTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showNextTaskName = false;
          });
        }
      });
    }

    _initializeState();
    _commentFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _initializeState() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final entry in _currentItem.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate && entry.actualValue != null) {
        _todaysAccumulatedMinutes = entry.actualValue!;
        _elapsedSeconds = _todaysAccumulatedMinutes * 60;
        break;
      }
    }

    _commentController.text = _currentItem.todayHistoryEntry?.comment ?? '';
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

  void _toggleStopwatch() {
    _log.info('toggleStopwatch called, isPaused is now ${!_isPaused}');
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _log.info('Stopwatch started, enabling wakelock.');
        _hasStarted = true;
        WakelockPlus.enable();

        if (_dimScreenMode) {
          _startDimmingProcess();
        }

        if (_minimalistMode) {
          _startFadeUITimer();
        }

        _runStopwatch();
      } else {
        _log.info('Stopwatch paused, disabling wakelock.');
        _timer?.cancel();
        WakelockPlus.disable();
        _shouldFadeUI = false;
        _fadeUITimer?.cancel();
        _fadeUITimer = null;
      }
    });
  }

  void _runStopwatch() {
    final subdivisions = _currentItem.subdivisions;

    if (subdivisions != null && subdivisions > 0) {
      _preciseSubdivisionInterval = subdivisions * 60.0;

      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        setState(() {
          _elapsedSeconds += 0.1;

          if (_preciseSubdivisionInterval > 0) {
            final currentSubdivision =
                (_elapsedSeconds / _preciseSubdivisionInterval).floor();

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
          _elapsedSeconds += 0.1;
        });
      });
    }
  }

  Future<void> _exitStopwatchDisplay() async {
    _log.info('exitStopwatchDisplay called');

    if (!_isPaused) {
      setState(() {
        _isPaused = true;
      });
    }

    _timer?.cancel();
    _dimTimer?.cancel();
    _log.info('Stopwatch stopped');
    WakelockPlus.disable();

    if (_dimScreenMode) {
      _restoreScreenBrightness();
    }

    if (_hasStarted && _elapsedSeconds > 0) {
      await _saveProgress();
    } else {
      await _saveCommentOnly();
    }

    await _saveMinimalistModePreference(_minimalistMode);

    widget.onExitCallback();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveProgress() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final totalMinutes = _elapsedSeconds / 60;
    final newTotalMinutes = _todaysAccumulatedMinutes + totalMinutes;

    _log.info(
        'Saving progress. Total time: ${newTotalMinutes.toStringAsFixed(2)} min');

    final newEntry = HistoryEntry(
      date: today,
      targetValue: 0,
      doneToday: true,
      actualValue: newTotalMinutes,
      comment: _commentController.text,
    );

    final updatedHistory = _currentItem.history
        .where((entry) => !DateUtils.isSameDay(entry.date, today))
        .toList()
      ..add(newEntry);

    final updatedItem = _createUpdatedItem(updatedHistory);
    await widget.dataManager.updateDailyThing(updatedItem);

    if (updatedItem.notificationEnabled) {
      await NotificationService().onItemCompleted(updatedItem);
    }

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

    if (todayEntry != null && todayEntry.comment == currentComment) {
      return;
    }

    if (todayEntry == null && currentComment.isEmpty) {
      return;
    }

    final updatedHistory = List<HistoryEntry>.from(_currentItem.history);

    if (todayEntry != null) {
      final updatedEntry = todayEntry.copyWith(comment: currentComment);
      updatedHistory[todayEntryIndex] = updatedEntry;
    } else {
      if (currentComment.isNotEmpty) {
        final newEntry = HistoryEntry(
          date: today,
          targetValue: 0,
          doneToday: false,
          actualValue: _todaysAccumulatedMinutes,
          comment: currentComment,
        );
        updatedHistory.add(newEntry);
      }
    }

    final updatedItem = _createUpdatedItem(updatedHistory);
    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info('Comment saved successfully.');
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
      bellSoundPath: _currentItem.bellSoundPath,
      subdivisions: _currentItem.subdivisions,
      subdivisionBellSoundPath: _currentItem.subdivisionBellSoundPath,
      notes: _currentItem.notes,
      isArchived: _currentItem.isArchived,
      notificationEnabled: _currentItem.notificationEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isNoteViewMode) {
      return NoteViewWidget(
        currentItem: _currentItem,
        isOvertime: false,
        isPaused: _isPaused,
        todaysTargetMinutes: 0,
        overtimeSeconds: 0,
        currentElapsedTimeInMinutes: _elapsedSeconds / 60,
        completedSubdivisions: _completedSubdivisions,
        subdivisions: _currentItem.subdivisions,
        getButtonText: _getButtonText,
        toggleTimer: _toggleStopwatch,
        toggleNoteViewMode: _toggleNoteViewMode,
        showNoteDialogInEditMode: _showNoteDialogInEditMode,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        _log.info('System back button pressed');

        if (!_isPaused) {
          _toggleStopwatch();
        }
        await _exitStopwatchDisplay();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ColorPalette.darkBackground,
            appBar: AppBar(
              backgroundColor: ColorPalette.darkBackground,
              toolbarHeight: 48,
              automaticallyImplyLeading: !(_minimalistMode && !_isPaused),
              leading: (_minimalistMode && !_isPaused)
                  ? AnimatedOpacity(
                      opacity: _shouldFadeUI ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          _log.info('Back button pressed');
                          if (!_isPaused) {
                            _toggleStopwatch();
                          }
                          await _exitStopwatchDisplay();
                        },
                      ),
                    )
                  : null,
              actions: [
                if (_currentItem.notes != null &&
                    _currentItem.notes!.isNotEmpty)
                  if (!(_minimalistMode && !_isPaused))
                    IconButton(
                      icon: const Icon(Icons.sticky_note_2),
                      onPressed: _toggleNoteViewMode,
                      tooltip: 'View Notes',
                    )
                  else
                    AnimatedOpacity(
                      opacity: _shouldFadeUI ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: IconButton(
                        icon: const Icon(Icons.sticky_note_2),
                        onPressed: _toggleNoteViewMode,
                        tooltip: 'View Notes',
                      ),
                    ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        _currentItem.name,
                        style: const TextStyle(
                          fontSize: 16,
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
                padding: const EdgeInsets.all(12.0),
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
                              isOvertime: false,
                              completedSubdivisions: _completedSubdivisions,
                              totalSubdivisions: _currentItem.subdivisions,
                              todaysTargetMinutes: 0,
                              overtimeSeconds: 0,
                              currentElapsedTimeInMinutes: _elapsedSeconds / 60,
                              formatMinutesToMmSs:
                                  TimerLogicHelper.formatMinutesToMmSs,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('minimalist_mode')),
                    ),
                    Expanded(
                      child: TimerDisplayWidget(
                        totalTime: 0,
                        elapsedTime: _elapsedSeconds / 60,
                        subdivisions: _currentItem.subdivisions ?? 0,
                        onTap: _toggleStopwatch,
                        isOvertime: true,
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: CommentInputWidget(
                        commentController: _commentController,
                        commentFocusNode: _commentFocusNode,
                        minimalistMode: _minimalistMode,
                        isOvertime: false,
                        isPaused: _isPaused,
                        remainingSeconds: 0,
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
                              toggleTimer: _toggleStopwatch,
                              exitTimerDisplay: _exitStopwatchDisplay,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('minimalist_mode_controls')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DimmingOverlayWidget(
            dimScreenMode: _dimScreenMode,
            dimOpacity: _dimOpacity,
            isPaused: _isPaused,
            startDimmingProcess: _startDimmingProcess,
            restoreScreenBrightness: _restoreScreenBrightness,
          ),
          NextTaskArrow(
            onTap: () async {
              await _exitStopwatchDisplay();
            },
            isVisible: _showNextTaskArrow,
            isOvertime: false,
            isMinimalistMode: _minimalistMode,
            isPaused: _isPaused,
            shouldFadeUI: _shouldFadeUI,
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    return _isPaused ? 'Start' : 'Stop';
  }

  void _editItem() async {
    _log.info('Editing item: ${_currentItem.name}');

    _timer?.cancel();

    if (_dimScreenMode) {
      _restoreScreenBrightness();
    }

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
      if (mounted) {
        setState(() {
          _currentItem = updatedItem;
        });
      }
    } else {
      _log.info('Edit cancelled.');
      if (!_isPaused && mounted) {
        WakelockPlus.enable();
        if (_dimScreenMode) {
          _startDimmingProcess();
        }
        _runStopwatch();
      }
    }
  }
}

class TimerLogicHelper {
  static String formatMinutesToMmSs(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
