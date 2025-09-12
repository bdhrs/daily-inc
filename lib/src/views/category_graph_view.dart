import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:daily_inc/src/views/widgets/graph_mixin.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

class CategoryGraphView extends StatefulWidget {
  final List<DailyThing> dailyThings;
  const CategoryGraphView({super.key, required this.dailyThings});

  @override
  State<CategoryGraphView> createState() => _CategoryGraphViewState();
}

class _CategoryGraphViewState extends State<CategoryGraphView>
    with BaseGraphStateMixin {
  final _log = Logger('CategoryGraphView');

  final Map<String, Map<DateTime, double>> _categoryData = {};

  @override
  String get prefsKey => 'category_graph_time_range_preference';

  // These are not used directly in this view, but required by the mixin
  @override
  double get minY => 0;

  @override
  double get maxY => 0;

  @override
  List<FlSpot> get spots => [];

  @override
  void initState() {
    super.initState();
    _log.info('initState called for category graph view');
    _loadTimeRangePreference();
  }

  Future<void> _loadTimeRangePreference() async {
    await loadTimeRangePreference();
    // Now that we have the time range preference, process the category data
    _processCategoryData();
    setState(() {}); // Rebuild with loaded preference
  }

  void _onTimeRangeChanged() {
    // Re-process category data with new time range
    _processCategoryData();
    setState(() {});
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
      if (selectedTimeRange == TimeRange.all) {
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
        startDate = selectedTimeRange.getStartDate(todayDate);
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
      if (selectedTimeRange != TimeRange.all) {
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
        if ((selectedTimeRange == TimeRange.all &&
                currentDate.isBefore(startDate)) ||
            (selectedTimeRange != TimeRange.all &&
                currentDate.isBefore(startDate))) {
          currentDate = DateTime(
              currentDate.year, currentDate.month, currentDate.day + 1);
          continue;
        }

        double total = 0;
        for (final thing in items) {
          if (thing.itemType == ItemType.trend) {
            // For trend items, use accumulated value
            final accumulatedValue =
                _getTrendAccumulatedValue(thing, currentDate);
            total += accumulatedValue;
          } else {
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
          buildTimeRangeDropdown(_onTimeRangeChanged),
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
    double minY = 0;
    double maxY = 0;
    if (dateTotals.isNotEmpty) {
      final values = dateTotals.values;
      final minValue = values.reduce(min);
      final maxValue = values.reduce(max);

      // Check if this category contains trend items (which can have negative accumulated values)
      final hasTrendItems = _categoryHasTrendItems(category);
      if (hasTrendItems && minValue < 0) {
        minY = minValue * 1.1; // Allow negative values with padding
        maxY = maxValue == 0 ? 1 : maxValue * 1.1;
      } else {
        minY = 0;
        maxY = maxValue == 0 ? 1 : maxValue * 1.1;
      }
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
                  minY: minY,
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
                      spots:
                          _calculateCategoryTrendLine(dateTotals, minY, maxY),
                      color: Colors.white,
                      barWidth: 2.5,
                      isCurved: true,
                      curveSmoothness: 0.1,
                      dashArray: [5, 5], // Dashed line pattern
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: buildAxisTitles(context, minY, maxY),
                  borderData: GraphStyleHelpers.getBorderData(),
                  gridData: buildGridData(minY, maxY),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    getTouchedSpotIndicator: (bar, spots) => spots
                        .map((s) => const TouchedSpotIndicatorData(
                              FlLine(color: Colors.transparent, strokeWidth: 0),
                              FlDotData(show: false),
                            ))
                        .toList(),
                    touchTooltipData:
                        _buildCategoryTouchTooltipData(dateTotals),
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

  /// Calculates the accumulated value for a trend item up to the specified date
  double _getTrendAccumulatedValue(DailyThing thing, DateTime targetDate) {
    // Sort history entries by date
    final sortedHistory = thing.history.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double accumulatedValue = 0.0;

    for (final entry in sortedHistory) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);

      // Stop if we've reached beyond the target date
      if (entryDate.isAfter(targetDate)) break;

      if (entry.actualValue != null) {
        accumulatedValue += entry.actualValue!;
      }
    }

    return accumulatedValue;
  }

  /// Checks if a category contains any trend items
  bool _categoryHasTrendItems(String category) {
    final itemsByCategory = <String, List<DailyThing>>{};
    for (final thing in widget.dailyThings) {
      if (thing.category.isNotEmpty) {
        itemsByCategory.putIfAbsent(thing.category, () => []).add(thing);
      }
    }

    final items = itemsByCategory[category] ?? [];
    return items.any((thing) => thing.itemType == ItemType.trend);
  }

  /// Builds the touch tooltip data for the category graph.
  LineTouchTooltipData _buildCategoryTouchTooltipData(
      Map<DateTime, double> dateTotals) {
    return LineTouchTooltipData(
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((s) {
          if (s.barIndex == 1) {
            // Trend line
            return null;
          }
          final d = GraphStyleHelpers.dateFromEpochDays(s.x.floorToDouble());
          final value = s.y.toStringAsFixed(1);

          return LineTooltipItem(
            '${DateFormat('M/d').format(d)}\n',
            const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          );
        }).toList();
      },
    );
  }
}
