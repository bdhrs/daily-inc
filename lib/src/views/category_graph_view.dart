import 'dart:math';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
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
  
  // Map to store category data: category -> date -> total value
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
    
    // Group items by category
    final Map<String, List<DailyThing>> itemsByCategory = {};
    for (final thing in widget.dailyThings) {
      if (!itemsByCategory.containsKey(thing.category)) {
        itemsByCategory[thing.category] = [];
      }
      itemsByCategory[thing.category]!.add(thing);
    }
    
    // Process each category separately
    for (final entry in itemsByCategory.entries) {
      final category = entry.key;
      final items = entry.value;
      
      // Get all unique dates for this category
      final Set<DateTime> allDates = {};
      for (final thing in items) {
        for (final historyEntry in thing.history) {
          final date = DateTime(historyEntry.date.year, historyEntry.date.month, historyEntry.date.day);
          allDates.add(date);
        }
      }
      
      // Add today's date if not already present
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      allDates.add(todayDate);
      
      // Sort dates
      final sortedDates = allDates.toList()..sort();
      
      // Calculate totals for each date
      final dateTotals = <DateTime, double>{};
      for (final date in sortedDates) {
        double total = 0;
        
        for (final thing in items) {
          // Find the most relevant history entry for this date
          HistoryEntry? relevantEntry;
          
          // First try to find an exact match
          try {
            relevantEntry = thing.history.firstWhere((e) {
              final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
              return entryDate == date;
            });
          } catch (e) {
            // No exact match, find the most recent entry before this date
            final pastEntries = thing.history.where((e) {
              final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
              return entryDate.isBefore(date);
            }).toList();
            
            if (pastEntries.isNotEmpty) {
              pastEntries.sort((a, b) => b.date.compareTo(a.date));
              relevantEntry = pastEntries.first;
            } else {
              // No past entries, check for future entries
              final futureEntries = thing.history.where((e) {
                final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
                return entryDate.isAfter(date);
              }).toList();
              
              if (futureEntries.isNotEmpty) {
                futureEntries.sort((a, b) => a.date.compareTo(b.date));
                relevantEntry = futureEntries.first;
              }
            }
          }
          
          // Calculate value based on item type
          if (relevantEntry != null) {
            double value = 0;
            if (thing.itemType == ItemType.check) {
              value = relevantEntry.doneToday ? 1.0 : 0.0;
            } else {
              // For reps and minutes, use actual value if available, otherwise target value
              value = relevantEntry.actualValue ?? relevantEntry.targetValue;
            }
            total += value;
          } else if (thing.history.isNotEmpty) {
            // If no relevant entry found but item has history, use the most recent entry
            thing.history.sort((a, b) => b.date.compareTo(a.date));
            final latestEntry = thing.history.first;
            if (thing.itemType == ItemType.check) {
              total += latestEntry.doneToday ? 1.0 : 0.0;
            } else {
              total += latestEntry.actualValue ?? latestEntry.targetValue;
            }
          }
        }
        
        dateTotals[date] = total;
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
                
                // Skip showing graphs for the category "None"
                if (category == 'None') {
                  return const SizedBox.shrink();
                }
                
                return _buildCategoryGraph(category, dateTotals, context);
              },
            ),
    );
  }
  
  Widget _buildCategoryGraph(String category, Map<DateTime, double> dateTotals, BuildContext context) {
    // Calculate ranges
    double minY = 0;
    double maxY = 0;
    
    if (dateTotals.isNotEmpty) {
      // Y range
      final values = dateTotals.values.toList();
      minY = values.reduce(min);
      maxY = values.reduce(max);
      
      // Add padding
      final padding = (maxY - minY) * 0.1;
      minY = max(0, minY - padding);
      maxY = maxY + padding;
      
      // If all values are the same, create a sensible range
      if (minY == maxY) {
        if (minY == 0) {
          maxY = 10;
        } else {
          minY = max(0, minY - 5);
          maxY = maxY + 5;
        }
      }
    } else {
      // Default range if no data
      maxY = 10;
    }
    
    // Create bars for the bar chart
    final List<BarChartGroupData> barGroups = [];
    final sortedDates = dateTotals.keys.toList()..sort();
    
    // Determine which dates to show labels for (every 3rd date to avoid overcrowding)
    final Set<DateTime> labelDates = {};
    if (sortedDates.length > 7) {
      for (int i = 0; i < sortedDates.length; i += 3) {
        labelDates.add(sortedDates[i]);
      }
      // Always include the last date
      labelDates.add(sortedDates.last);
    } else {
      labelDates.addAll(sortedDates);
    }
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final yValue = dateTotals[date]!;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 5, // Show about 5 labels on Y axis
                        getTitlesWidget: (value, meta) {
                          // Only show labels at regular intervals
                          if (value % meta.appliedInterval == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        // Show labels only for selected dates to avoid overcrowding
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            final date = sortedDates[index];
                            // Only show label if this date should have a label
                            if (labelDates.contains(date)) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  DateFormat('M/d').format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  gridData: const FlGridData(show: true),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = sortedDates[group.x];
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
          ],
        ),
      ),
    );
  }
}