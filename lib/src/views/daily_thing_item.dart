import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/graph_view.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class DailyThingItem extends StatefulWidget {
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
  final VoidCallback? onItemChanged;

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
    this.onItemChanged,
  });

  @override
  State<DailyThingItem> createState() => _DailyThingItemState();
}

class _DailyThingItemState extends State<DailyThingItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(DailyThingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
    }
  }

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

  bool _hasIncompleteProgress(DailyThing item) {
    if (item.itemType != ItemType.minutes) return false;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayEntry = item.history.firstWhere(
      (entry) =>
          entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day,
      orElse: () =>
          HistoryEntry(date: DateTime(0), targetValue: 0, doneToday: false),
    );

    return todayEntry.date.year != 0 &&
        (todayEntry.actualValue ?? 0) > 0 &&
        !todayEntry.doneToday;
  }

  @override
  Widget build(BuildContext context) {
    // For CHECK type, visual state should not depend on past history; if due, it's initially not done and takes one tap to mark done.
    // We still use completedForToday for MINUTES/REPS logic elsewhere.
    final isCompletedToday = widget.item.itemType == ItemType.check
        ? widget.item.hasBeenDoneLiterallyToday
        : widget.item.completedForToday;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: ExpansionTile(
          // Include today's completion state in the key so Flutter doesn't reuse a stale widget after toggle
          key: ValueKey(
              '${widget.item.id}_${widget.isExpanded}_${widget.item.completedForToday}'),
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
            widget.onExpansionChanged(expanded);
          },
          trailing: const SizedBox.shrink(),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          collapsedShape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // Left section
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isCompletedToday
                            ? Icons.check
                            : (_hasIncompleteProgress(widget.item)
                                ? Icons.brightness_2_outlined
                                : Icons.close),
                        color: isCompletedToday
                            ? Theme.of(context).colorScheme.primary
                            : _hasIncompleteProgress(widget.item)
                                ? ColorPalette.partialYellow
                                : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      if (widget.item.icon != null)
                        Text(
                          widget.item.icon!,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.allTasksCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.allTasksCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right-aligned timer chip
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (widget.item.itemType == ItemType.minutes) {
                          if (isCompletedToday) {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                            widget.onExpansionChanged(_isExpanded);
                          } else {
                            widget.showFullscreenTimer(widget.item);
                          }
                        } else if (widget.item.itemType == ItemType.check) {
                          // Determine current completion based on history.doneToday rather than todayValue to avoid stale reads
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          HistoryEntry? existingEntry =
                              widget.item.history.firstWhere(
                            (entry) =>
                                entry.date.year == today.year &&
                                entry.date.month == today.month &&
                                entry.date.day == today.day,
                            orElse: () => HistoryEntry(
                                date: DateTime(0),
                                targetValue: 0,
                                doneToday: false),
                          );

                          final wasDone = existingEntry.date.year != 0
                              ? existingEntry.doneToday
                              : false;
                          final newDone = !wasDone;
                          final newValue = newDone ? 1.0 : 0.0;

                          final newEntry = HistoryEntry(
                            date: today,
                            targetValue: newValue,
                            doneToday: newDone,
                          );

                          if (existingEntry.date.year != 0) {
                            final index =
                                widget.item.history.indexOf(existingEntry);
                            widget.item.history[index] = newEntry;
                          } else {
                            widget.item.history.add(newEntry);
                          }

                          // Immediately rebuild this tile so UI reflects change on first tap
                          if (mounted) {
                            setState(() {});
                          }

                          // Persist and notify parent; do not block UI feedback on await
                          await widget.dataManager
                              .updateDailyThing(widget.item);
                          widget.onItemChanged?.call();
                          widget.checkAndShowCompletionSnackbar();
                        } else if (widget.item.itemType == ItemType.reps) {
                          widget.showRepsInputDialog(widget.item);
                        }
                      },
                      child: SizedBox(
                        width: 72.0,
                        height: 34.0,
                        child: Container(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: widget.item.completedForToday
                                ? Theme.of(context).colorScheme.primary
                                : _hasIncompleteProgress(widget.item)
                                    ? ColorPalette.partialYellow
                                    : Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.transparent,
                                width: 0), // ensure no extra visual inset
                          ),
                          alignment: Alignment.center,
                          child: widget.item.itemType == ItemType.check
                              ? Icon(
                                  widget.item.completedForToday
                                      ? Icons.check
                                      : (widget.item.hasBeenDoneLiterallyToday
                                          ? Icons.brightness_2_outlined
                                          : Icons.close),
                                  color: _hasIncompleteProgress(widget.item)
                                      ? ColorPalette.onPartialYellow
                                      : Theme.of(context).colorScheme.onPrimary,
                                  size: 16.0,
                                )
                              : Text(
                                  _formatValue(widget.item.displayValue,
                                      widget.item.itemType),
                                  style: TextStyle(
                                      color: _hasIncompleteProgress(widget.item)
                                          ? ColorPalette.onPartialYellow
                                          : Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                      fontSize: 14),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 0),
                  ],
                )
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Layout rule:
                  // - CHECK items: category on line 2; NO third line.
                  // - Non-CHECK items: metrics row on line 2; category on line 3.

                  // Line 2 for CHECK: category + right-side icon cluster
                  if (widget.item.itemType == ItemType.check) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: category (if any)
                        Expanded(
                          child: (widget.item.category).isNotEmpty
                              ? Text(
                                  widget.item.category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                )
                              : const SizedBox.shrink(),
                        ),
                        // Right: same icon cluster used on the non-CHECK second line
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'see daily stats',
                              icon: const Icon(Icons.auto_graph),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GraphView(dailyThing: widget.item),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: widget.item.isPaused
                                  ? 'resume increments'
                                  : 'pause increments',
                              icon: Icon(widget.item.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () async {
                                final updated = DailyThing(
                                  id: widget.item.id,
                                  icon: widget.item.icon,
                                  name: widget.item.name,
                                  itemType: widget.item.itemType,
                                  startDate: widget.item.startDate,
                                  startValue: widget.item.startValue,
                                  duration: widget.item.duration,
                                  endValue: widget.item.endValue,
                                  history: widget.item.history,
                                  nagTime: widget.item.nagTime,
                                  nagMessage: widget.item.nagMessage,
                                  frequencyInDays: widget.item.frequencyInDays,
                                  category: widget.item.category,
                                  isPaused: !widget.item.isPaused,
                                );
                                await widget.dataManager
                                    .updateDailyThing(updated);
                                if (mounted) {
                                  setState(() {});
                                }
                                widget.onItemChanged?.call();
                              },
                            ),
                            IconButton(
                              tooltip: 'edit the item',
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onEdit(widget.item),
                            ),
                            IconButton(
                              tooltip: 'duplicate the item',
                              icon: const Icon(Icons.content_copy),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onDuplicate(widget.item),
                            ),
                            IconButton(
                              tooltip: 'delete the item',
                              icon: const Icon(Icons.delete),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onDelete(widget.item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    // Line 2 for non-CHECK: start→end, increment, and right icon cluster
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left group: start→end and increment on the second line
                        Expanded(
                          child: Row(
                            children: [
                              // start → end
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatValue(widget.item.startValue,
                                          widget.item.itemType),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.trending_flat, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatValue(widget.item.endValue,
                                          widget.item.itemType),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ],
                                ),
                              ),
                              // increment (non-check only)
                              const SizedBox(width: 8),
                              Text(
                                (() {
                                  final inc = widget.item.increment;
                                  final sign = inc < 0 ? '-' : '+';
                                  final absVal = inc.abs();
                                  String numStr = absVal.toStringAsFixed(2);
                                  numStr =
                                      numStr.replaceFirst(RegExp(r'\.00$'), '');
                                  numStr =
                                      numStr.replaceFirst(RegExp(r'0$'), '');
                                  return '$sign$numStr';
                                })(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                        // Right cluster: icon buttons stay on line 2
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'see daily stats',
                              icon: const Icon(Icons.auto_graph),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GraphView(dailyThing: widget.item),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: widget.item.isPaused
                                  ? 'resume increments'
                                  : 'pause increments',
                              icon: Icon(widget.item.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () async {
                                final updated = DailyThing(
                                  id: widget.item.id,
                                  icon: widget.item.icon,
                                  name: widget.item.name,
                                  itemType: widget.item.itemType,
                                  startDate: widget.item.startDate,
                                  startValue: widget.item.startValue,
                                  duration: widget.item.duration,
                                  endValue: widget.item.endValue,
                                  history: widget.item.history,
                                  nagTime: widget.item.nagTime,
                                  nagMessage: widget.item.nagMessage,
                                  frequencyInDays: widget.item.frequencyInDays,
                                  category: widget.item.category,
                                  isPaused: !widget.item.isPaused,
                                );
                                await widget.dataManager
                                    .updateDailyThing(updated);
                                if (mounted) {
                                  setState(() {});
                                }
                                widget.onItemChanged?.call();
                              },
                            ),
                            IconButton(
                              tooltip: 'edit the item',
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onEdit(widget.item),
                            ),
                            IconButton(
                              tooltip: 'duplicate the item',
                              icon: const Icon(Icons.content_copy),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onDuplicate(widget.item),
                            ),
                            IconButton(
                              tooltip: 'delete the item',
                              icon: const Icon(Icons.delete),
                              iconSize: 20,
                              visualDensity: const VisualDensity(
                                  horizontal: -3, vertical: -3),
                              onPressed: () => widget.onDelete(widget.item),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Line 3 for non-CHECK: category
                    if ((widget.item.category).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.item.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
