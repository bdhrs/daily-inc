import 'package:flutter/material.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatefulWidget {
  final DailyThing item;
  final VoidCallback onHistoryUpdated;

  const HistoryView({
    super.key,
    required this.item,
    required this.onHistoryUpdated,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late List<HistoryEntry> _history;
  final DataManager _dataManager = DataManager();
  final NumberFormat _numberFormat = NumberFormat('0.##');
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.item.history);
    _history.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _saveChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

      if (confirmed == true) {
        debugPrint('History before saving: ${_history.map((e) => e.comment).toList()}');
        final updatedItem = widget.item.copyWith(history: _history);
        await _dataManager.updateDailyThing(updatedItem);
        widget.onHistoryUpdated();
        setState(() {
          _isDirty = false;
          _history = List.from(updatedItem.history);
        });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History saved successfully')),
        );
        // Only pop if we are not already popping due to the PopScope
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _history.remove(entry);
        _isDirty = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) {
      return true; // No changes, allow pop
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveChanges();
      return false; // Don't pop, saveChanges will handle navigation
    } else if (result == 'discard') {
      return true; // Allow pop
    }
    // If result is 'cancel', do nothing and stay on the page
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return; // A pop gesture was already handled by the system
        }
        // This callback is for when the system tries to pop, but canPop is false.
        // We should show our dialog here as well.
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit History: ${widget.item.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DataTable(
              columnSpacing: 4.0,
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Target'), numeric: true),
                DataColumn(label: Text('Actual'), numeric: true),
                DataColumn(label: Text('Done')),
                DataColumn(label: Text('Comment')),
                DataColumn(label: Text('')), // For delete icon
              ],
              rows: _history.map((entry) {
                final index = _history.indexOf(entry);
                return DataRow(
                  cells: [
                    DataCell(
                        Text(DateFormat('yy/MM/dd').format(entry.date))),
                    DataCell(
                      TextFormField(
                        initialValue:
                            _numberFormat.format(entry.targetValue),
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(fontSize: 14.0),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isDirty = true;
                            _history[index] = entry.copyWith(
                              targetValue: double.tryParse(value) ??
                                  entry.targetValue,
                            );
                            debugPrint('Updated targetValue for index $index: ${_history[index].targetValue}');
                          });
                        },
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: entry.actualValue != null
                            ? _numberFormat.format(entry.actualValue)
                            : '',
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(fontSize: 14.0),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isDirty = true;
                            _history[index] = entry.copyWith(
                              actualValue: double.tryParse(value),
                            );
                            debugPrint('Updated actualValue for index $index: ${_history[index].actualValue}');                                });
                        },
                      ),
                    ),
                    DataCell(
                      Checkbox(
                        value: entry.doneToday,
                        onChanged: (value) {
                          setState(() {
                            _isDirty = true;
                            _history[index] =
                                entry.copyWith(doneToday: value);
                          });
                        },
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 150, // Fixed width for comment field
                        child: TextFormField(
                          initialValue: entry.comment,
                          style: const TextStyle(fontSize: 14.0),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isDirty = true;
                              _history[index] =
                                  entry.copyWith(comment: value);
                              debugPrint('Updated comment for index $index: ${_history[index].comment}');
                            });
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteEntry(entry),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}