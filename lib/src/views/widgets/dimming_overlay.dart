import 'package:flutter/material.dart';
import 'dart:async';

class DimmingOverlayWidget extends StatefulWidget {
  final bool dimScreenMode;
  final double dimOpacity;
  final bool isPaused;
  final VoidCallback startDimmingProcess;
  final VoidCallback restoreScreenBrightness;

  const DimmingOverlayWidget({
    super.key,
    required this.dimScreenMode,
    required this.dimOpacity,
    required this.isPaused,
    required this.startDimmingProcess,
    required this.restoreScreenBrightness,
  });

  @override
  State<DimmingOverlayWidget> createState() => _DimmingOverlayWidgetState();
}

class _DimmingOverlayWidgetState extends State<DimmingOverlayWidget> {
  Timer? _tapTimer;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    // Temporarily restore visibility when tapped
    widget.restoreScreenBrightness();

    // Restart dimming after a delay if still in dim mode and timer is running
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 3), () {
      if (!widget.isPaused && widget.dimScreenMode) {
        widget.startDimmingProcess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show the overlay when dim screen mode is enabled and opacity is greater than 0
    if (!widget.dimScreenMode || widget.dimOpacity <= 0.0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          color: Color.fromARGB((widget.dimOpacity * 255).round(), 0, 0, 0),
        ),
      ),
    );
  }
}
