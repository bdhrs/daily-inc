import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
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
  double _minX = 0;
  double _maxX = 0;
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

      if (widget.dailyThing.history.isNotEmpty) {
        var sortedHistory = List.from(widget.dailyThing.history)
          ..sort((a, b) => a.date.compareTo(b.date));
        _minX = sortedHistory.first.date
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch
            .toDouble();
        _maxX = sortedHistory.last.date
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch
            .toDouble();
      } else {
        // Default range if no history
        _minX = DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch
            .toDouble();
        _maxX = DateTime.now()
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch
            .toDouble();
      }
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

      // Calculate X-axis range based on startDate, duration, and history
      DateTime earliestDate = widget.dailyThing.startDate;
      DateTime latestDate = widget.dailyThing.startDate
          .add(Duration(days: widget.dailyThing.duration));

      if (widget.dailyThing.history.isNotEmpty) {
        var sortedHistory = List.from(widget.dailyThing.history);
        sortedHistory.sort((a, b) => a.date.compareTo(b.date));
        final firstHistoryDate = sortedHistory.first.date;
        final lastHistoryDate = sortedHistory.last.date;

        if (firstHistoryDate.isBefore(earliestDate)) {
          earliestDate = firstHistoryDate;
        }
        if (lastHistoryDate.isAfter(latestDate)) {
          latestDate = lastHistoryDate;
        }
      }

      _minX = earliestDate.millisecondsSinceEpoch.toDouble();
      _maxX = latestDate
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch
          .toDouble();
    }
    _log.info('Ranges calculated: Y($_minY, $_maxY), X($_minX, $_maxX)');
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
        child: LineChart(
          LineChartData(
            minY: _minY,
            maxY: _maxY,
            minX: _minX,
            maxX: _maxX,
            lineBarsData: [
              // Projected line (only if not a 'check' item)

              // Actual "bars"
              ..._getActualBarsAsLines(context),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60, // Further increased reserved size
                  interval: (_maxY - _minY) / 5, // Aim for 5 labels
                  getTitlesWidget: (value, meta) {
                    if (value % meta.appliedInterval == 0) {
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
                  padding:
                      const EdgeInsets.only(bottom: 16.0), // Increased padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dailyThing.itemType.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Value (${_getUnitForType(widget.dailyThing.itemType)})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50, // Further increased reserved size
                  interval: 1000 * 60 * 60 * 24 * 2, // Minimum 2-day interval
                  getTitlesWidget: (value, meta) {
                    // Don't show labels at the very edge of the graph
                    if (value == meta.min || value == meta.max) {
                      return const Text('');
                    }
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());

                    // Let the library handle the interval, just format the visible ones.
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('M/d').format(date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
                axisNameWidget: Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0), // Increased padding
                  child: Text(
                    'Date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            gridData: const FlGridData(show: true),
            lineTouchData: const LineTouchData(enabled: false),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _getActualBarsAsLines(BuildContext context) {
    final List<LineChartBarData> lines = [];
    if (widget.dailyThing.itemType == ItemType.check) {
      for (var entry in widget.dailyThing.history) {
        if (entry.doneToday) {
          final xValue = entry.date.millisecondsSinceEpoch.toDouble();
          lines.add(LineChartBarData(
            spots: [FlSpot(xValue, 0), FlSpot(xValue, 1)],
            barWidth: 8,
            color: Colors.green,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
          ));
        }
      }
    } else {
      final historyByDate = {
        for (var entry in widget.dailyThing.history)
          if (entry.actualValue != null)
            entry.date.millisecondsSinceEpoch.toDouble(): entry.actualValue!
      };

      for (var entry in widget.dailyThing.history) {
        final xValue = entry.date.millisecondsSinceEpoch.toDouble();
        final value = historyByDate[xValue];
        if (value != null) {
          lines.add(LineChartBarData(
            spots: [FlSpot(xValue, 0), FlSpot(xValue, value)],
            barWidth: 8,
            color: Colors.blue,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
          ));
        }
      }
    }
    return lines;
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
