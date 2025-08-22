import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/views/widgets/timer_painter.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerView extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final VoidCallback onExitCallback;
  final bool startInOvertime;

  const TimerView({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onExitCallback,
    this.startInOvertime = false,
  });

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late int _remainingSeconds;
  bool _isPaused = true;
  bool _hasStarted = false;
  Timer? _timer;
  bool _isOvertime = false;
  int _overtimeSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _log = Logger('TimerView');
  final _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late double _todaysTargetMinutes;
  late double _initialTargetSeconds;

  // Screen dimmer variables
  bool _dimScreenMode = false;
  bool _isDimming = false;
  Timer? _dimTimer;
  double _dimOpacity = 0.0;

  double get _currentElapsedTimeInMinutes {
    if (_isOvertime) {
      final overtimeMinutes = _overtimeSeconds / 60.0;
      return _todaysTargetMinutes + overtimeMinutes;
    }

    if (_hasStarted) {
      final elapsedSeconds = _initialTargetSeconds - _remainingSeconds;
      final sessionElapsedMinutes = elapsedSeconds / 60.0;
      return sessionElapsedMinutes;
    }

    // For non-started case, we need to check persisted value
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    HistoryEntry? todaysEntry;
    for (final entry in widget.item.history) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == todayDate) {
        todaysEntry = entry;
        break;
      }
    }

    return todaysEntry?.actualValue ?? 0.0;
  }

  String _formatMinutesToMmSs(double minutesValue) {
    final totalSeconds = (minutesValue * 60).round();
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

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
    _isDimming = false;
    _dimTimer?.cancel();
    setState(() {
      _dimOpacity = 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize target values first
    _todaysTargetMinutes = widget.item.todayValue;
    _initialTargetSeconds = _todaysTargetMinutes * 60;

    // Enable fullscreen mode when entering the timer view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.startInOvertime) {
      _isOvertime = true;
      _isPaused = true;
      _hasStarted = true;
    }

    // Load dim screen mode preference
    _loadDimScreenPreference();
    _log.info('--- TIMER INITIALIZATION START ---');
    _log.info('Item Name: ${widget.item.name}');
    _log.info('Item Type: ${widget.item.itemType}');
    _log.info('Start Value: ${widget.item.startValue}');
    _log.info('End Value: ${widget.item.endValue}');
    _log.info('Calculated Increment: ${widget.item.increment}');
    _log.info('Calculated Daily Target (todayValue): $_todaysTargetMinutes');

    final todayDate = DateUtils.dateOnly(DateTime.now());
    _log.info('Searching for history entry for date: $todayDate');

    HistoryEntry? todayEntry;
    for (final entry in widget.item.history) {
      final entryDate = DateUtils.dateOnly(entry.date);
      if (entryDate == todayDate) {
        // Find any entry for today, regardless of completion state.
        // This is crucial for correctly resuming overtime.
        todayEntry = entry;
        _log.info(
            'Found entry for today (done: ${entry.doneToday}, actual: ${entry.actualValue}).');
        break;
      }
    }

    if (todayEntry != null) {
      // Load existing comment
      if (todayEntry.comment != null && todayEntry.comment!.isNotEmpty) {
        _commentController.text = todayEntry.comment!;
      }

      final dailyTarget = _todaysTargetMinutes;
      final completedMinutes = todayEntry.actualValue ?? 0.0;
      // Use epsilon comparison to handle floating-point precision issues
      final epsilon = 0.0001; // Small tolerance for floating-point comparison
      if (widget.startInOvertime ||
          (completedMinutes - dailyTarget).abs() < epsilon ||
          completedMinutes > dailyTarget) {
        _isOvertime = true;
        _isPaused = true;
        _hasStarted = true;
        final overtimeMinutes = completedMinutes - dailyTarget;
        _overtimeSeconds =
            (overtimeMinutes > 0) ? (overtimeMinutes * 60).round() : 0;
        _remainingSeconds = 0;
      } else {
        final remainingMinutes = dailyTarget - completedMinutes;
        _remainingSeconds = (remainingMinutes * 60).round();
      }
    } else {
      _remainingSeconds = _initialTargetSeconds.round();
    }
    _log.info('--- TIMER INITIALIZATION END ---');
    _commentFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _log.info('dispose called');
    // Disable fullscreen mode when exiting the timer view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    _dimTimer?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
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

        final bool isFinished = _remainingSeconds <= 0 && !_isOvertime;
        _log.info(
            'isFinished: $isFinished, _remainingSeconds: $_remainingSeconds, _isOvertime: $_isOvertime');
        if (isFinished) {
          _log.info('Timer is finished, starting overtime mode');
          // Timer is finished, start overtime mode
          _isOvertime = true;
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

    final subdivisions = widget.item.subdivisions;
    if (subdivisions != null && subdivisions > 1) {
      final totalSeconds = (_todaysTargetMinutes * 60).round();
      final subdivisionInterval = (totalSeconds / subdivisions).round();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds--;

          // Check for immediate completion when reaching 0
          if (_remainingSeconds <= 0) {
            _log.info('Timer completed at zero.');
            timer.cancel();
            _onTimerComplete();
            return;
          }

          if (subdivisionInterval > 0 &&
              _remainingSeconds > 0 &&
              _remainingSeconds % subdivisionInterval == 0) {
            _playSubdivisionBell();
          }
        });
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds--;

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
    _playTimerCompleteNotification();

    // Update UI state immediately to show completion
    setState(() {
      _isPaused = true;
      _log.info('Timer paused in onTimerComplete');
    });

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
    final elapsed = _currentElapsedTimeInMinutes;
    final target = _todaysTargetMinutes;
    final isDone = (elapsed - target).abs() < epsilon || elapsed > target;

    _log.info(
        'Saving progress. Done: $isDone, Time: ${_currentElapsedTimeInMinutes.toStringAsFixed(2)} min');

    final newEntry = HistoryEntry(
      date: today,
      targetValue: _todaysTargetMinutes,
      doneToday: isDone,
      actualValue: _currentElapsedTimeInMinutes,
      comment: _commentController.text,
    );

    // Remove any existing entry for today to prevent duplicates.
    // This ensures we are always updating or creating the day's progress.
    final updatedHistory = widget.item.history
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

    for (int i = 0; i < widget.item.history.length; i++) {
      if (DateUtils.isSameDay(widget.item.history[i].date, today)) {
        todayEntry = widget.item.history[i];
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

    final updatedHistory = List<HistoryEntry>.from(widget.item.history);

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
      bellSoundPath: widget.item.bellSoundPath, // Pass the bell sound path
      subdivisions: widget.item.subdivisions,
      subdivisionBellSoundPath: widget.item.subdivisionBellSoundPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        _log.info('System back button pressed');
        await _exitTimerDisplay();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopInfoRow(context),
                    const SizedBox(height: 4),
                    Text(
                      _isOvertime
                          ? '${_formatMinutesToMmSs(_todaysTargetMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)} + ${_formatMinutesToMmSs(_overtimeSeconds / 60.0)}'
                          : '${_formatMinutesToMmSs(_currentElapsedTimeInMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)}',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            ColorPalette.lightText.withAlpha((255 * 0.7).round()),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Expanded(
                      child: _isOvertime
                          ? _buildOvertimeView()
                          : _buildCountdownView(),
                    ),
                    const SizedBox(height: 8),
                    _buildCommentField(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleTimer,
                            child: Text(
                              _getButtonText(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _exitTimerDisplay,
                            child: const Text('Exit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Dimming overlay
              if (_dimScreenMode && _dimOpacity > 0.0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // Cancel any existing dimming timer
                      _dimTimer?.cancel();
                      // Temporarily restore visibility when tapped
                      setState(() {
                        _dimOpacity = 0.0;
                        _isDimming = false;
                      });
                      // Restart dimming after a delay if still in dim mode and timer is running
                      Future.delayed(const Duration(seconds: 3), () {
                        if (!_isPaused && _dimScreenMode && mounted) {
                          _startDimmingProcess();
                        }
                      });
                    },
                    child: Container(
                      color: Color.fromARGB((_dimOpacity * 255).round(), 0, 0, 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _buildCountdownView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: TimerPainter(
            totalTime: _todaysTargetMinutes,
            elapsedTime: _currentElapsedTimeInMinutes,
            subdivisions: widget.item.subdivisions ?? 0,
          ),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              child: GestureDetector(
                onTap: _toggleTimer,
                child: Text(
                  _formatMinutesToMmSs(
                      (_todaysTargetMinutes - _currentElapsedTimeInMinutes)
                          .clamp(0.0, double.infinity)),
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.lightText,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOvertimeView() {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        painter: TimerPainter(
          totalTime: _todaysTargetMinutes,
          elapsedTime: _currentElapsedTimeInMinutes,
          subdivisions: widget.item.subdivisions ?? 0,
        ),
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            child: GestureDetector(
              onTap: _toggleTimer,
              child: Text(
                _formatMinutesToMmSs(_currentElapsedTimeInMinutes),
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.lightText,
                ),
                textAlign: TextAlign.center,
                softWrap: false,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCommentField() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_commentFocusNode);
      },
      child: TextField(
        controller: _commentController,
        focusNode: _commentFocusNode,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'add a comment',
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border:
              _commentFocusNode.hasFocus || _commentController.text.isNotEmpty
                  ? const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    )
                  : InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _playTimerCompleteNotification() async {
    _log.info('Playing timer complete notification');

    try {
      final bellPath = (widget.item.bellSoundPath ?? 'assets/bells/bell1.mp3')
          .replaceFirst('assets/', '');
      // Don't await the play operation - let it run in background
      _audioPlayer.play(AssetSource(bellPath));
    } catch (e) {
      _log.warning('Failed to play bell sound: $e');
    }
  }

  Future<void> _playSubdivisionBell() async {
    _log.info('Playing subdivision bell');

    try {
      final bellPath =
          (widget.item.subdivisionBellSoundPath ?? 'assets/bells/bell1.mp3')
              .replaceFirst('assets/', '');
      // Don't await the play operation - let it run in background
      _audioPlayer.play(AssetSource(bellPath));
    } catch (e) {
      _log.warning('Failed to play subdivision bell sound: $e');
    }
  }

  Widget _buildTopInfoRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Empty container to balance the menu on the right
        const SizedBox(width: 40),
        Expanded(
          child: Text(
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
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: ColorPalette.lightText,
          ),
          onSelected: (String result) {
            if (result == 'toggle') {
              _toggleDimScreenMode();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(_dimScreenMode ? Icons.brightness_high : Icons.brightness_low),
                  const SizedBox(width: 8),
                  Text(_dimScreenMode ? 'Keep Screen On' : 'Dim Screen'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}