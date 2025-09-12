import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:daily_inc/src/views/widgets/graph_mixin.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GraphView extends StatefulWidget {
  final DailyThing dailyThing;
  const GraphView({super.key, required this.dailyThing});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> with BaseGraphStateMixin<GraphView> {
  double _minY = 0;
  double _maxY = 0;
  final _log = Logger('GraphView');
  List<FlSpot> _spots = [];
  
  @override
  String get prefsKey => 'graph_time_range_preference';
  
  @override
  double get minY => _minY;
  
  @override
  double get maxY => _maxY;
  
  @override
  List<FlSpot> get spots => _spots;

  @override
  void initState() {
    super.initState();
    _log.info('initState called for item: ${widget.dailyThing.name}');
    _loadTimeRangePreference();
  }

  Future<void> _loadTimeRangePreference() async {
    await loadTimeRangePreference();
    // Now that we have the time range preference, build the spots
    _spots = _buildSpots();
    _calculateRanges();
    setState(() {}); // Rebuild with loaded preference
  }

  void _onTimeRangeChanged() {
    // Rebuild spots with new time range
    _spots = _buildSpots();
    _calculateRanges();
    setState(() {});
  }

  void _calculateRanges() {
    _log.info('Calculating graph ranges...');
    if (widget.dailyThing.itemType == ItemType.check) {
      _minY = 0;
      _maxY = 1.2;
    } else if (widget.dailyThing.itemType == ItemType.trend) {
      // For trend items, allow negative values
      if (_spots.isEmpty) {
        _minY = -1;
        _maxY = 1;
      } else {
        final values = _spots.map((s) => s.y);
        final minValue = values.reduce(min);
        final maxValue = values.reduce(max);
        final range = maxValue - minValue;
        final padding = range * 0.1; // 10% padding

        _minY = minValue - padding;
        _maxY = maxValue + padding;
      }
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
          buildTimeRangeDropdown(_onTimeRangeChanged),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LineChart(
          LineChartData(
            minX: GraphStyleHelpers.epochDays(_getFilteredDates().first).floorToDouble(),
            maxX: GraphStyleHelpers.epochDays(_getFilteredDates().last).ceilToDouble(),
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
                spots: calculateTrendLine(_spots, _minY, _maxY),
                color: Colors.white,
                barWidth: 2.5,
                isCurved: true,
                curveSmoothness: 0.1,
                dashArray: [5, 5], // Dashed line pattern
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: buildAxisTitles(context, _minY, _maxY),
            borderData: GraphStyleHelpers.getBorderData(),
            gridData: buildGridData(_minY, _maxY),
            lineTouchData: LineTouchData(
              enabled: true,
              getTouchedSpotIndicator: (bar, spots) => spots
                  .map((s) => const TouchedSpotIndicatorData(
                        FlLine(color: Colors.transparent, strokeWidth: 0),
                        FlDotData(show: false),
                      ))
                  .toList(),
              handleBuiltInTouches: true,
              touchTooltipData: buildTouchTooltipData(_spots, widget.dailyThing.history, GraphStyleHelpers.dateFromEpochDays),
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

    // For trend items, calculate accumulated values
    if (widget.dailyThing.itemType == ItemType.trend) {
      return _buildTrendSpots(dates, historyMap);
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
      spots.add(FlSpot(GraphStyleHelpers.epochDays(d), y));
    }
    return spots;
  }

  /// Builds spots for trend items with accumulated values
  List<FlSpot> _buildTrendSpots(List<DateTime> dates, Map<DateTime, dynamic> historyMap) {
    final spots = <FlSpot>[];
    double accumulatedValue = 0.0;

    for (final date in dates) {
      final entry = historyMap[date];

      if (entry != null && entry.actualValue != null) {
        // Add today's trend to the accumulated value
        accumulatedValue += entry.actualValue!;
      }
      // If no entry for this date, keep the previous accumulated value

      spots.add(FlSpot(GraphStyleHelpers.epochDays(date), accumulatedValue));
    }

    return spots;
  }

  List<DateTime> _getFilteredDates() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // For "all" time range, use the first history entry date of this specific item
    if (selectedTimeRange == TimeRange.all &&
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
    final startDate = selectedTimeRange.getStartDate(todayDate);

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
}
