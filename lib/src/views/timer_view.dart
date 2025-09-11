import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/add_edit_daily_item_view.dart';
import 'package:daily_inc/src/views/widgets/next_task_arrow.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/views/widgets/timer_painter.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_inc/src/core/time_converter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _subdivisionAudioPlayer = AudioPlayer();
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
  late double _initialTargetSeconds;

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
    for (final entry in _currentItem.history) {
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
    return TimeConverter.toMmSsString(minutesValue, padZeroes: true);
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

  /// Builds the Note View UI when in note view mode
  Widget _buildNoteView(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        // When back button is pressed in note view mode, just toggle back to normal mode
        _toggleNoteViewMode();
      },
      child: Scaffold(
        backgroundColor: ColorPalette.darkBackground,
        appBar: AppBar(
          backgroundColor: ColorPalette.darkBackground,
          title: Text(
            _currentItem.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          elevation: 0,
          // Add a close button to the app bar
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleNoteViewMode,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Information Bar
                _buildNoteViewTopBar(),
                const SizedBox(height: 16),
                // Main Notes Display
                Expanded(
                  child: _buildNoteViewNotesDisplay(),
                ),
                const SizedBox(height: 16),
                // Bottom Action Buttons
                _buildNoteViewBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Top Information Bar for Note View mode
  Widget _buildNoteViewTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left Side: Timer Control Button (fixed width to prevent layout shifts)
          SizedBox(
            width: 120, // Fixed width to prevent layout shifts
            child: ElevatedButton(
              onPressed: _toggleTimer,
              child: Text(
                _getButtonText(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Center: Time Display
          Expanded(
            child: Text(
              _isOvertime
                  ? '${_formatMinutesToMmSs(_todaysTargetMinutes)} + ${_formatMinutesToMmSs(_overtimeSeconds / 60.0)}'
                  : '${_formatMinutesToMmSs(_currentElapsedTimeInMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: ColorPalette.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Subdivision Display (only if subdivisions are enabled)
          if (_currentItem.subdivisions != null &&
              _currentItem.subdivisions! > 1)
            SizedBox(
              width: 80, // Fixed width for consistent layout
              child: Text(
                '$_completedSubdivisions / ${_currentItem.subdivisions}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  color: ColorPalette.lightText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the Main Notes Display for Note View mode
  Widget _buildNoteViewNotesDisplay() {
    final notes = _currentItem.notes ?? '';

    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes for this item.',
          style: TextStyle(
            fontSize: 20,
            color: ColorPalette.lightText.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: notes,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 25,
              color: ColorPalette.lightText,
              height: 1.5,
            ),
            h1: TextStyle(
              fontSize: 40,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            h2: TextStyle(
              fontSize: 35,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            h3: TextStyle(
              fontSize: 30,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            strong: const TextStyle(fontWeight: FontWeight.bold),
            em: const TextStyle(fontStyle: FontStyle.italic),
            // Add more styles as needed for lists, etc.
          ),
        ),
      ),
    );
  }

  /// Builds the Bottom Action Buttons for Note View mode
  Widget _buildNoteViewBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed:
                _showNoteDialogInEditMode, // Use the new edit mode dialog
            child: const Text('Edit Note'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _toggleNoteViewMode, // Close note view mode
            child: const Text('Close'),
          ),
        ),
      ],
    );
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
    // Initialize target values first
    _todaysTargetMinutes = widget.item.todayValue;
    _initialTargetSeconds = _todaysTargetMinutes * 60;

    // Initialize the current item reference
    _currentItem = widget.item;

    // Set initial minimalist mode from parameter
    _minimalistMode = widget.initialMinimalistMode;

    if (widget.startInOvertime) {
      _isOvertime = true;
      _isPaused = true;
      _hasStarted = true;
    }

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
    for (final entry in _currentItem.history) {
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
        _overtimeSeconds = (overtimeMinutes > 0) ? (overtimeMinutes * 60) : 0.0;
        _remainingSeconds = 0.0;

        // Calculate completed subdivisions for overtime mode using precise floating-point
        if (_currentItem.subdivisions != null &&
            _currentItem.subdivisions! > 1) {
          final totalSeconds = (_todaysTargetMinutes * 60);
          final subdivisionInterval = totalSeconds / _currentItem.subdivisions!;
          if (subdivisionInterval > 0) {
            final elapsedSeconds = totalSeconds + _overtimeSeconds;
            // Use precise calculation to match the new timer logic
            _completedSubdivisions = (elapsedSeconds / subdivisionInterval)
                .floor()
                .clamp(0, _currentItem.subdivisions! * 2); // Allow for overtime
          }
        }
      } else {
        final remainingMinutes = dailyTarget - completedMinutes;
        _remainingSeconds = (remainingMinutes * 60);
      }

      // Calculate already completed subdivisions using precise floating-point
      if (_currentItem.subdivisions != null && _currentItem.subdivisions! > 1) {
        final totalSeconds = (_todaysTargetMinutes * 60);
        final subdivisionInterval = totalSeconds / _currentItem.subdivisions!;
        if (subdivisionInterval > 0) {
          final elapsedSeconds = totalSeconds - _remainingSeconds;
          // Use precise calculation to match the new timer logic
          _completedSubdivisions = (elapsedSeconds / subdivisionInterval)
              .floor()
              .clamp(0, _currentItem.subdivisions! - 1);
        }
      }
    } else {
      _remainingSeconds = _initialTargetSeconds;
    }
    _log.info('--- TIMER INITIALIZATION END ---');
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
    _subdivisionAudioPlayer.dispose();
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
            _playSubdivisionBell();
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
              _playSubdivisionBell();
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
    _playTimerCompleteNotification();

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

  /// Finds the next undone task in the list after the current item
  DailyThing? _findNextUndoneTask() {
    // If we don't have the full list or current index, we can't navigate
    if (widget.allItems == null || widget.currentItemIndex == null) {
      return null;
    }

    // Start from the next item
    for (int i = widget.currentItemIndex! + 1;
        i < widget.allItems!.length;
        i++) {
      final item = widget.allItems![i];

      // Check if the item is undone based on its type
      switch (item.itemType) {
        case ItemType.check:
          if (!item.completedForToday) {
            return item;
          }
          break;
        case ItemType.reps:
          // For reps, check if no actual value has been entered today
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final hasActualValueToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate && entry.actualValue != null;
          });
          if (!hasActualValueToday) {
            return item;
          }
          break;
        case ItemType.minutes:
          // For minutes, check if not completed
          if (!item.completedForToday) {
            return item;
          }
          break;
        case ItemType.percentage:
          // For percentage, check if no entry for today or entry has 0 value
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final todayEntry = item.history.cast<HistoryEntry?>().firstWhere(
                (entry) =>
                    entry != null &&
                    DateTime(entry.date.year, entry.date.month,
                            entry.date.day) ==
                        todayDate,
                orElse: () => null,
              );
          if (todayEntry == null || (todayEntry.actualValue ?? 0) == 0) {
            return item;
          }
          break;
        case ItemType.trend:
          // For trend, check if no entry for today
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final hasEntryToday = item.history.any((entry) {
            final entryDate =
                DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate == todayDate;
          });
          if (!hasEntryToday) {
            return item;
          }
          break;
      }
    }

    // No more undone tasks
    return null;
  }

  /// Navigates to the next task or exits to main UI
  void _navigateToNextTask() async {
    final nextTask = _findNextUndoneTask();

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
    double elapsedMinutesInCurrentSubdivision = 0;
    double totalMinutesInCurrentSubdivision = 0;
    double overtimeMinutesInCurrentSubdivision = 0;
    if (!_isOvertime &&
        _currentItem.subdivisions != null &&
        _currentItem.subdivisions! > 1) {
      final double subdivisionDurationInMinutes =
          _todaysTargetMinutes / _currentItem.subdivisions!;
      final double elapsedMinutesInCompletedSubdivisions =
          _completedSubdivisions * subdivisionDurationInMinutes;
      elapsedMinutesInCurrentSubdivision =
          _currentElapsedTimeInMinutes - elapsedMinutesInCompletedSubdivisions;
      totalMinutesInCurrentSubdivision = subdivisionDurationInMinutes;
    } else if (_isOvertime &&
        _currentItem.subdivisions != null &&
        _currentItem.subdivisions! > 1) {
      final double subdivisionDurationInMinutes =
          _todaysTargetMinutes / _currentItem.subdivisions!;
      final double overtimeMinutes = _overtimeSeconds / 60.0;
      overtimeMinutesInCurrentSubdivision =
          overtimeMinutes % subdivisionDurationInMinutes;
    }

    // If in note view mode, render the note view UI instead
    if (_isNoteViewMode) {
      return _buildNoteView(context);
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
                          ? _isOvertime
                              ? Column(
                                  key: const ValueKey('full_mode_overtime'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentItem.subdivisions != null &&
                                        _currentItem.subdivisions! > 1)
                                      Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${_formatMinutesToMmSs(_todaysTargetMinutes)} + ${_formatMinutesToMmSs(_overtimeSeconds / 60.0)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: ColorPalette.lightText
                                                    .withAlpha(
                                                        (255 * 0.7).round()),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$_completedSubdivisions / ${_currentItem.subdivisions!}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: ColorPalette.lightText
                                                    .withAlpha(
                                                        (255 * 0.7).round()),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '${_formatMinutesToMmSs(overtimeMinutesInCurrentSubdivision)} / ${_formatMinutesToMmSs(_todaysTargetMinutes / _currentItem.subdivisions!)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: ColorPalette.lightText
                                                    .withAlpha(
                                                        (255 * 0.7).round()),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        '${_formatMinutesToMmSs(_todaysTargetMinutes)} + ${_formatMinutesToMmSs(_overtimeSeconds / 60.0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ColorPalette.lightText
                                              .withAlpha((255 * 0.7).round()),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                )
                              : (_currentItem.subdivisions != null &&
                                      _currentItem.subdivisions! > 1)
                                  ? Stack(
                                      key: const ValueKey(
                                          'full_mode_subdivisions'),
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${_formatMinutesToMmSs(_currentElapsedTimeInMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ColorPalette.lightText
                                                  .withAlpha(
                                                      (255 * 0.7).round()),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$_completedSubdivisions / ${_currentItem.subdivisions!}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ColorPalette.lightText
                                                  .withAlpha(
                                                      (255 * 0.7).round()),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${_formatMinutesToMmSs(elapsedMinutesInCurrentSubdivision)} / ${_formatMinutesToMmSs(totalMinutesInCurrentSubdivision)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ColorPalette.lightText
                                                  .withAlpha(
                                                      (255 * 0.7).round()),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '${_formatMinutesToMmSs(_currentElapsedTimeInMinutes)} / ${_formatMinutesToMmSs(_todaysTargetMinutes)}',
                                      key: const ValueKey('full_mode_normal'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: ColorPalette.lightText
                                            .withAlpha((255 * 0.7).round()),
                                      ),
                                    )
                          : const SizedBox.shrink(
                              key: ValueKey('minimalist_mode')),
                    ),
                    Expanded(
                      child: _isOvertime
                          ? _buildOvertimeView()
                          : _buildCountdownView(),
                    ),
                    // Comment field - always present in layout but visibility controlled by logic
                    SizedBox(
                      height: 50, // Fixed height to prevent layout shifts
                      child: _buildCommentField(),
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
                          ? Column(
                              key: const ValueKey('full_mode_controls'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
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

  Widget _buildCountdownView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: TimerPainter(
            totalTime: _todaysTargetMinutes,
            elapsedTime: _currentElapsedTimeInMinutes,
            subdivisions: _currentItem.subdivisions ?? 0,
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
          subdivisions: _currentItem.subdivisions ?? 0,
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
    // In minimalist mode:
    // - When timer is running in overtime, hide the comment field
    // - When timer is paused in overtime, show the comment field
    // - When timer is finished (at 0 seconds) but not in overtime, show the comment field
    final bool showCommentField = !_minimalistMode ||
        (_isOvertime ? _isPaused : (_remainingSeconds <= 0 && !_isOvertime));

    // In minimalist mode when timer is running, fade out the comment field like other UI elements
    final bool shouldFadeOut =
        _minimalistMode && !_isPaused && showCommentField;

    return Opacity(
      opacity: showCommentField ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !showCommentField,
        child: AnimatedOpacity(
          opacity: shouldFadeOut ? (_shouldFadeUI ? 0.0 : 1.0) : 1.0,
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
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
                border: _commentFocusNode.hasFocus ||
                        _commentController.text.isNotEmpty
                    ? const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      )
                    : InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playTimerCompleteNotification() async {
    _log.info('Playing timer complete notification');

    try {
      final bellPath = (_currentItem.bellSoundPath ?? 'assets/bells/bell1.mp3')
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
          (_currentItem.subdivisionBellSoundPath ?? 'assets/bells/bell1.mp3')
              .replaceFirst('assets/', '');
      // Stop any currently playing subdivision bell to ensure the new one plays
      await _subdivisionAudioPlayer.stop();
      // Don't await the play operation - let it run in background
      _subdivisionAudioPlayer.play(AssetSource(bellPath));
    } catch (e) {
      _log.warning('Failed to play subdivision bell sound: $e');
    }
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
