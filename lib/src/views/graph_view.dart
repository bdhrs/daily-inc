import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
        child: LineChart(
          LineChartData(
            minY: _minY,
            maxY: _maxY,
            minX: -2,
            maxX: widget.dailyThing.duration.toDouble() + 2,
            lineBarsData: [
              // Projected line
              LineChartBarData(
                spots: _getTargetSpots(),
                isCurved: false,
                color: Colors.grey,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              // Actual "bars"
              ..._getActualBarsAsLines(context),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60, // Further increased reserved size
                  getTitlesWidget: (value, meta) {
                    // Show labels for all integer values within the range
                    if (value == value.toInt().toDouble()) {
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
                  getTitlesWidget: (value, meta) {
                    // Show labels for all integer values within the range
                    if (value >= 0 &&
                        value <= widget.dailyThing.duration &&
                        value == value.toInt().toDouble()) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
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
                      const EdgeInsets.only(top: 16.0), // Increased padding
                  child: Text(
                    'Days',
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
    final historyByDay = {
      for (var entry in widget.dailyThing.history)
        entry.date.difference(widget.dailyThing.startDate).inDays:
            entry.targetValue
    };

    for (int i = 0; i <= widget.dailyThing.duration; i++) {
      final value = historyByDay[i];
      if (value != null) {
        lines.add(LineChartBarData(
          spots: [FlSpot(i.toDouble(), 0), FlSpot(i.toDouble(), value)],
          barWidth: 8,
          color: Colors.blue,
          isStrokeCapRound: false,
          dotData: const FlDotData(show: false),
        ));
      }
    }
    return lines;
  }

  List<FlSpot> _getTargetSpots() {
    final List<FlSpot> spots = [];
    for (int i = 0; i <= widget.dailyThing.duration; i++) {
      final value =
          widget.dailyThing.startValue + (widget.dailyThing.increment * i);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
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
