import 'package:flutter/material.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/views/graph_view.dart';
import 'package:daily_inc/src/views/history_view.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/core/time_converter.dart';

class DailyThingItem extends StatefulWidget {
  final DailyThing item;
  final DataManager dataManager;
  final Function(DailyThing) onEdit;
  final Function(DailyThing) onDelete;
  final Function(DailyThing) onDuplicate;
  final Future<bool> Function(DailyThing) onConfirmSnooze;
  final Function(DailyThing, {bool startInOvertime}) showFullscreenTimer;
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
    required this.onConfirmSnooze,
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
  void _showEditNoteDialog(BuildContext context, DailyThing item) {
    final notesController = TextEditingController(text: item.notes);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: notesController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter your note...'),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedItem = item.copyWith(notes: notesController.text);
                await widget.dataManager.updateDailyThing(updatedItem);
                if (mounted) {
                  setState(() {});
                }
                widget.onItemChanged?.call();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatValue(double value, ItemType itemType) {
    if (itemType == ItemType.minutes) {
      return TimeConverter.toSmartString(value);
    } else if (itemType == ItemType.reps) {
      return '${value.round()}x';
    } else {
      return value >= 1 ? '✅' : '❌';
    }
  }

  bool _hasIncompleteProgress(DailyThing item) {
    final todayEntry = item.todayHistoryEntry;
    if (todayEntry == null) return false;

    // For minutes items: check if timer was started but not finished
    if (item.itemType == ItemType.minutes) {
      return (todayEntry.actualValue ?? 0) > 0 && !todayEntry.doneToday;
    }

    // For reps items: check if reps were entered but target wasn't met
    if (item.itemType == ItemType.reps) {
      return todayEntry.actualValue != null && !todayEntry.doneToday;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isSnoozedToday = widget.item.isSnoozedForToday;
    final isLiterallyDoneToday = widget.item.hasBeenDoneLiterallyToday;

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) {
        return widget.onConfirmSnooze(widget.item);
      },
      background: Container(
        color: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.snooze, color: Colors.white),
      ),
      child: Card(
        color: isSnoozedToday ? Colors.blueGrey[700] : null,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ExpansionTile(
            key: ValueKey(
                '${widget.item.id}_${widget.isExpanded}_${widget.item.completedForToday}_$isSnoozedToday'),
            initiallyExpanded: widget.isExpanded,
            onExpansionChanged: widget.onExpansionChanged,
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
                          isSnoozedToday
                              ? Icons.snooze
                              : isLiterallyDoneToday
                                  ? Icons.check
                                  : (_hasIncompleteProgress(widget.item)
                                      ? Icons.brightness_2_outlined
                                      : Icons.close),
                          color: isSnoozedToday
                              ? Colors.white70
                              : isLiterallyDoneToday
                                  ? Theme.of(context).colorScheme.primary
                                  : _hasIncompleteProgress(widget.item)
                                      ? ColorPalette.partialYellow
                                      : widget.allTasksCompleted
                                          ? Theme.of(context).colorScheme.primary
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
                            if (isLiterallyDoneToday) {
                              widget.showFullscreenTimer(widget.item,
                                  startInOvertime: true);
                            } else {
                              widget.showFullscreenTimer(widget.item);
                            }
                          } else if (widget.item.itemType == ItemType.check) {
                            final today = DateTime.now();
                            final todayDate = DateTime(today.year, today.month, today.day);
                            final existingEntry = widget.item.todayHistoryEntry;

                            final wasDone = existingEntry?.doneToday ?? false;
                            final newDone = !wasDone;
                            final newValue = newDone ? 1.0 : 0.0;

                            final newEntry = HistoryEntry(
                              date: todayDate,
                              targetValue: newValue,
                              doneToday: newDone,
                            );

                            final history = List<HistoryEntry>.from(widget.item.history);
                            if (existingEntry != null) {
                              final index = history.indexOf(existingEntry);
                              history[index] = newEntry;
                            } else {
                              history.add(newEntry);
                            }

                            if (mounted) {
                              setState(() {});
                            }

                            await widget.dataManager
                                .updateDailyThing(widget.item.copyWith(history: history));
                            widget.onItemChanged?.call();
                            widget.checkAndShowCompletionSnackbar();
                          } else if (widget.item.itemType == ItemType.reps) {
                            widget.showRepsInputDialog(widget.item);
                          }
                        },
                        child: SizedBox(
                          width: 90.0,
                          height: 35.0,
                          child: Container(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isLiterallyDoneToday
                                  ? Theme.of(context).colorScheme.primary
                                  : _hasIncompleteProgress(widget.item)
                                      ? ColorPalette.partialYellow
                                      : Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.transparent,
                                  width: 0),
                            ),
                            alignment: Alignment.center,
                            child: widget.item.itemType == ItemType.check
                                ? Icon(
                                    isLiterallyDoneToday
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
                    if (widget.item.itemType == ItemType.check) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                tooltip: 'edit history',
                                icon: const Icon(Icons.history),
                                iconSize: 20,
                                visualDensity: const VisualDensity(
                                    horizontal: -3, vertical: -3),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoryView(
                                        item: widget.item,
                                        onHistoryUpdated: () {
                                          if (mounted) setState(() {});
                                          widget.onItemChanged?.call();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'edit note',
                                icon: const Icon(Icons.note_add_outlined),
                                iconSize: 20,
                                visualDensity: const VisualDensity(
                                    horizontal: -3, vertical: -3),
                                onPressed: () =>
                                    _showEditNoteDialog(context, widget.item),
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
                                  final updated = widget.item.copyWith(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
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
                                const SizedBox(width: 8),
                                Text(
                                  (() {
                                    final inc = widget.item.increment;
                                    final sign = inc < 0 ? '-' : '+';
                                    final absVal = inc.abs();

                                    if (widget.item.itemType ==
                                        ItemType.minutes) {
                                      final formatted =
                                          TimeConverter.toMmSsString(absVal);
                                      return '$sign$formatted';
                                    }

                                    String numStr = absVal.toStringAsFixed(2);
                                    numStr =
                                        numStr.replaceFirst(RegExp(r'\.00'), '');
                                    numStr =
                                        numStr.replaceFirst(RegExp(r'0'), '');
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
                                tooltip: 'edit history',
                                icon: const Icon(Icons.history),
                                iconSize: 20,
                                visualDensity: const VisualDensity(
                                    horizontal: -3, vertical: -3),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoryView(
                                        item: widget.item,
                                        onHistoryUpdated: () {
                                          if (mounted) setState(() {});
                                          widget.onItemChanged?.call();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'edit note',
                                icon: const Icon(Icons.note_add_outlined),
                                iconSize: 20,
                                visualDensity: const VisualDensity(
                                    horizontal: -3, vertical: -3),
                                onPressed: () =>
                                    _showEditNoteDialog(context, widget.item),
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
                                  final updated = widget.item.copyWith(
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
      ),
    );
  }
}
