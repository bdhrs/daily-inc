import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class AddEditDailyItemView extends StatefulWidget {
  final DataManager dataManager;
  final DailyThing? dailyThing;
  final VoidCallback onSubmitCallback;

  const AddEditDailyItemView({
    super.key,
    required this.dataManager,
    this.dailyThing,
    required this.onSubmitCallback,
  });

  @override
  State<AddEditDailyItemView> createState() => _AddEditDailyItemViewState();
}

class _AddEditDailyItemViewState extends State<AddEditDailyItemView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _iconController;
  late TextEditingController _nameController;
  late TextEditingController _startDateController;
  late TextEditingController _startValueController;
  late TextEditingController _durationController;
  late TextEditingController _endValueController;
  late TextEditingController _frequencyController;
  late TextEditingController _nagTimeController;
  late TextEditingController _nagMessageController;
  ItemType _selectedItemType = ItemType.minutes;
  TimeOfDay? _selectedNagTime;
  final _log = Logger('AddEditDailyItemView');

  bool _didChangeDependencies = false;

  @override
  void initState() {
    super.initState();
    _log.info('initState called');
    final existingItem = widget.dailyThing;
    _iconController = TextEditingController(text: existingItem?.icon);
    _nameController = TextEditingController(text: existingItem?.name);
    _startDateController = TextEditingController(
      text: existingItem != null
          ? DateFormat('yyyy-MM-dd').format(existingItem.startDate)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _startValueController =
        TextEditingController(text: existingItem?.startValue.toString());
    _durationController =
        TextEditingController(text: existingItem?.duration.toString() ?? '30');
    _endValueController =
        TextEditingController(text: existingItem?.endValue.toString());
    _frequencyController = TextEditingController(
        text: existingItem?.frequencyInDays.toString() ?? '1');
    _nagTimeController = TextEditingController();
    _nagMessageController = TextEditingController();
    if (existingItem != null) {
      _log.info('Editing existing item: ${existingItem.name}');
      _selectedItemType = existingItem.itemType;
      if (existingItem.nagTime != null) {
        _selectedNagTime = TimeOfDay.fromDateTime(existingItem.nagTime!);
      }
      _nagMessageController.text = existingItem.nagMessage ?? '';
    } else {
      _log.info('Creating new item');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _log.info('didChangeDependencies called');
    if (!_didChangeDependencies) {
      if (_selectedNagTime != null) {
        _nagTimeController.text = _selectedNagTime!.format(context);
      }
      _didChangeDependencies = true;
    }
  }

  @override
  void dispose() {
    _log.info('dispose called');
    _iconController.dispose();
    _nameController.dispose();
    _startDateController.dispose();
    _startValueController.dispose();
    _durationController.dispose();
    _endValueController.dispose();
    _frequencyController.dispose();
    _nagTimeController.dispose();
    _nagMessageController.dispose();
    super.dispose();
  }

  List<HistoryEntry> _updateHistoryEntriesWithNewParameters(
    List<HistoryEntry> history,
    double newStartValue,
    double newEndValue,
    int newDuration,
    DateTime newStartDate,
  ) {
    _log.info('Updating history entries with new progression parameters');
    
    // Calculate new increment
    final newIncrement = newDuration > 0 ? (newEndValue - newStartValue) / newDuration : 0.0;
    
    // Create updated history entries
    return history.map((entry) {
      // For entries that have actual values (reps), update their targetValue but keep actualValue
      if (entry.actualValue != null) {
        // Recalculate target value based on new parameters for this entry's date
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final startDateOnly = DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
        final daysSinceStart = entryDate.difference(startDateOnly).inDays;
        
        double newTargetValue;
        if (daysSinceStart <= 0) {
          newTargetValue = newStartValue;
        } else if (daysSinceStart >= newDuration) {
          newTargetValue = newEndValue;
        } else {
          newTargetValue = newStartValue + (newIncrement * daysSinceStart);
        }
        
        return HistoryEntry(
          date: entry.date,
          targetValue: newTargetValue,
          doneToday: entry.doneToday,
          actualValue: entry.actualValue,
        );
      }
      
      // For entries without actual values, recalculate targetValue based on new parameters
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final startDateOnly = DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
      final daysSinceStart = entryDate.difference(startDateOnly).inDays;
      
      double newTargetValue;
      if (daysSinceStart <= 0) {
        newTargetValue = newStartValue;
      } else if (daysSinceStart >= newDuration) {
        newTargetValue = newEndValue;
      } else {
        newTargetValue = newStartValue + (newIncrement * daysSinceStart);
      }
      
      return HistoryEntry(
        date: entry.date,
        targetValue: newTargetValue,
        doneToday: entry.doneToday,
        actualValue: entry.actualValue,
      );
    }).toList();
  }

  void _submitDailyItem() async {
    _log.info('Attempting to submit daily item');
    if (_formKey.currentState!.validate()) {
      _log.info('Form is valid');
      try {
        final startDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(_startDateController.text);

        // For CHECK items, use default values since the fields are hidden
        final double startValue;
        final int duration;
        final double endValue;

        if (_selectedItemType == ItemType.check) {
          startValue = 0.0; // Always start unchecked
          duration = 1; // Duration is irrelevant for check items
          endValue = 1.0; // End value is checked state
        } else {
          startValue = double.parse(_startValueController.text);
          duration = int.parse(_durationController.text);
          endValue = double.parse(_endValueController.text);
        }

        final DateTime? nagTime;
        if (_selectedNagTime != null) {
          final now = DateTime.now();
          // Create the nag time for today at the selected time
          DateTime scheduledTime = DateTime(now.year, now.month, now.day,
              _selectedNagTime!.hour, _selectedNagTime!.minute);

          // Ensure the time is in the future
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          nagTime = scheduledTime;
        } else {
          nagTime = null;
        }

        // Update existing history entries to reflect new progression parameters if needed
        List<HistoryEntry> updatedHistory = widget.dailyThing?.history ?? [];
        if (widget.dailyThing != null) {
          // Only update if progression parameters actually changed
          final oldStartValue = widget.dailyThing!.startValue;
          final oldEndValue = widget.dailyThing!.endValue;
          final oldDuration = widget.dailyThing!.duration;
          
          if (oldStartValue != startValue || 
              oldEndValue != endValue || 
              oldDuration != duration) {
            // Progression parameters changed, update history entries
            updatedHistory = _updateHistoryEntriesWithNewParameters(
              widget.dailyThing!.history,
              startValue,
              endValue,
              duration,
              startDate,
            );
          }
        }

        final newItem = DailyThing(
          id: widget.dailyThing?.id,
          icon: _iconController.text,
          name: _nameController.text,
          itemType: _selectedItemType,
          startDate: startDate,
          startValue: startValue,
          duration: duration,
          endValue: endValue,
          history: updatedHistory,
          nagTime: nagTime,
          nagMessage: _nagMessageController.text.isEmpty
              ? null
              : _nagMessageController.text,
          frequencyInDays: int.parse(_frequencyController.text),
        );
        _log.info('Created new DailyThing: ${newItem.name}');

        if (widget.dailyThing == null) {
          _log.info('Adding new item');
          await widget.dataManager.addDailyThing(newItem);
        } else {
          _log.info('Updating existing item');
          await widget.dataManager.updateDailyThing(newItem);
        }

        if (!mounted) return;
        _log.info('Item submitted successfully, calling callback and popping');
        widget.onSubmitCallback();
        Navigator.of(context).pop(newItem);
      } catch (e, s) {
        _log.severe('Error submitting daily item', e, s);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      _log.warning('Form is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    _log.info('build called');
    final theme = Theme.of(context);
    final hintDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dailyThing == null ? 'New Daily Thing' : 'Edit Daily Thing',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Basic Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _iconController,
                        decoration: const InputDecoration(
                          labelText: 'Icon',
                          hintText: 'e.g. 🚀',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Daily Reading',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency (days)',
                    hintText: '1',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a frequency';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ItemType>(
                  value: _selectedItemType,
                  items: ItemType.values.map((type) {
                    return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.toString().split('.').last.toUpperCase(),
                        ));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Progress Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date (YYYY-MM-DD)',
                    hintText: hintDate,
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a start date';
                    }
                    try {
                      DateFormat('yyyy-MM-dd').parse(value);
                      return null;
                    } catch (e) {
                      return 'Invalid date format';
                    }
                  },
                ),
                // Hide start/end values and duration for CHECK items
                if (_selectedItemType != ItemType.check) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startValueController,
                          decoration: const InputDecoration(
                            labelText: 'Start Value',
                            hintText: '0.0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a start value';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endValueController,
                          decoration: const InputDecoration(
                            labelText: 'End Value',
                            hintText: '0.0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an end value';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      hintText: '30',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a duration';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nagTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Nag Time',
                    hintText: 'HH:mm',
                    prefixIcon: Icon(Icons.alarm),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedNagTime ?? TimeOfDay.now(),
                    );
                    if (picked != null && picked != _selectedNagTime) {
                      setState(() {
                        _selectedNagTime = picked;
                        _nagTimeController.text = picked.format(context);
                      });
                    }
                  },
                  validator: (value) {
                    if (_nagMessageController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Please select a nag time when a nag message is provided.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nagMessageController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nag Message',
                    hintText: 'e.g. Time to do your daily reading!',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitDailyItem,
                      child: Text(widget.dailyThing == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
