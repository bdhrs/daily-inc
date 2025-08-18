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

class CategoryGraphView extends StatefulWidget {
  final List<DailyThing> dailyThings;
  const CategoryGraphView({super.key, required this.dailyThings});

  @override
  State<CategoryGraphView> createState() => _CategoryGraphViewState();
}

class _CategoryGraphViewState extends State<CategoryGraphView> {
  final _log = Logger('CategoryGraphView');
  TimeRange _selectedTimeRange = TimeRange.twelveWeeks;
  static const String _prefsKey = 'category_graph_time_range_preference';

  final Map<String, Map<DateTime, double>> _categoryData = {};

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
    // Now that we have the time range preference, process the category data
    _processCategoryData();
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
    // Re-process category data with new time range
    _processCategoryData();
  }

  @override
  void initState() {
    super.initState();
    _log.info('initState called for category graph view');
    _loadTimeRangePreference();
  }

  void _processCategoryData() {
    _log.info('Processing category data...');
    _categoryData.clear();

    final Map<String, List<DailyThing>> itemsByCategory = {};
    for (final thing in widget.dailyThings) {
      if (thing.category.isNotEmpty) {
        itemsByCategory.putIfAbsent(thing.category, () => []).add(thing);
      }
    }

    for (final entry in itemsByCategory.entries) {
      final category = entry.key;
      final items = entry.value;

      // Get the date range based on the selected time range
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // For "all" time range, use the earliest history entry of any item within the category
      DateTime startDate;
      if (_selectedTimeRange == TimeRange.all) {
        DateTime? earliestHistoryDate;
        DateTime? earliestItemStartDate;

        for (final thing in items) {
          // Check item start date
          final itemStartDate = DateTime(
              thing.startDate.year, thing.startDate.month, thing.startDate.day);
          if (earliestItemStartDate == null ||
              itemStartDate.isBefore(earliestItemStartDate)) {
            earliestItemStartDate = itemStartDate;
          }

          // Check history dates
          for (final historyEntry in thing.history) {
            final historyDate = DateTime(historyEntry.date.year,
                historyEntry.date.month, historyEntry.date.day);
            if (earliestHistoryDate == null ||
                historyDate.isBefore(earliestHistoryDate)) {
              earliestHistoryDate = historyDate;
            }
          }
        }

        // Use the earlier of the earliest history date and earliest item start date
        startDate = (earliestHistoryDate != null &&
                (earliestItemStartDate == null ||
                    earliestHistoryDate.isBefore(earliestItemStartDate)))
            ? earliestHistoryDate
            : earliestItemStartDate ?? todayDate;
      } else {
        // For other time ranges, use the standard logic
        startDate = _selectedTimeRange.getStartDate(todayDate);
      }

      DateTime? minDate;
      DateTime? maxDate;
      for (final thing in items) {
        final start = DateTime(
            thing.startDate.year, thing.startDate.month, thing.startDate.day);
        // Only consider dates within the selected time range
        final effectiveStart = start.isBefore(startDate) ? startDate : start;
        if (minDate == null || effectiveStart.isBefore(minDate)) {
          minDate = effectiveStart;
        }

        for (final historyEntry in thing.history) {
          final date = DateTime(historyEntry.date.year, historyEntry.date.month,
              historyEntry.date.day);
          // Only consider dates within the selected time range
          if (date.isBefore(startDate)) continue;
          if (minDate == null || date.isBefore(minDate)) minDate = date;
          if (maxDate == null || date.isAfter(maxDate)) maxDate = date;
        }
      }

      // For non-"all" time ranges, ensure minDate is at least startDate
      if (_selectedTimeRange != TimeRange.all) {
        minDate = minDate == null || startDate.isBefore(minDate)
            ? startDate
            : minDate;
      }

      // If no data within the selected time range, skip this category
      if (minDate == null || maxDate == null) {
        _categoryData[category] = {};
        continue;
      }

      final endDate = maxDate.isAfter(todayDate) ? maxDate : todayDate;

      final dateTotals = <DateTime, double>{};
      DateTime currentDate = minDate;
      int count = 0;
      const maxDays = 1000; // Limit to prevent performance issues

      while (!currentDate.isAfter(endDate) && count < maxDays) {
        // Skip dates before the start date (for "all" time range) or ensure we start from startDate (for other time ranges)
        if ((_selectedTimeRange == TimeRange.all &&
                currentDate.isBefore(startDate)) ||
            (_selectedTimeRange != TimeRange.all &&
                currentDate.isBefore(startDate))) {
          currentDate = DateTime(
              currentDate.year, currentDate.month, currentDate.day + 1);
          continue;
        }

        double total = 0;
        for (final thing in items) {
          final sameDayEntries = thing.history.where((e) {
            final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
            return entryDate == currentDate;
          });
          for (final e in sameDayEntries) {
            if (thing.itemType == ItemType.check) {
              if (e.doneToday) total += 1.0;
            } else {
              if (e.actualValue != null) total += e.actualValue!;
            }
          }
        }
        dateTotals[currentDate] = total;

        currentDate =
            DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
        count++;
      }

      _categoryData[category] = dateTotals;
    }

    _log.info('Processed data for ${_categoryData.length} categories');
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress by Category'),
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
      body: _categoryData.isEmpty
          ? const Center(child: Text('No category data available'))
          : ListView.builder(
              itemCount: _categoryData.length,
              itemBuilder: (context, index) {
                final category = _categoryData.keys.elementAt(index);
                final dateTotals = _categoryData[category]!;
                if (category == 'None') return const SizedBox.shrink();
                return _buildCategoryGraph(category, dateTotals, context);
              },
            ),
    );
  }

  Widget _buildCategoryGraph(
      String category, Map<DateTime, double> dateTotals, BuildContext context) {
    double maxY = 0;
    if (dateTotals.isNotEmpty) {
      maxY = dateTotals.values.reduce(max);
      maxY = maxY == 0 ? 1 : maxY * 1.1;
    } else {
      maxY = 1;
    }

    final sortedDates = dateTotals.keys.toList()..sort();
    if (sortedDates.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: GraphStyleHelpers.epochDays(sortedDates.first)
                      .floorToDouble(),
                  maxX: GraphStyleHelpers.epochDays(sortedDates.last)
                      .ceilToDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildCategorySpots(sortedDates, dateTotals),
                      color: GraphStyle.lineColor,
                      barWidth: GraphStyle.lineWidth,
                      isCurved: false,
                      isStepLineChart: true,
                      lineChartStepData: const LineChartStepData(
                          stepDirection: GraphStyle.stepDirection),
                      belowBarData: BarAreaData(
                          show: true, color: GraphStyle.areaColor(context)),
                      dotData: GraphStyle.dotData,
                    ),
                    // Trend line
                    LineChartBarData(
                      spots: _calculateCategoryTrendLine(dateTotals, 0, maxY),
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
                              GraphStyleHelpers.calculateYAxisInterval(0, maxY);
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
                          final v = value.roundToDouble();
                          if (v != value) return const SizedBox.shrink();
                          final d = GraphStyleHelpers.dateFromEpochDays(v);

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
                                  child: Text(DateFormat('M/d').format(d),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                );
                              }
                            } else {
                              // For shorter time ranges, show labels on every Monday
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(DateFormat('M/d').format(d),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: GraphStyleHelpers.getBorderData(),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval:
                        GraphStyleHelpers.calculateYAxisInterval(0, maxY),
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: (v % 10 == 0)
                          ? Colors.grey.shade500
                          : Colors.grey.shade700,
                      strokeWidth: (v % 10 == 0) ? 1.5 : 1,
                    ),
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    checkToShowVerticalLine: (v) => v.roundToDouble() % 1 == 0,
                    getDrawingVerticalLine: (v) {
                      final d = GraphStyleHelpers.dateFromEpochDays(v);
                      final isMonday = d.weekday == DateTime.monday;
                      return FlLine(
                        color: isMonday
                            ? Colors.grey.shade500
                            : Colors.grey.shade700,
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
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final d = GraphStyleHelpers.dateFromEpochDays(
                            s.x.floorToDouble());
                        return LineTooltipItem(
                          '${DateFormat('M/d').format(d)}\n',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          children: [
                            const TextSpan(text: ''),
                            TextSpan(
                              text: s.y.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildCategorySpots(
      List<DateTime> sortedDates, Map<DateTime, double> dateTotals) {
    final spots = <FlSpot>[];
    for (final d in sortedDates) {
      final y = dateTotals[d] ?? 0;
      spots.add(FlSpot(GraphStyleHelpers.epochDays(d), y));
    }
    return spots;
  }

  /// Calculate trend line points for category data using linear regression
  /// The trend line only spans actual data points, not the full time range
  List<FlSpot> _calculateCategoryTrendLine(
      Map<DateTime, double> dateTotals, double minY, double maxY) {
    // Collect values for dates with actual data (non-zero values)
    final dataPoints = <Point>[];
    
    // Get sorted dates with data
    final sortedDates = dateTotals.keys.toList()..sort();
    for (final d in sortedDates) {
      final value = dateTotals[d] ?? 0;
      // Only include points with actual data (non-zero values) for trend calculation
      // This ensures the trend line only spans dates where there's actual activity
      if (value > 0) {
        dataPoints.add(Point(GraphStyleHelpers.epochDays(d), value));
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
}
