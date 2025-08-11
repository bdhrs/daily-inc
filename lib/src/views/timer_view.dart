import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimerView extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onExitCallback;

  const TimerView({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onExitCallback,
  });

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late int _remainingSeconds;
  late int _originalTotalSeconds;
  bool _isPaused = true;
  bool _hasStarted = false;
  Timer? _timer;
  bool _isOvertime = false;
  int _overtimeSeconds = 0;
  double _totalTimeCompleted = 0.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _log = Logger('TimerView');
  final _commentController = TextEditingController();

  double get _todaysTargetMinutes => widget.item.todayValue;

  double get _elapsedMinutes {
    // Prefer persisted actualValue (partial progress) for today if present,
    // so top-row reflects previously done time even before starting this session.
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    HistoryEntry? todaysEntry;
    for (final entry in widget.item.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate && !entry.doneToday) {
        todaysEntry = entry;
        break;
      }
    }

    final persisted = todaysEntry?.actualValue ?? 0.0;

    // Also include this session's elapsed time once the timer starts.
    final sessionElapsedSeconds = _originalTotalSeconds - _remainingSeconds;
    final sessionElapsedMinutes = sessionElapsedSeconds / 60.0;

    // If timer hasn't started, show only persisted value; otherwise add both.
    return _hasStarted ? (persisted + sessionElapsedMinutes) : persisted;
  }

  String _formatMinutesToMmSs(double minutesValue) {
    final totalSeconds = (minutesValue * 60).round();
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
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
      return '${value.round()}x';
    } else {
      return value >= 1 ? '✅' : '❌';
    }
  }

  @override
  void initState() {
    super.initState();
    _log.info('--- TIMER INITIALIZATION START ---');
    _log.info('Item Name: ${widget.item.name}');
    _log.info('Item Type: ${widget.item.itemType}');
    _log.info('Start Value: ${widget.item.startValue}');
    _log.info('End Value: ${widget.item.endValue}');
    _log.info('Calculated Increment: ${widget.item.increment}');
    _log.info(
        'Calculated Daily Target (todayValue): ${widget.item.todayValue}');

    final todayDate = DateUtils.dateOnly(DateTime.now());
    _log.info('Searching for history entry for date: $todayDate');

    HistoryEntry? todayEntry;
    for (final entry in widget.item.history) {
      final entryDate = DateUtils.dateOnly(entry.date);
      _log.info(
          'Checking history: date=$entryDate, actual=${entry.actualValue}, done=${entry.doneToday}, target=${entry.targetValue}');
      if (entryDate == todayDate &&
          entry.actualValue != null &&
          !entry.doneToday) {
        todayEntry = entry;
        _log.info('Found matching entry for today.');
        break;
      }
    }

    if (todayEntry != null) {
      _log.info('Partial progress found for today.');
      final dailyTarget = widget.item.todayValue;
      final completedMinutes = todayEntry.actualValue!;
      final remainingMinutes = dailyTarget - completedMinutes;

      _log.info('--- Calculation Details ---');
      _log.info('Daily Target (from item.todayValue): $dailyTarget min');
      _log.info('Completed (from entry.actualValue): $completedMinutes min');
      _log.info('Calculated Remaining: $remainingMinutes min');

      final safeRemainingMinutes = remainingMinutes.clamp(0.0, double.infinity);
      _remainingSeconds = (safeRemainingMinutes * 60).round();

      _log.info('Clamped Remaining: $safeRemainingMinutes min');
      _log.info('Final Remaining Seconds: $_remainingSeconds');
    } else {
      _log.info('No partial progress found. Using full daily target.');
      final dailyTarget = widget.item.todayValue;
      _remainingSeconds = (dailyTarget * 60).round();
      _log.info('Daily Target: $dailyTarget min');
      _log.info('Final Remaining Seconds: $_remainingSeconds');
    }
    _originalTotalSeconds = _remainingSeconds;
    _log.info('--- TIMER INITIALIZATION END ---');
  }

  @override
  void dispose() {
    _log.info('dispose called');
    _timer?.cancel();
    _commentController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleTimer() {
    _log.info('toggleTimer called, isPaused is now ${!_isPaused}');
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _log.info('Timer started, enabling wakelock.');
        _hasStarted = true; // Mark that timer has been started
        WakelockPlus.enable();
        if (_isOvertime) {
          _runOvertime();
        } else {
          _runCountdown();
        }
      } else {
        _log.info('Timer paused, disabling wakelock.');
        _timer?.cancel();
        WakelockPlus.disable();
      }
    });
  }

  void _runOvertime() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) {
        timer.cancel();
        return;
      }
      setState(() {
        _overtimeSeconds++;
        _totalTimeCompleted = (_originalTotalSeconds + _overtimeSeconds) / 60.0;
      });
    });
  }

  void _runCountdown() {
    _log.info('runCountdown called with $_remainingSeconds seconds remaining');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _remainingSeconds <= 0) {
        timer.cancel();
        if (_remainingSeconds <= 0) {
          _log.info('Timer completed at zero.');
          _onTimerComplete();
        }
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _onTimerComplete() async {
    _log.info('onTimerComplete called');

    // Play notification with sound and vibration (works even with screen off)
    await _playTimerCompleteNotification();

    WakelockPlus.disable();
    _log.info('Wakelock disabled.');

    setState(() {
      _isOvertime = true;
      _totalTimeCompleted = _originalTotalSeconds / 60.0;
      _isPaused = true;
    });
  }

  Future<void> _exitTimerDisplay() async {
    _log.info('exitTimerDisplay called');
    _log.info(
        'Conditions: _hasStarted=$_hasStarted, _remainingSeconds=$_remainingSeconds, _originalTotalSeconds=$_originalTotalSeconds, _isOvertime=$_isOvertime');

    // Stop the timer immediately when exiting
    _timer?.cancel();
    _log.info('Timer stopped');
    WakelockPlus.disable();

    if (_isOvertime) {
      final shouldSave = await _showSaveDialog(isOvertime: true);
      if (shouldSave == true) {
        await _saveTotalProgress();
      } else if (shouldSave == null) {
        return; // User cancelled
      }
    } else if (_hasStarted &&
        _remainingSeconds > 0 &&
        _remainingSeconds < _originalTotalSeconds) {
      _log.info('Showing save dialog for partial progress');
      final shouldSave = await _showSaveDialog();
      _log.info('Save dialog result: $shouldSave');

      if (shouldSave == null) {
        _log.info('User cancelled dialog, not exiting');
        return; // User cancelled dialog
      }

      if (shouldSave) {
        await _savePartialProgress();
      }
    } else {
      _log.info('Save dialog conditions not met, exiting without prompt');
    }

    widget.onExitCallback();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Unused formatting functions removed:
  // - _formatTime: redundant with _formatMinutesToMmSs
  // - _formatElapsedTotalTime: not used in UI

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

  Future<void> _savePartialProgress() async {
    _log.info('Saving partial progress');

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Calculate actual minutes completed in this session
    final secondsCompleted = _originalTotalSeconds - _remainingSeconds;
    final sessionMinutes = secondsCompleted / 60.0;
    _log.info(
        'Session completed: ${secondsCompleted}s = ${sessionMinutes.toStringAsFixed(2)}min');

    // Find existing partial progress for today
    HistoryEntry? existingEntry;
    for (final entry in widget.item.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate && !entry.doneToday) {
        existingEntry = entry;
        break;
      }
    }

    // Calculate accumulated minutes
    final accumulatedMinutes =
        (existingEntry?.actualValue ?? 0.0) + sessionMinutes;

    final newEntry = HistoryEntry(
      date: todayDate,
      targetValue: widget.item.todayValue,
      doneToday: false, // Mark as incomplete
      actualValue: accumulatedMinutes,
      comment: _commentController.text,
    );

    final updatedHistory = widget.item.history
        .where((entry) => entry.date != todayDate || entry.doneToday)
        .toList()
      ..add(newEntry);

    final updatedItem = DailyThing(
      id: widget.item.id,
      icon: widget.item.icon,
      name: widget.item.name,
      itemType: widget.item.itemType,
      startDate: widget.item.startDate,
      startValue: widget.item.startValue,
      duration: widget.item.duration,
      endValue: widget.item.endValue,
      history: updatedHistory,
      nagTime: widget.item.nagTime,
      nagMessage: widget.item.nagMessage,
      category: widget.item.category,
      isPaused: widget.item.isPaused,
      intervalType: widget.item.intervalType,
      intervalValue: widget.item.intervalValue,
      intervalWeekdays: widget.item.intervalWeekdays,
    );

    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info(
        'Saved partial progress: $sessionMinutes minutes (total: $accumulatedMinutes)');
  }

  Future<void> _saveTotalProgress() async {
    _log.info('Saving total progress');
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final newEntry = HistoryEntry(
      date: todayDate,
      targetValue: widget.item.todayValue,
      doneToday: true,
      actualValue: _totalTimeCompleted,
      comment: _commentController.text,
    );

    final updatedHistory = widget.item.history
        .where((entry) => entry.date != todayDate)
        .toList()
      ..add(newEntry);

    final updatedItem = _createUpdatedItem(updatedHistory);
    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info('Saved total progress: $_totalTimeCompleted minutes');
  }

  DailyThing _createUpdatedItem(List<HistoryEntry> updatedHistory) {
    return DailyThing(
      id: widget.item.id,
      icon: widget.item.icon,
      name: widget.item.name,
      itemType: widget.item.itemType,
      startDate: widget.item.startDate,
      startValue: widget.item.startValue,
      duration: widget.item.duration,
      endValue: widget.item.endValue,
      history: updatedHistory,
      nagTime: widget.item.nagTime,
      nagMessage: widget.item.nagMessage,
      category: widget.item.category,
      isPaused: widget.item.isPaused,
      intervalType: widget.item.intervalType,
      intervalValue: widget.item.intervalValue,
      intervalWeekdays: widget.item.intervalWeekdays,
    );
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');

    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // Already handled
        _log.info('System back button pressed');
        await _exitTimerDisplay();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top line 1: item name (small bold)
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // New Row for Start/End/Increment
                _buildGoalRow(context),

                const SizedBox(height: 12),

                // Center content expands
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Group 2: The two timers
                      _isOvertime
                          ? Column(
                              children: [
                                Text(
                                  'Total Time:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ColorPalette.lightText
                                        .withAlpha((255 * 0.7).round()),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMinutesToMmSs(_totalTimeCompleted),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 60,
                                    color: ColorPalette.lightText,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  '${_formatMinutesToMmSs(_elapsedMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ColorPalette.lightText
                                        .withAlpha((255 * 0.7).round()),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const maxTimeText = "88:88";
                                    final textPainter = TextPainter(
                                      text: const TextSpan(
                                        text: maxTimeText,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      textDirection: TextDirection.ltr,
                                    );
                                    textPainter.layout();

                                    final fontSize =
                                        (constraints.maxWidth * 0.9) /
                                            textPainter.width *
                                            12;

                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _formatMinutesToMmSs(
                                              (_todaysTargetMinutes -
                                                      _elapsedMinutes)
                                                  .clamp(0.0, double.infinity)),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize,
                                            color: ColorPalette.lightText,
                                          ),
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    hintText: 'Add an optional comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _toggleTimer,
                  child: Text(
                    _isOvertime
                        ? (_isPaused ? 'Continue' : 'Pause')
                        : (_isPaused ? 'Start' : 'Pause'),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _exitTimerDisplay,
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playTimerCompleteNotification() async {
    _log.info('Playing timer complete notification');

    try {
      // Try to play the bell sound first (for when app is in foreground)
      await _audioPlayer.play(AssetSource('bell.mp3'));
    } catch (e) {
      _log.warning('Failed to play bell sound: $e');
    }
  }

  Widget _buildGoalRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // start → end
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatValue(widget.item.startValue, widget.item.itemType),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.trending_flat, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatValue(widget.item.endValue, widget.item.itemType),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
        // increment
        const SizedBox(width: 8),
        Text(
          (() {
            final inc = widget.item.increment;
            final sign = inc < 0 ? '-' : '+';
            final absVal = inc.abs();
            String numStr = absVal.toStringAsFixed(2);
            numStr = numStr.replaceFirst(RegExp(r'\.00$'), '');
            numStr = numStr.replaceFirst(RegExp(r'0$'), '');
            return '$sign$numStr';
          })(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}
