import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
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
    final targetSpots = _getTargetSpots();
    final actualBars = _getActualBars();

    final allYValues = [
      ...targetSpots.map((spot) => spot.y),
      ...actualBars.map((bar) => bar.barRods.first.toY),
    ];

    final allXValues = [
      ...targetSpots.map((spot) => spot.x),
      ...actualBars.map((bar) => bar.x.toDouble()),
    ];

    if (allYValues.isNotEmpty) {
      _minY = allYValues.reduce(min);
      _maxY = allYValues.reduce(max);
    } else {
      _minY = widget.dailyThing.startValue;
      _maxY = widget.dailyThing.endValue;
    }

    if (allXValues.isNotEmpty) {
      _minX = allXValues.reduce(min);
      _maxX = allXValues.reduce(max);
    } else {
      _minX = 0;
      _maxX = widget.dailyThing.duration.toDouble();
    }

    final yPadding = (_maxY - _minY) * 0.1;
    _minY -= yPadding;
    _maxY += yPadding;

    final xPadding = (_maxX - _minX) * 0.05;
    _minX -= xPadding;
    _maxX += xPadding;
    _log.info('Ranges calculated: X($_minX, $_maxX), Y($_minY, $_maxY)');
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dailyThing.name),
      ),
      body: Padding(
        padding: const EdgeInsets.only(right: 18, top: 8, bottom: 12, left: 8),
        child: Stack(
          children: [
            LineChart(
              LineChartData(
                minY: _minY,
                maxY: _maxY,
                minX: _minX,
                maxX: _maxX,
                lineBarsData: [
                  LineChartBarData(
                    spots: _getTargetSpots(),
                    isCurved: false,
                    color: Colors.grey,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: _getInterval(),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                gridData: const FlGridData(show: true),
              ),
            ),
            BarChart(
              BarChartData(
                minY: _minY,
                maxY: _maxY,
                barGroups: _getActualBars(),
                alignment: BarChartAlignment.spaceEvenly,
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  enabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getInterval() {
    final double range = (_maxY - _minY).abs();
    if (range <= 10) {
      return 1;
    } else if (range <= 20) {
      return 2;
    } else if (range <= 50) {
      return 5;
    } else if (range <= 100) {
      return 10;
    } else {
      return 20;
    }
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

  List<BarChartGroupData> _getActualBars() {
    final List<BarChartGroupData> bars = [];
    final historyByDay = {
      for (var entry in widget.dailyThing.history)
        entry.date.difference(widget.dailyThing.startDate).inDays: entry.value
    };

    for (int i = 0; i <= widget.dailyThing.duration; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: historyByDay[i] ?? 0,
              color: historyByDay.containsKey(i)
                  ? Colors.blue
                  : Colors.transparent,
              width: 8,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    return bars;
  }
}
