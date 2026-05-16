import 'dart:math';
import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/core/sequence_helper.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/graph_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniGraphWidget extends StatelessWidget {
  final DailyThing dailyThing;
  final List<DailyThing> allItems;

  const MiniGraphWidget({
    super.key,
    required this.dailyThing,
    this.allItems = const [],
  });

  /// Extracts data points for the graph, showing the last 14 days for consistency across all graphs
  List<FlSpot> _buildSpots() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    const int daysToShow = 14;

    final dates = <DateTime>[];
    for (int i = daysToShow - 1; i >= 0; i--) {
      dates.add(DateTime(todayDate.year, todayDate.month, todayDate.day - i));
    }

    if (dailyThing.itemType == ItemType.sequence) {
      return _buildSequenceSpots(dates);
    }

    // Create a map of history entries for quick lookup
    final historyMap = <DateTime, dynamic>{};
    for (final entry in dailyThing.history) {
      final dateKey =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      historyMap[dateKey] = entry;
    }

    // For trend items, calculate accumulated values
    if (dailyThing.itemType == ItemType.trend) {
      return _buildTrendSpots(dates, historyMap);
    }

    // Build spots for each day
    final spots = <FlSpot>[];
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final entry = historyMap[date];
      double y = 0;

      if (entry != null) {
        if (dailyThing.itemType == ItemType.check) {
          y = entry.doneToday ? 1 : 0;
        } else {
          if (entry.actualValue != null) {
            y = entry.actualValue!;
          }
        }
      }

      final epochDays = date.millisecondsSinceEpoch / (24 * 60 * 1000);
      spots.add(FlSpot(epochDays.toDouble(), y));
    }

    return spots;
  }

  List<FlSpot> _buildSequenceSpots(List<DateTime> dates) {
    final children = SequenceHelper.resolveChildren(dailyThing, allItems);
    final spots = <FlSpot>[];
    for (final date in dates) {
      double total = 0;
      for (final child in children) {
        for (final entry in child.history) {
          final entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          if (entryDate == date) {
            if (child.itemType == ItemType.check) {
              if (entry.doneToday) total += 1;
            } else {
              if (entry.actualValue != null) total += entry.actualValue!;
            }
          }
        }
      }
      final epochDays = date.millisecondsSinceEpoch / (24 * 60 * 1000);
      spots.add(FlSpot(epochDays.toDouble(), total));
    }
    return spots;
  }

  /// Builds spots for trend items with accumulated values.
  /// Missed days (before today) count as -1, with the running total
  /// floored at 0 after every step.
  List<FlSpot> _buildTrendSpots(
      List<DateTime> dates, Map<DateTime, dynamic> historyMap) {
    final series = IncrementCalculator.accumulatedTrendSeries(
        dailyThing.history, dates);
    final spots = <FlSpot>[];
    for (final date in dates) {
      final value = series[date] ?? 0.0;
      final epochDays = date.millisecondsSinceEpoch / (24 * 60 * 1000);
      spots.add(FlSpot(epochDays.toDouble(), value));
    }
    return spots;
  }

  /// Calculates the Y-axis range for the graph
  double _calculateMaxY(List<FlSpot> spots) {
    if (dailyThing.itemType == ItemType.check) {
      return 1.2; // For check items, we only need 0-1 range
    }

    if (spots.isEmpty) return 1.0;

    final values = spots.map((s) => s.y);
    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);

    // For trend items, ensure we have enough range to show negative values
    if (dailyThing.itemType == ItemType.trend) {
      final range = maxValue - minValue;
      final padding = range * 0.1; // 10% padding
      return maxValue + padding;
    }

    return maxValue == 0 ? 1 : maxValue * 1.1; // Add 10% padding
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final maxY = _calculateMaxY(spots);
    final minY = dailyThing.itemType == ItemType.trend && spots.isNotEmpty
        ? spots.map((s) => s.y).reduce(min) *
            1.1 // Allow negative values with padding
        : 0.0;

    return GestureDetector(
      onTap: () {
        // Navigate to the full graph view when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
              GraphView(dailyThing: dailyThing, allItems: allItems),
          ),
        );
      },
      child: SizedBox(
        height: 60, // Approximately 1-2 cm
        child: LineChart(
          LineChartData(
            minX: spots.isNotEmpty ? spots.first.x : 0,
            maxX: spots.isNotEmpty ? spots.last.x : 0,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 2,
                isCurved: false,
                isStepLineChart: true,
                lineChartStepData: const LineChartStepData(
                  stepDirection: 0.76,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
                ),
                dotData: const FlDotData(show: false),
              ),
            ],
            // No border
            borderData: FlBorderData(show: false),
            // No grid lines
            gridData: const FlGridData(show: false),
            // No titles or labels
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            // No tooltips
            lineTouchData: const LineTouchData(enabled: false),
          ),
        ),
      ),
    );
  }
}
