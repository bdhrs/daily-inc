import 'package:flutter/material.dart';

/// A widget that displays the timer control buttons (Start/Pause/Continue and Exit).
///
/// This widget handles the display and functionality of the timer control buttons,
/// including the dynamic button text based on the timer state.
class TimerControlsWidget extends StatelessWidget {
  final String Function() getButtonText;
  final VoidCallback toggleTimer;
  final VoidCallback exitTimerDisplay;

  const TimerControlsWidget({
    super.key,
    required this.getButtonText,
    required this.toggleTimer,
    required this.exitTimerDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8), // Reduced from 12 to save vertical space
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: toggleTimer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8), // Reduced padding
                  minimumSize: const Size(0, 40), // Set minimum height
                ),
                child: Text(
                  getButtonText(),
                  style: const TextStyle(fontSize: 14), // Smaller font size
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: exitTimerDisplay,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8), // Reduced padding
                  minimumSize: const Size(0, 40), // Set minimum height
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(fontSize: 14), // Smaller font size
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
