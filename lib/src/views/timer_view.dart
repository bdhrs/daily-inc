import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _log = Logger('TimerView');

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
          'Checking history: date=${entryDate}, actual=${entry.actualValue}, done=${entry.doneToday}, target=${entry.targetValue}');
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
        _runCountdown();
      } else {
        _log.info('Timer paused, disabling wakelock.');
        WakelockPlus.disable();
      }
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
    // Play the bell sound
    await _audioPlayer.play(AssetSource('bell.mp3'));
    WakelockPlus.disable();
    _log.info('Wakelock disabled.');

    // Update the history
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // For timer-based items, we consider the target value as completed
    // since they completed the full timer duration
    final newEntry = HistoryEntry(
      date: todayDate,
      targetValue: widget.item.todayValue, // Save target value
      doneToday: true, // Timer completion implies meeting the target
      // No actual value needed for timer-based items
      // since completion implies meeting the target
    );
    _log.info('Created new history entry for today.');

    final updatedHistory = widget.item.history
        .where((entry) => entry.date != todayDate)
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
    );
    _log.info('Created updated DailyThing.');

    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info('Updated daily thing in data manager.');
    if (!mounted) {
      _log.warning('Widget not mounted, returning.');
      return; // Ensure the widget is still mounted before using context
    }
    widget.onExitCallback();
    Navigator.of(context).pop();
    _log.info('Exited timer view.');
  }

  Future<void> _exitTimerDisplay() async {
    _log.info('exitTimerDisplay called');
    _log.info(
        'Conditions: _hasStarted=$_hasStarted, _remainingSeconds=$_remainingSeconds, _originalTotalSeconds=$_originalTotalSeconds');

    // Stop the timer immediately when exiting
    _timer?.cancel();
    _log.info('Timer stopped');
    WakelockPlus.disable();

    // Check if timer has started but not completed
    if (_hasStarted &&
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

  String _formatTime(int seconds) {
    // No logging here as it's a pure formatting function called frequently.
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Progress?'),
          content: const Text(
            'You have incomplete progress. Would you like to save your current time?',
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
    );

    await widget.dataManager.updateDailyThing(updatedItem);
    _log.info(
        'Saved partial progress: $sessionMinutes minutes (total: $accumulatedMinutes)');
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate font size based on the widest possible time "88:88"
                      // This ensures consistent sizing regardless of actual digits
                      const maxTimeText = "88:88";
                      final textPainter = TextPainter(
                        text: const TextSpan(
                          text: maxTimeText,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        textDirection: TextDirection.ltr,
                      );
                      textPainter.layout();

                      // Calculate font size to fit 90% of available width for the widest case
                      final fontSize = (constraints.maxWidth * 0.9) /
                          textPainter.width *
                          12; // 12 is base font size

                      return SizedBox(
                        width: constraints.maxWidth,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: ColorPalette
                                  .lightText, // Apply white to timer text
                            ),
                            textAlign: TextAlign.center,
                            softWrap: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _toggleTimer,
                  child: Text(_isPaused ? 'Start' : 'Pause'),
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
}
