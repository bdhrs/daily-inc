import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/views/widgets/timer_painter.dart';
import 'package:daily_inc/src/core/time_converter.dart';

/// A widget that displays the timer with circular visualization and time text.
///
/// This widget handles both countdown and overtime display modes, using the
/// TimerPainter for the circular visualization and displaying the time text
/// that updates every 100ms.
class TimerDisplayWidget extends StatelessWidget {
  final double totalTime;
  final double elapsedTime;
  final int subdivisions;
  final VoidCallback onTap;
  final bool isOvertime;

  const TimerDisplayWidget({
    super.key,
    required this.totalTime,
    required this.elapsedTime,
    required this.subdivisions,
    required this.onTap,
    required this.isOvertime,
  });

  /// Formats minutes to MM:SS string representation
  String _formatMinutesToMmSs(double minutesValue) {
    return TimeConverter.toMmSsString(minutesValue, padZeroes: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: TimerPainter(
            totalTime: totalTime,
            elapsedTime: elapsedTime,
            subdivisions: subdivisions,
          ),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  isOvertime
                      ? _formatMinutesToMmSs(elapsedTime)
                      : _formatMinutesToMmSs((totalTime - elapsedTime)
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
}
