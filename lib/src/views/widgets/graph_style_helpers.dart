import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GraphStyle {
  static const Color lineColor = Colors.blue;
  static const double lineWidth = 2;
  static const double stepDirection = 0.76;
  static Color areaColor(BuildContext context) =>
      Colors.blue.withValues(alpha: 0.25);
  static FlDotData get dotData => const FlDotData(show: false);
  static FlLine thinGreyLine(bool strong) => FlLine(
        color: strong ? Colors.grey.shade500 : Colors.grey.shade700,
        strokeWidth: strong ? 1.5 : 1,
      );
}

// Extension to add log10 method to num
extension on num {
  double log10() => log(this) / log(10);
}

class GraphStyleHelpers {
  static double epochDays(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
  }

  static DateTime dateFromEpochDays(double v) {
    final ms = (v * 24 * 60 * 60 * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Calculate a reasonable interval for Y-axis labels
  static double calculateYAxisInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1;

    // Find a "nice" interval (1, 2, 5, 10, 20, 50, 100, etc.)
    final roughInterval = range / 5; // Aim for about 5 labels
    final exponent = pow(10, roughInterval.log10().floor()).toDouble();

    if (roughInterval < 1.5 * exponent) {
      return exponent;
    } else if (roughInterval < 3 * exponent) {
      return 2 * exponent;
    } else if (roughInterval < 7.5 * exponent) {
      return 5 * exponent;
    } else {
      return 10 * exponent;
    }
  }

  /// Generates the styles for the graph titles
  static FlTitlesData getTitlesData({
    required BuildContext context,
    required double minY,
    required double maxY,
    required String yAxisName,
    List<DateTime>? sortedDates, // For BarChart
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const Text('');
            }
            final interval = calculateYAxisInterval(minY, maxY);
            final roundedValue = (value / interval).round() * interval;
            if ((value - roundedValue).abs() < interval * 0.01) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return const Text('');
          },
        ),
        axisNameWidget: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            yAxisName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          interval: sortedDates != null ? null : 24 * 60 * 60 * 1000,
          getTitlesWidget: (value, meta) {
            if (sortedDates != null) {
              // BarChart logic
              final index = value.toInt();
              if (index >= 0 && index < sortedDates.length) {
                if (index == 0 || index == sortedDates.length - 1) {
                  return const Text('');
                }
                final date = sortedDates[index];
                if (date.weekday == DateTime.monday) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
              }
            } else {
              // LineChart logic
              if (value == meta.min || value == meta.max) {
                return const Text('');
              }
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              if (date.weekday == DateTime.monday) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
            }
            return const Text('');
          },
        ),
        axisNameWidget: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            'Date',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// Generates the styles for the graph grid
  static FlGridData getGridData(
      {List<DateTime>? sortedDates, double? minY, double? maxY}) {
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: Colors.white12, strokeWidth: 1),
      drawVerticalLine: true,
      verticalInterval:
          sortedDates != null ? 1 : (24 * 60 * 60 * 1000).toDouble(),
      checkToShowVerticalLine: (v) {
        if (sortedDates != null) {
          return v % 1 == 0;
        } else {
          return v % (24 * 60 * 60 * 1000) == 0;
        }
      },
      getDrawingVerticalLine: (value) {
        if (sortedDates != null) {
          final i = value.toInt();
          if (i >= 0 && i < sortedDates.length) {
            final isMonday = sortedDates[i].weekday == DateTime.monday;
            return FlLine(
              color: isMonday ? Colors.grey.shade400 : Colors.grey.shade200,
              strokeWidth: isMonday ? 2 : 1,
              dashArray: null,
            );
          }
        } else {
          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
          final isMonday = date.weekday == DateTime.monday;
          return FlLine(
            color: isMonday ? Colors.grey.shade400 : Colors.grey.shade200,
            strokeWidth: isMonday ? 2 : 1,
            dashArray: null,
          );
        }
        return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
      },
    );
  }

  /// Generates the styles for the graph border
  static FlBorderData getBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: Colors.grey.shade300, width: 1),
    );
  }
}
