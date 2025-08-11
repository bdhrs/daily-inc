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
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _log.info('initState called for item: ${widget.dailyThing.name}');
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LineChart(
          LineChartData(
            minX: _epochDays(_getAllDatesFromStartToToday().first)
                .floorToDouble(),
            maxX:
                _epochDays(_getAllDatesFromStartToToday().last).ceilToDouble(),
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
                    // Render labels only on Mondays as M/d.
                    final v = value.roundToDouble();
                    if (v != value) return const SizedBox.shrink();
                    final d = _dateFromEpochDays(v);
                    if (d.weekday == DateTime.monday) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('M/d').format(d),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
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
    final dates = _getAllDatesFromStartToToday();
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

    final earliestDate =
        firstHistoryDate.isBefore(startDate) ? firstHistoryDate : startDate;

    return _generateDateRange(earliestDate, todayDate);
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
