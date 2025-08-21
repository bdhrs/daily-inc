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
  bool _isAddingEntry = false;
  late TextEditingController _newDateController;
  late TextEditingController _newTargetValueController;
  late TextEditingController _newActualValueController;
  late TextEditingController _newCommentController;
  bool _newDoneToday = false;
  bool _isDateInvalid = false;

  // Controllers for existing entries
  final Map<String, TextEditingController> _targetControllers = {};
  final Map<String, TextEditingController> _actualControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.item.history);
    _history.sort((a, b) => b.date.compareTo(a.date));
    _newDateController = TextEditingController(
      text: DateFormat('yy/MM/dd').format(DateTime.now()),
    );
    _newTargetValueController = TextEditingController(
      text: _numberFormat.format(widget.item.todayValue),
    );
    _newActualValueController = TextEditingController();
    _newCommentController = TextEditingController();
    _isDateInvalid = false;

    // Add listener to validate date when it changes
    _newDateController.addListener(() {
      _validateDate(_newDateController.text);
    });

    // Initialize controllers for existing entries
    _initializeControllers();
  }

  void _initializeControllers() {
    // Clear existing controllers
    for (final controller in _targetControllers.values) {
      controller.dispose();
    }
    for (final controller in _actualControllers.values) {
      controller.dispose();
    }
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    _targetControllers.clear();
    _actualControllers.clear();
    _commentControllers.clear();

    // Initialize controllers for existing entries
    for (final entry in _history) {
      final key = _getEntryKey(entry);
      _targetControllers[key] = TextEditingController(
        text: _numberFormat.format(entry.targetValue),
      );
      _actualControllers[key] = TextEditingController(
        text: entry.actualValue != null
            ? _numberFormat.format(entry.actualValue)
            : '',
      );
      _commentControllers[key] = TextEditingController(
        text: entry.comment ?? '',
      );
    }
  }

  String _getEntryKey(HistoryEntry entry) {
    // Use the date as the key, but ensure uniqueness by including time components
    // This assumes that entries are unique per day, which is validated elsewhere
    return entry.date.toIso8601String();
  }

  bool _isDateAlreadyExists(DateTime date) {
    return _history.any(
      (entry) =>
          entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day,
    );
  }

  void _validateDate(String dateStr) {
    try {
      final date = DateFormat('yy/MM/dd').parse(dateStr);
      setState(() {
        _isDateInvalid = _isDateAlreadyExists(date);
      });
    } catch (e) {
      // If parsing fails, we don't need to check for duplicates
      // The existing validation will handle this
      setState(() {
        _isDateInvalid = false;
      });
    }
  }

  Future<void> _saveChanges() async {
      debugPrint(
          'History before saving: ${_history.map((e) => e.comment).toList()}');
      final updatedItem = widget.item.copyWith(history: _history);
      await _dataManager.updateDailyThing(updatedItem);
      widget.onHistoryUpdated();
      setState(() {
        _isDirty = false;
        _history = List.from(updatedItem.history);
        // Reinitialize controllers with new data
        _initializeControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History saved successfully')),
        );
      }
  }

  void _startAddingEntry() {
    setState(() {
      _isAddingEntry = true;
      // Reset the form fields
      _newDateController.text = DateFormat('yy/MM/dd').format(DateTime.now());
      _newTargetValueController.text =
          _numberFormat.format(widget.item.todayValue);
      _newActualValueController.text = '';
      _newCommentController.text = '';
      _newDoneToday = false;
      // Validate the date immediately
      _validateDate(_newDateController.text);
    });
  }

  void _saveNewEntry() {
    // Validate target value
    final targetValueStr = _newTargetValueController.text;
    if (targetValueStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target value cannot be empty')),
      );
      return;
    }

    final targetValue = double.tryParse(targetValueStr);
    if (targetValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid target value')),
      );
      return;
    }

    // Validate actual value if provided
    double? actualValue;
    if (_newActualValueController.text.isNotEmpty) {
      actualValue = double.tryParse(_newActualValueController.text);
      if (actualValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid actual value')),
        );
        return;
      }
    }

    // Parse date from the text field
    DateTime? date;
    try {
      date = DateFormat('yy/MM/dd').parse(_newDateController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date format')),
      );
      return;
    }

    // Check if an entry with the same date already exists
    final existingEntryIndex = _history.indexWhere(
      (entry) =>
          entry.date.year == date!.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day,
    );

    if (existingEntryIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An entry with this date already exists')),
      );
      return;
    }

    final newEntry = HistoryEntry(
      date: date,
      targetValue: targetValue,
      doneToday: _newDoneToday,
      actualValue: actualValue,
      comment: _newCommentController.text,
    );

    setState(() {
      _history.insert(0, newEntry);
      _isDirty = true;
      _isAddingEntry = false;

      // Initialize controllers for the new entry
      final key = _getEntryKey(newEntry);
      _targetControllers[key] = TextEditingController(
        text: _numberFormat.format(newEntry.targetValue),
      );
      _actualControllers[key] = TextEditingController(
        text: newEntry.actualValue != null
            ? _numberFormat.format(newEntry.actualValue)
            : '',
      );
      _commentControllers[key] = TextEditingController(
        text: newEntry.comment ?? '',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry added successfully')),
    );
  }

  void _cancelAddingEntry() {
    setState(() {
      _isAddingEntry = false;
    });
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
      final key = _getEntryKey(entry);
      setState(() {
        _history.remove(entry);
        _isDirty = true;
        // Remove controllers for deleted entry
        _targetControllers.remove(key)?.dispose();
        _actualControllers.remove(key)?.dispose();
        _commentControllers.remove(key)?.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty, // This will prevent immediate pop if dirty
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return; // A pop gesture was already handled by the system (e.g., if canPop was true)
        }

        // If canPop was false (meaning _isDirty is true), we handle the dialog here.
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content:
                const Text('You have unsaved changes. What would you like to do?'),
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
          if (mounted) {
            Navigator.of(context).pop(); // Pop after saving
          }
        } else if (result == 'discard') {
          if (mounted) {
            Navigator.of(context).pop(); // Pop, discarding changes
          }
        }
        // If result is 'cancel', do nothing and stay on the page.
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit History: ${widget.item.name}'),
          actions: [
            if (!_isAddingEntry)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _startAddingEntry,
                tooltip: 'Add Entry',
              ),
            if (_isAddingEntry)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelAddingEntry,
                tooltip: 'Cancel Adding Entry',
              ),
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
                DataColumn(
                    label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('#',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Target'), numeric: true),
                DataColumn(label: Text('Actual'), numeric: true),
                DataColumn(label: Text('Done')),
                DataColumn(label: Text('Comment')),
                DataColumn(label: Text('Actions')), // For delete icon
              ],
              rows: [
                if (_isAddingEntry)
                  DataRow(
                    cells: [
                      const DataCell(Text('')), // Empty cell for number column
                      DataCell(
                        TextFormField(
                          controller: _newDateController,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: _isDateInvalid ? Colors.red : null,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            enabledBorder: _isDateInvalid
                                ? const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                  )
                                : InputBorder.none,
                            focusedBorder: _isDateInvalid
                                ? const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          controller: _newTargetValueController,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontSize: 14.0),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          controller: _newActualValueController,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontSize: 14.0),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      DataCell(
                        Checkbox(
                          value: _newDoneToday,
                          onChanged: (value) {
                            setState(() {
                              _newDoneToday = value ?? false;
                            });
                          },
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 150, // Fixed width for comment field
                          child: TextFormField(
                            controller: _newCommentController,
                            style: const TextStyle(fontSize: 14.0),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _isDateInvalid ? null : _saveNewEntry,
                          tooltip: _isDateInvalid
                              ? 'Date already exists'
                              : 'Save Entry',
                        ),
                      ),
                    ],
                  ),
                ..._history.map((entry) {
                  final index = _history.indexOf(entry);
                  return DataRow(
                    cells: [
                      DataCell(Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${_history.length - index}.',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataCell(Text(DateFormat('yy/MM/dd').format(entry.date))),
                      DataCell(
                        TextFormField(
                          controller: _targetControllers[_getEntryKey(entry)]!,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontSize: 14.0),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isDirty = true;
                              _history[index] = entry.copyWith(
                                targetValue:
                                    double.tryParse(value) ?? entry.targetValue,
                              );
                              debugPrint(
                                  'Updated targetValue for index $index: ${_history[index].targetValue}');
                            });
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          controller: _actualControllers[_getEntryKey(entry)]!,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(fontSize: 14.0),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isDirty = true;
                              _history[index] = entry.copyWith(
                                actualValue: double.tryParse(value),
                              );
                              debugPrint(
                                  'Updated actualValue for index $index: ${_history[index].actualValue}');
                            });
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
                            controller:
                                _commentControllers[_getEntryKey(entry)]!,
                            style: const TextStyle(fontSize: 14.0),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isDirty = true;
                                _history[index] =
                                    entry.copyWith(comment: value);
                                debugPrint(
                                    'Updated comment for index $index: ${_history[index].comment}');
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
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
