import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/graph_view.dart';

class DailyThingItem extends StatelessWidget {
  final DailyThing item;
  final DataManager dataManager;
  final Function(DailyThing) onEdit;
  final Function(DailyThing) onDelete;
  final Function(DailyThing) onDuplicate;
  final Function(DailyThing) showFullscreenTimer;
  final Function(DailyThing) showRepsInputDialog;
  final Function checkAndShowCompletionSnackbar;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;
  final bool allTasksCompleted;

  const DailyThingItem({
    super.key,
    required this.item,
    required this.dataManager,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.showFullscreenTimer,
    required this.showRepsInputDialog,
    required this.checkAndShowCompletionSnackbar,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.allTasksCompleted,
  });

  String _formatValue(double value, ItemType itemType) {
    if (itemType == ItemType.minutes) {
      if (value.truncateToDouble() == value) {
        return '${value.toInt()}m';
      } else {
        final minutes = value.truncate();
        final seconds = ((value - minutes) * 60).round();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } else if (itemType == ItemType.reps) {
      return '${value.round()}x';
    } else {
      return value >= 1 ? '✅' : '❌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompletedToday = item.isDoneToday;

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 0.5, 10, 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          trailing: const SizedBox.shrink(),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          collapsedShape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCompletedToday ? Icons.check : Icons.close,
                    color: isCompletedToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  if (item.icon != null)
                    Text(
                      item.icon!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: allTasksCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  if (item.itemType == ItemType.minutes) {
                    if (isCompletedToday) {
                      onExpansionChanged(!isExpanded);
                    } else {
                      showFullscreenTimer(item);
                    }
                  } else if (item.itemType == ItemType.check) {
                    final today = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );
                    final newValue = item.todayValue == 1.0 ? 0.0 : 1.0;
                    final newEntry = HistoryEntry(
                      date: today,
                      targetValue: newValue,
                      doneToday: item.isDone(newValue),
                    );
                    HistoryEntry? existingEntry = item.history.firstWhere(
                      (entry) =>
                          entry.date.year == today.year &&
                          entry.date.month == today.month &&
                          entry.date.day == today.day,
                      orElse: () => HistoryEntry(
                          date: DateTime(0), targetValue: 0, doneToday: false),
                    );

                    if (existingEntry.date.year != 0) {
                      final index = item.history.indexOf(existingEntry);
                      item.history[index] = newEntry;
                    } else {
                      item.history.add(newEntry);
                    }
                    await dataManager.updateDailyThing(item);
                    checkAndShowCompletionSnackbar();
                  } else if (item.itemType == ItemType.reps) {
                    showRepsInputDialog(item);
                  }
                },
                child: SizedBox(
                  width: 80.0,
                  height: 34.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: item.isDoneToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: item.itemType == ItemType.check
                        ? Icon(
                            item.todayValue == 1.0 ? Icons.check : Icons.close,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 16.0,
                          )
                        : Text(
                            _formatValue(
                                item.actualTodayValue ?? item.todayValue,
                                item.itemType),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14),
                          ),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.itemType != ItemType.check)
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Row(
                      children: [
                        Text(_formatValue(item.startValue, item.itemType)),
                        const Icon(Icons.trending_flat),
                        Text(_formatValue(item.endValue, item.itemType)),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 48.0), // Match height of other rows
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_graph),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GraphView(dailyThing: item),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onEdit(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () => onDuplicate(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
