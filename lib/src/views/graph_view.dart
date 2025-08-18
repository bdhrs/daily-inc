import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}

class GraphView extends StatefulWidget {
  final DailyThing dailyThing;
  const GraphView({super.key, required this.dailyThing});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  double _minY = 0;
  double _maxY = 0;
  final _log = Logger('GraphView');
  List<FlSpot> _spots = [];
  TimeRange _selectedTimeRange = TimeRange.twelveWeeks;
  static const String _prefsKey = 'graph_time_range_preference';

  @override
  void initState() {
    super.initState();
    _log.info('initState called for item: ${widget.dailyThing.name}');
    _loadTimeRangePreference();
  }

  Future<void> _loadTimeRangePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_prefsKey);
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
    // Now that we have the time range preference, build the spots
    _spots = _buildSpots();
    _calculateRanges();
    setState(() {}); // Rebuild with loaded preference
  }

  Future<void> _saveTimeRangePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _selectedTimeRange.name);
  }

  void _onTimeRangeChanged(TimeRange newRange) {
    setState(() {
      _selectedTimeRange = newRange;
    });
    _saveTimeRangePreference();
    // Rebuild spots with new time range
    _spots = _buildSpots();
    _calculateRanges();
  }

  void _calculateRanges() {
    _log.info('Calculating graph ranges...');
    if (widget.dailyThing.itemType == ItemType.check) {
      _minY = 0;
      _maxY = 1.2;
    } else {
      final maxValue =
          _spots.isEmpty ? 0.0 : _spots.map((s) => s.y).reduce(max);
      _minY = 0;
      _maxY = maxValue == 0 ? 1 : maxValue * 1.1;
    }
    _log.info('Ranges calculated: Y($_minY, $_maxY)');
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dailyThing.name),
        actions: [
          DropdownButtonHideUnderline(
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
                  _onTimeRangeChanged(newValue);
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
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LineChart(
          LineChartData(
            minX: _epochDays(_getFilteredDates().first).floorToDouble(),
            maxX: _epochDays(_getFilteredDates().last).ceilToDouble(),
            minY: _minY,
            maxY: _maxY,
            lineBarsData: [
              LineChartBarData(
                spots: _spots,
                color: GraphStyle.lineColor,
                barWidth: GraphStyle.lineWidth,
                isCurved: false,
                isStepLineChart: true,
                lineChartStepData: const LineChartStepData(
                    stepDirection: GraphStyle.stepDirection),
                belowBarData: BarAreaData(
                    show: true, color: GraphStyle.areaColor(context)),
                dotData: const FlDotData(show: false),
              ),
              // Trend line
              LineChartBarData(
                spots: _calculateTrendLine(),
                color: Colors.white,
                barWidth: 2.5,
                isCurved: true,
                curveSmoothness: 0.1,
                dashArray: [5, 5], // Dashed line pattern
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    final interval =
                        GraphStyleHelpers.calculateYAxisInterval(_minY, _maxY);
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
                    // X axis uses "epoch days" (days since Unix epoch) as doubles.
                    // Render labels only on Mondays as M/d for shorter ranges.
                    // For longer ranges (12+ weeks), show labels every other Monday to prevent cramped labels.
                    final v = value.roundToDouble();
                    if (v != value) return const SizedBox.shrink();
                    final d = _dateFromEpochDays(v);

                    // Only show labels on Mondays
                    if (d.weekday == DateTime.monday) {
                      // For longer time ranges, show labels every other Monday
                      if (_selectedTimeRange == TimeRange.twelveWeeks ||
                          _selectedTimeRange == TimeRange.sixteenWeeks) {
                        // Calculate weeks since a reference point to determine if this should be a label
                        final daysSinceEpoch =
                            d.difference(DateTime(1970, 1, 1)).inDays;
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
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: GraphStyleHelpers.getBorderData(),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: widget.dailyThing.itemType == ItemType.check
                  ? 1
                  : GraphStyleHelpers.calculateYAxisInterval(_minY, _maxY),
              getDrawingHorizontalLine: (v) => FlLine(
                color:
                    (v % 10 == 0) ? Colors.grey.shade500 : Colors.grey.shade700,
                strokeWidth: (v % 10 == 0) ? 1.5 : 1,
              ),
              drawVerticalLine: true,
              verticalInterval: 1,
              checkToShowVerticalLine: (v) => v.roundToDouble() % 1 == 0,
              getDrawingVerticalLine: (v) {
                final d = _dateFromEpochDays(v);
                final isMonday = d.weekday == DateTime.monday;
                return FlLine(
                  color: isMonday ? Colors.grey.shade500 : Colors.grey.shade700,
                  strokeWidth: isMonday ? 1.5 : 1,
                );
              },
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              getTouchedSpotIndicator: (bar, spots) => spots
                  .map((s) => const TouchedSpotIndicatorData(
                        FlLine(color: Colors.transparent, strokeWidth: 0),
                        FlDotData(show: false),
                      ))
                  .toList(),
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                maxContentWidth: 200,
                fitInsideHorizontally: true,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .map((spotData) {
                        final spotIndex = spotData.spotIndex;
                        if (spotIndex >= _spots.length) return null;

                        final spot = _spots[spotIndex];
                        final d = _dateFromEpochDays(spot.x);
                        final dateKey = DateTime(d.year, d.month, d.day);

                        dynamic entry;
                        try {
                          entry = widget.dailyThing.history.firstWhere((e) =>
                              DateTime(e.date.year, e.date.month, e.date.day) ==
                              dateKey);
                        } catch (e) {
                          entry = null;
                        }

                        final children = <TextSpan>[
                          TextSpan(
                            text: spot.y.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ];

                        if (entry != null &&
                            entry.comment != null &&
                            entry.comment!.isNotEmpty) {
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

                        return LineTooltipItem(
                          '${DateFormat('M/d').format(d)}\n',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          children: children,
                        );
                      })
                      .whereType<LineTooltipItem>()
                      .toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final dates = _getFilteredDates();
    final historyMap = <DateTime, dynamic>{};
    for (final entry in widget.dailyThing.history) {
      final dateKey =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      historyMap[dateKey] = entry;
    }
    final spots = <FlSpot>[];
    for (final d in dates) {
      final entry = historyMap[d];
      double y = 0;
      if (entry != null) {
        if (widget.dailyThing.itemType == ItemType.check) {
          if (entry.doneToday) y = 1;
        } else {
          if (entry.actualValue != null) y = entry.actualValue!;
        }
      }
      spots.add(FlSpot(_epochDays(d), y));
    }
    return spots;
  }

  double _epochDays(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.millisecondsSinceEpoch / (24 * 60 * 60 * 1000);
  }

  DateTime _dateFromEpochDays(double v) {
    final ms = (v * 24 * 60 * 60 * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // Removed old _getBarGroups implementation after switching to LineChart

  List<DateTime> _getFilteredDates() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // For "all" time range, use the first history entry date of this specific item
    if (_selectedTimeRange == TimeRange.all &&
        widget.dailyThing.history.isNotEmpty) {
      final sortedHistory = widget.dailyThing.history.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final firstHistoryDate = DateTime(sortedHistory.first.date.year,
          sortedHistory.first.date.month, sortedHistory.first.date.day);
      final itemStartDate = DateTime(widget.dailyThing.startDate.year,
          widget.dailyThing.startDate.month, widget.dailyThing.startDate.day);
      final startDate = firstHistoryDate.isBefore(itemStartDate)
          ? firstHistoryDate
          : itemStartDate;
      return _generateDateRange(startDate, todayDate);
    }

    // For other time ranges, use the standard logic
    final startDate = _selectedTimeRange.getStartDate(todayDate);

    if (widget.dailyThing.history.isEmpty) {
      return _generateDateRange(startDate, todayDate);
    }

    final sortedHistory = widget.dailyThing.history.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final firstHistoryDate = DateTime(sortedHistory.first.date.year,
        sortedHistory.first.date.month, sortedHistory.first.date.day);
    final itemStartDate = DateTime(widget.dailyThing.startDate.year,
        widget.dailyThing.startDate.month, widget.dailyThing.startDate.day);

    final earliestDate = [firstHistoryDate, itemStartDate, startDate]
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return _generateDateRange(earliestDate, todayDate)
        .where((date) => !date.isBefore(startDate))
        .toList();
  }

  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    for (DateTime d = start;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)) {
      dates.add(d);
    }
    return dates;
  }

  /// Calculate trend line points using linear regression
  /// The trend line only spans actual data points, not the full time range
  List<FlSpot> _calculateTrendLine() {
    // Get history data
    final historyMap = <DateTime, dynamic>{};
    for (final entry in widget.dailyThing.history) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      historyMap[dateKey] = entry;
    }

    // Collect actual values for dates with data
    final dataPoints = <Point>[];
    
    // Get the filtered dates to respect the time range
    final dates = _getFilteredDates();
    for (final d in dates) {
      final entry = historyMap[d];
      double y = 0;
      if (entry != null) {
        if (widget.dailyThing.itemType == ItemType.check) {
          if (entry.doneToday) y = 1;
        } else {
          if (entry.actualValue != null) y = entry.actualValue!;
        }
      }
      // Only include points with actual data for trend calculation
      if (y > 0 || widget.dailyThing.itemType == ItemType.check) {
        dataPoints.add(Point(_epochDays(d), y));
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
      final constrainedY = averageY.clamp(_minY, _maxY);
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
    final firstY = (slope * firstX + intercept).clamp(_minY, _maxY);
    final lastY = (slope * lastX + intercept).clamp(_minY, _maxY);
    
    return [
      FlSpot(firstX, firstY),
      FlSpot(lastX, lastY),
    ];
  }
}
