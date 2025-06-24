import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc_timer_flutter/src/data/data_manager.dart';
import 'package:daily_inc_timer_flutter/src/models/daily_thing.dart';
import 'package:daily_inc_timer_flutter/src/models/history_entry.dart';

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

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.item.todayValue * 60).toInt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _runCountdown();
      }
    });
  }

  void _runCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _remainingSeconds <= 0) {
        timer.cancel();
        if (_remainingSeconds <= 0) {
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
    // Play the bell sound
    await _audioPlayer.play(AssetSource('bell.mp3'));

    // Update the history
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final newEntry = HistoryEntry(
      date: todayDate,
      value: widget.item.todayValue,
      doneToday: true,
    );

    final updatedHistory = widget.item.history
        .where((entry) => entry.date != todayDate)
        .toList()
      ..add(newEntry);

    final updatedItem = DailyThing(
      name: widget.item.name,
      itemType: widget.item.itemType,
      startDate: widget.item.startDate,
      startValue: widget.item.startValue,
      duration: widget.item.duration,
      endValue: widget.item.endValue,
      history: updatedHistory,
    );

    await widget.dataManager.updateDailyThing(updatedItem);
    if (!mounted) {
      return; // Ensure the widget is still mounted before using context
    }
    widget.onExitCallback();
    Navigator.of(context).pop();
  }

  void _exitTimerDisplay() {
    widget.onExitCallback();
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
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
    );
  }
}
