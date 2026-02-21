import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

/// A widget that displays subdivision information for the timer.
///
/// This widget handles the display of subdivision information in different modes:
/// - Normal countdown mode with subdivisions
/// - Overtime mode with subdivisions
/// - Normal mode without subdivisions
class SubdivisionDisplayWidget extends StatelessWidget {
  final bool isOvertime;
  final int completedSubdivisions;
  final int? totalSubdivisions;
  final double todaysTargetMinutes;
  final double overtimeSeconds;
  final double currentElapsedTimeInMinutes;
  final String Function(double minutesValue) formatMinutesToMmSs;

  const SubdivisionDisplayWidget({
    super.key,
    required this.isOvertime,
    required this.completedSubdivisions,
    required this.totalSubdivisions,
    required this.todaysTargetMinutes,
    required this.overtimeSeconds,
    required this.currentElapsedTimeInMinutes,
    required this.formatMinutesToMmSs,
  });

  /// Calculates elapsed minutes in current subdivision
  double _calculateElapsedMinutesInCurrentSubdivision() {
    if (totalSubdivisions == null || totalSubdivisions! < 1) {
      return 0.0;
    }

    // For stopwatch, todaysTargetMinutes is 0 and totalSubdivisions is the interval
    if (todaysTargetMinutes == 0) {
      return currentElapsedTimeInMinutes % totalSubdivisions!;
    }

    if (totalSubdivisions! <= 1) {
      return 0.0;
    }

    final double subdivisionDurationInMinutes =
        todaysTargetMinutes / totalSubdivisions!;
    final double elapsedMinutesInCompletedSubdivisions =
        completedSubdivisions * subdivisionDurationInMinutes;
    return currentElapsedTimeInMinutes - elapsedMinutesInCompletedSubdivisions;
  }

  /// Calculates total minutes in current subdivision
  double _calculateTotalMinutesInCurrentSubdivision() {
    if (totalSubdivisions == null || totalSubdivisions! < 1) {
      return 0.0;
    }

    // For stopwatch, todaysTargetMinutes is 0 and totalSubdivisions is the interval
    if (todaysTargetMinutes == 0) {
      return totalSubdivisions!.toDouble();
    }

    if (totalSubdivisions! <= 1) {
      return 0.0;
    }

    return todaysTargetMinutes / totalSubdivisions!;
  }

  /// Calculates overtime minutes in current subdivision
  double _calculateOvertimeMinutesInCurrentSubdivision() {
    if (totalSubdivisions == null || totalSubdivisions! < 1) {
      return 0.0;
    }

    // Overtime doesn't really apply to stopwatch in the same way
    if (todaysTargetMinutes == 0) return 0.0;

    if (totalSubdivisions! <= 1) {
      return 0.0;
    }

    final double subdivisionDurationInMinutes =
        todaysTargetMinutes / totalSubdivisions!;
    final double overtimeMinutes = overtimeSeconds / 60.0;
    return overtimeMinutes % subdivisionDurationInMinutes;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate subdivision values
    final double elapsedMinutesInCurrentSubdivision =
        _calculateElapsedMinutesInCurrentSubdivision();
    final double totalMinutesInCurrentSubdivision =
        _calculateTotalMinutesInCurrentSubdivision();
    final double overtimeMinutesInCurrentSubdivision =
        _calculateOvertimeMinutesInCurrentSubdivision();

    if (isOvertime && todaysTargetMinutes > 0) {
      return _buildOvertimeDisplay(
        overtimeMinutesInCurrentSubdivision,
        totalMinutesInCurrentSubdivision,
      );
    } else if (totalSubdivisions != null &&
        totalSubdivisions! >= (todaysTargetMinutes == 0 ? 1 : 2)) {
      return _buildNormalDisplay(
        elapsedMinutesInCurrentSubdivision,
        totalMinutesInCurrentSubdivision,
      );
    } else {
      return _buildSimpleDisplay();
    }
  }

  /// Builds the display for overtime mode with subdivisions
  Widget _buildOvertimeDisplay(
    double overtimeMinutesInCurrentSubdivision,
    double totalMinutesInCurrentSubdivision,
  ) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${formatMinutesToMmSs(todaysTargetMinutes)} + ${formatMinutesToMmSs(overtimeSeconds / 60.0)}',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            '${completedSubdivisions + 1} / $totalSubdivisions',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${formatMinutesToMmSs(overtimeMinutesInCurrentSubdivision)} / ${formatMinutesToMmSs(todaysTargetMinutes / totalSubdivisions!)}',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the display for normal mode with subdivisions
  Widget _buildNormalDisplay(
    double elapsedMinutesInCurrentSubdivision,
    double totalMinutesInCurrentSubdivision,
  ) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            todaysTargetMinutes == 0
                ? formatMinutesToMmSs(currentElapsedTimeInMinutes)
                : '${formatMinutesToMmSs(currentElapsedTimeInMinutes)} / ${formatMinutesToMmSs(todaysTargetMinutes)}',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            todaysTargetMinutes == 0
                ? '${completedSubdivisions + 1}'
                : '${completedSubdivisions + 1} / $totalSubdivisions',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${formatMinutesToMmSs(elapsedMinutesInCurrentSubdivision)} / ${formatMinutesToMmSs(totalMinutesInCurrentSubdivision)}',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to save vertical space
              color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the simple display for normal mode without subdivisions
  Widget _buildSimpleDisplay() {
    return Text(
      todaysTargetMinutes == 0
          ? formatMinutesToMmSs(currentElapsedTimeInMinutes)
          : '${formatMinutesToMmSs(currentElapsedTimeInMinutes)} / ${formatMinutesToMmSs(todaysTargetMinutes)}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14, // Reduced from 16 to save vertical space
        color: ColorPalette.lightText.withAlpha((255 * 0.7).round()),
      ),
    );
  }
}
