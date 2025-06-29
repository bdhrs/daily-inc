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
  bool _isPaused = true;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _log = Logger('TimerView');

  @override
  void initState() {
    super.initState();
    _log.info('initState called for item: ${widget.item.name}');
    _remainingSeconds = (widget.item.todayValue * 60).toInt();
    _log.info('Initial remaining seconds: $_remainingSeconds');
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
        WakelockPlus.enable();
        _runCountdown();
      } else {
        _log.info('Timer paused, disabling wakelock.');
        WakelockPlus.disable();
      }
    });
  }

  void _runCountdown() {
    _log.info('runCountdown called');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _remainingSeconds <= 0) {
        _log.info('Timer stopping.');
        timer.cancel();
        if (_remainingSeconds <= 0) {
          _log.info('Timer completed.');
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
    final newEntry = HistoryEntry(
      date: todayDate,
      value: widget.item.todayValue,
      doneToday: true,
    );
    _log.info('Created new history entry for today.');

    final updatedHistory = widget.item.history
        .where((entry) => entry.date != todayDate)
        .toList()
      ..add(newEntry);

    final updatedItem = DailyThing(
      id: widget.item.id,
      name: widget.item.name,
      itemType: widget.item.itemType,
      startDate: widget.item.startDate,
      startValue: widget.item.startValue,
      duration: widget.item.duration,
      endValue: widget.item.endValue,
      history: updatedHistory,
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

  void _exitTimerDisplay() {
    _log.info('exitTimerDisplay called');
    widget.onExitCallback();
    WakelockPlus.disable();
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    // No logging here as it's a pure formatting function called frequently.
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    return Scaffold(
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

                    // Calculate font size to fit 60% of available width for the widest case
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
    );
  }
}
