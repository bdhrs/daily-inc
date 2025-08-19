import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mixin to provide common graph functionality for Daily Inc Timer graphs.
/// This includes time range selection, axis configuration, grid setup, and trend line calculation.
mixin BaseGraphStateMixin<T extends StatefulWidget> on State<T> {
  final Logger _log = Logger('BaseGraphStateMixin');
  
  /// The currently selected time range for the graph.
  TimeRange _selectedTimeRange = TimeRange.twelveWeeks;

  /// The key used to store the time range preference in SharedPreferences.
  /// Must be overridden by the implementing class.
  String get prefsKey;

  /// The minimum value on the Y-axis.
  double get minY;

  /// The maximum value on the Y-axis.
  double get maxY;

  /// The list of data spots for the graph.
  List<FlSpot> get spots;

  /// The context for building widgets.
  BuildContext get graphContext => context;

  /// Loads the time range preference from SharedPreferences.
  Future<void> loadTimeRangePreference() async {
    _log.info('Loading time range preference with key: \$prefsKey');
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(prefsKey);
    if (savedValue != null) {
      try {
        _selectedTimeRange = TimeRange.values.firstWhere(
          (e) => e.name == savedValue,
          orElse: () => TimeRange.twelveWeeks,
        );
      } catch (e) {
        _selectedTimeRange = TimeRange.twelveWeeks;
      }
    }
    _log.info('Loaded time range preference: \$_selectedTimeRange');
  }

  /// Saves the current time range preference to SharedPreferences.
  Future<void> saveTimeRangePreference() async {
    _log.info('Saving time range preference: \$_selectedTimeRange with key: \$prefsKey');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, _selectedTimeRange.name);
  }

  /// Updates the selected time range and triggers a rebuild.
  void updateTimeRange(TimeRange newRange) {
    _log.info('Updating time range to: \$newRange');
    setState(() {
      _selectedTimeRange = newRange;
    });
  }

  /// Gets the currently selected time range.
  TimeRange get selectedTimeRange => _selectedTimeRange;

  /// Builds the dropdown menu for selecting the time range.
  Widget buildTimeRangeDropdown(VoidCallback onTimeRangeChanged) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<TimeRange>(
        value: _selectedTimeRange,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.white),
        underline: Container(
          height: 2,
          color: Colors.white,
        ),
        onChanged: (TimeRange? newValue) {
          if (newValue != null) {
            updateTimeRange(newValue);
            saveTimeRangePreference();
            onTimeRangeChanged();
          }
        },
        items: TimeRange.values
            .map<DropdownMenuItem<TimeRange>>((TimeRange value) {
              return DropdownMenuItem<TimeRange>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
      ),
    );
  }

  /// Builds the axis titles for the graph.
  FlTitlesData buildAxisTitles(BuildContext context, double minY, double maxY) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            final interval = GraphStyleHelpers.calculateYAxisInterval(minY, maxY);
            final rounded = (value / interval).round() * interval;
            if ((value - rounded).abs() < interval * 0.01) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            // X axis uses \"epoch days\" (days since Unix epoch) as doubles.
            // Render labels only on Mondays as M/d for shorter ranges.
            // For longer ranges (12+ weeks), show labels every other Monday to prevent cramped labels.
            final v = value.roundToDouble();
            if (v != value) return const SizedBox.shrink();
            final d = GraphStyleHelpers.dateFromEpochDays(v);

            // Only show labels on Mondays
            if (d.weekday == DateTime.monday) {
              // For longer time ranges, show labels every other Monday
              if (_selectedTimeRange == TimeRange.twelveWeeks ||
                  _selectedTimeRange == TimeRange.sixteenWeeks) {
                // Calculate weeks since a reference point to determine if this should be a label
                final daysSinceEpoch = d.difference(DateTime(1970, 1, 1)).inDays;
                final weeksSinceEpoch = daysSinceEpoch ~/ 7;
                if (weeksSinceEpoch % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('M/d').format(d),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
              } else {
                // For shorter time ranges, show labels on every Monday
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(d),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// Builds the grid data for the graph.
  FlGridData buildGridData(double minY, double maxY) {
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      horizontalInterval: GraphStyleHelpers.calculateYAxisInterval(minY, maxY),
      getDrawingHorizontalLine: (v) => FlLine(
        color: (v % 10 == 0) ? Colors.grey.shade500 : Colors.grey.shade700,
        strokeWidth: (v % 10 == 0) ? 1.5 : 1,
      ),
      drawVerticalLine: true,
      verticalInterval: 1,
      checkToShowVerticalLine: (v) => v.roundToDouble() % 1 == 0,
      getDrawingVerticalLine: (v) {
        final d = GraphStyleHelpers.dateFromEpochDays(v);
        final isMonday = d.weekday == DateTime.monday;
        return FlLine(
          color: isMonday ? Colors.grey.shade500 : Colors.grey.shade700,
          strokeWidth: isMonday ? 1.5 : 1,
        );
      },
    );
  }

  /// Calculates the trend line points using linear regression.
  /// The trend line only spans actual data points, not the full time range.
  List<FlSpot> calculateTrendLine(List<FlSpot> spots, double minY, double maxY) {
    // Collect values for dates with actual data (non-zero values)
    final dataPoints = <Point>[];
    
    // Filter spots to only include those with actual data
    for (final spot in spots) {
      // Only include points with actual data (non-zero values) for trend calculation
      // This ensures the trend line only spans dates where there's actual activity
      if (spot.y > 0) {
        dataPoints.add(Point(spot.x, spot.y));
      }
    }

    // Need at least 2 points to calculate a trend
    if (dataPoints.length < 2) return [];

    // Perform linear regression: y = mx + b using only actual data points
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = dataPoints.length.toDouble();

    for (final point in dataPoints) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumXX += point.x * point.x;
    }

    // Prevent division by zero
    final denominator = (n * sumXX - sumX * sumX);
    if (denominator == 0) {
      // If all x values are the same, return a flat line at the average y value
      final averageY = sumY / n;
      // Constrain to graph bounds
      final constrainedY = averageY.clamp(minY, maxY);
      return [
        FlSpot(dataPoints.first.x, constrainedY),
        FlSpot(dataPoints.last.x, constrainedY),
      ];
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Create line from first to last actual data point using the regression formula
    final firstX = dataPoints.first.x;
    final lastX = dataPoints.last.x;
    final firstY = (slope * firstX + intercept).clamp(minY, maxY);
    final lastY = (slope * lastX + intercept).clamp(minY, maxY);

    return [
      FlSpot(firstX, firstY),
      FlSpot(lastX, lastY),
    ];
  }

  /// Builds the touch tooltip data for the graph.
  LineTouchTooltipData buildTouchTooltipData(List<FlSpot> spots, List<dynamic> historyEntries, DateTime Function(double) dateFromEpochDays) {
    return LineTouchTooltipData(
      maxContentWidth: 200,
      fitInsideHorizontally: true,
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((spotData) {
          if (spotData.barIndex == 1) { // Trend line
            return null;
          }
          final spotIndex = spotData.spotIndex;
          if (spotIndex >= spots.length) return null;

          final spot = spots[spotIndex];
          final d = dateFromEpochDays(spot.x);
          final dateKey = DateTime(d.year, d.month, d.day);

          dynamic entry;
          try {
            entry = historyEntries.firstWhere((e) =>
                DateTime(e.date.year, e.date.month, e.date.day) == dateKey);
          } catch (e) {
            entry = null;
          }

          final children = <TextSpan>[];

          if (entry != null) {
            // For check type, we might want to show "Done" or "Not Done"
            // For other types, we show the actual value
            String valueText;
            if (entry.doneToday != null && entry.doneToday) {
              valueText = "Done";
            } else if (entry.actualValue != null) {
              valueText = entry.actualValue.toStringAsFixed(1);
            } else {
              valueText = "0";
            }
            
            children.add(
              TextSpan(
                text: valueText,
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            );

            if (entry.comment != null && entry.comment!.isNotEmpty) {
              children.add(
                TextSpan(
                  text: '\n${entry.comment}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal),
                ),
              );
            }
          } else {
            // If no entry, show 0 or "Not Done"
            children.add(
              TextSpan(
                text: "0",
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          return LineTooltipItem(
            '${DateFormat('M/d').format(d)}\n',
            const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
            children: children,
          );
        }).toList();
      },
    );
  }
}

/// A simple point class for trend line calculation.
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}