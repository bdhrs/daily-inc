import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _log.info('initState called for item: ${widget.dailyThing.name}');
    _calculateRanges();
  }

  void _calculateRanges() {
    _log.info('Calculating graph ranges...');
    if (widget.dailyThing.itemType == ItemType.check) {
      _minY = 0;
      _maxY = 1.2; // A little padding above the "check" mark
    } else {
      final startValue = widget.dailyThing.startValue;
      final endValue = widget.dailyThing.endValue;

      final minValue = min(startValue, endValue);
      final maxValue = max(startValue, endValue);

      final yPadding = (maxValue - minValue) * 0.1;
      _minY = 0;
      _maxY = maxValue + yPadding;

      // If start and end are the same, create a sensible range
      if (startValue == endValue) {
        if (startValue == 0) {
          _minY = 0;
          _maxY = 10;
        } else {
          _minY = max(0, startValue - 5);
          _maxY = startValue + 5;
        }
      }
    }
    _log.info('Ranges calculated: Y($_minY, $_maxY)');
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dailyThing.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: _getBarGroups(),
            titlesData: GraphStyleHelpers.getTitlesData(
              context: context,
              minY: _minY,
              maxY: _maxY,
              yAxisName:
                  'Value (${_getUnitForType(widget.dailyThing.itemType)})',
              sortedDates: _getAllDatesFromStartToToday(),
            ),
            borderData: GraphStyleHelpers.getBorderData(),
            gridData: GraphStyleHelpers.getGridData(
              sortedDates: _getAllDatesFromStartToToday(),
              minY: _minY,
              maxY: _maxY,
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final allDates = _getAllDatesFromStartToToday();
                  final date = allDates[group.x];
                  return BarTooltipItem(
                    '${DateFormat('M/d').format(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: rod.toY.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final List<BarChartGroupData> barGroups = [];
    
    // Get all dates from start to today
    final allDates = _getAllDatesFromStartToToday();
    final historyMap = <DateTime, dynamic>{};
    
    // Create a map of dates to history entries for quick lookup
    for (final entry in widget.dailyThing.history) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      historyMap[dateKey] = entry;
    }

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      final entry = historyMap[date];
      double yValue = 0;

      if (entry != null) {
        if (widget.dailyThing.itemType == ItemType.check) {
          if (entry.doneToday) {
            yValue = 1;
          }
        } else {
          if (entry.actualValue != null) {
            yValue = entry.actualValue!;
          }
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              color: widget.dailyThing.itemType == ItemType.check
                  ? Colors.green
                  : Colors.blue,
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  List<DateTime> _getAllDatesFromStartToToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (widget.dailyThing.history.isEmpty) {
      final startDate = DateTime(widget.dailyThing.startDate.year, 
          widget.dailyThing.startDate.month, widget.dailyThing.startDate.day);
      return _generateDateRange(startDate, todayDate);
    }
    
    final sortedHistory = widget.dailyThing.history.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final firstHistoryDate = DateTime(sortedHistory.first.date.year,
        sortedHistory.first.date.month, sortedHistory.first.date.day);
    final startDate = DateTime(widget.dailyThing.startDate.year, 
        widget.dailyThing.startDate.month, widget.dailyThing.startDate.day);
    
    final earliestDate = firstHistoryDate.isBefore(startDate) ? firstHistoryDate : startDate;
    
    return _generateDateRange(earliestDate, todayDate);
  }

  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
      dates.add(d);
    }
    return dates;
  }

}


String _getUnitForType(ItemType type) {
  switch (type) {
    case ItemType.minutes:
      return 'minutes';
    case ItemType.reps:
      return 'reps';
    case ItemType.check:
      return '';
  }
}
