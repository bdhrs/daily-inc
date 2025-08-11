import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
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

class _CategoryGraphViewState extends State<CategoryGraphView> {
  final _log = Logger('CategoryGraphView');

  final Map<String, Map<DateTime, double>> _categoryData = {};

  @override
  void initState() {
    super.initState();
    _log.info('initState called for category graph view');
    _processCategoryData();
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

      DateTime? minDate;
      DateTime? maxDate;
      for (final thing in items) {
        final start = DateTime(
            thing.startDate.year, thing.startDate.month, thing.startDate.day);
        if (minDate == null || start.isBefore(minDate)) minDate = start;
        for (final historyEntry in thing.history) {
          final date = DateTime(historyEntry.date.year, historyEntry.date.month,
              historyEntry.date.day);
          if (minDate == null || date.isBefore(minDate)) minDate = date;
          if (maxDate == null || date.isAfter(maxDate)) maxDate = date;
        }
      }

      if (minDate == null || maxDate == null) {
        _categoryData[category] = {};
        continue;
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final endDate = maxDate.isAfter(todayDate) ? maxDate : todayDate;

      final dateTotals = <DateTime, double>{};
      for (DateTime d = minDate;
          !d.isAfter(endDate);
          d = DateTime(d.year, d.month, d.day + 1)) {
        double total = 0;
        for (final thing in items) {
          final sameDayEntries = thing.history.where((e) {
            final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
            return entryDate == d;
          });
          for (final e in sameDayEntries) {
            if (thing.itemType == ItemType.check) {
              if (e.doneToday) total += 1.0;
            } else {
              if (e.actualValue != null) total += e.actualValue!;
            }
          }
        }
        dateTotals[d] = total;
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
                          final isMonday = d.weekday == DateTime.monday;
                          if (isMonday) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(DateFormat('M/d').format(d),
                                  style: Theme.of(context).textTheme.bodySmall),
                            );
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
}
