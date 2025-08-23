/// A comprehensive utility class for time conversions between decimal minutes
/// and minutes/seconds components with various formatting options.
class TimeConverter {
  /// Converts decimal minutes to TimeComponents object
  static TimeComponents fromDecimalMinutes(double decimalMinutes) {
    if (decimalMinutes.isNaN || decimalMinutes.isInfinite) {
      throw ArgumentError('Decimal minutes must be a finite number');
    }

    // Handle negative values by taking absolute value and preserving sign
    final isNegative = decimalMinutes < 0;
    final absMinutes = decimalMinutes.abs();

    final minutes = absMinutes.truncate();
    final seconds = ((absMinutes - minutes) * 60).round();

    // Handle seconds overflow (e.g., 2.999 minutes = 2:60 → 3:00)
    final adjustedMinutes = minutes + (seconds ~/ 60);
    final adjustedSeconds = seconds % 60;

    return TimeComponents(
      minutes: isNegative ? -adjustedMinutes : adjustedMinutes,
      seconds: adjustedSeconds,
    );
  }

  /// Converts minutes and seconds to decimal format
  static double toDecimalMinutes(int minutes, int seconds) {
    if (!validateSeconds(seconds)) {
      throw ArgumentError('Seconds must be between 0 and 59');
    }

    // Handle negative minutes with positive seconds
    final isNegative = minutes < 0;
    final absMinutes = minutes.abs();

    return (isNegative ? -1 : 1) * (absMinutes + seconds / 60.0);
  }

  /// Formats decimal minutes as MM:SS string with optional zero padding
  static String toMmSsString(double decimalMinutes, {bool padZeroes = false}) {
    final components = fromDecimalMinutes(decimalMinutes);
    return components.toString(padZeroes: padZeroes);
  }

  /// Formats decimal minutes with smart formatting (5m for whole, 5:30 for fractional)
  static String toSmartString(double decimalMinutes) {
    final components = fromDecimalMinutes(decimalMinutes);

    // If seconds are zero and minutes are whole, use "5m" format
    if (components.seconds == 0) {
      return '${components.minutes}m';
    }

    // Otherwise use "5:30" format
    return components.toString();
  }

  /// Converts decimal minutes to total seconds
  static int toTotalSeconds(double decimalMinutes) {
    return (decimalMinutes * 60).round();
  }

  /// Converts total seconds to decimal minutes
  static double fromTotalSeconds(int totalSeconds) {
    return totalSeconds / 60.0;
  }

  /// Validates minutes value (can be negative for countdowns)
  static bool validateMinutes(int minutes) {
    return minutes.isFinite;
  }

  /// Validates seconds value (0-59)
  static bool validateSeconds(int seconds) {
    return seconds >= 0 && seconds <= 59;
  }
}

/// Data class representing minutes and seconds components
class TimeComponents {
  final int minutes;
  final int seconds;

  TimeComponents({required this.minutes, required this.seconds}) {
    if (!TimeConverter.validateSeconds(seconds)) {
      throw ArgumentError('Seconds must be between 0 and 59');
    }
  }

  /// Returns formatted string (with optional zero padding)
  @override
  String toString({bool padZeroes = false}) {
    final absMinutes = minutes.abs();
    final sign = minutes < 0 ? '-' : '';

    if (padZeroes) {
      return '$sign${absMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$sign$absMinutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Converts to decimal minutes
  double toDecimal() {
    return TimeConverter.toDecimalMinutes(minutes, seconds);
  }

  /// Converts to total seconds
  int toTotalSeconds() {
    return (minutes * 60 + seconds) * (minutes < 0 ? -1 : 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeComponents &&
          runtimeType == other.runtimeType &&
          minutes == other.minutes &&
          seconds == other.seconds;

  @override
  int get hashCode => minutes.hashCode ^ seconds.hashCode;
}
