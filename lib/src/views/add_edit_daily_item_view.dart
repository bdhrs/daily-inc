import 'package:daily_inc/src/core/value_converter.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/data/history_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:daily_inc/src/views/widgets/interval_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:daily_inc/src/views/widgets/custom_bell_selector.dart'; // Import the new dialog

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
  late TextEditingController _nagTimeController;
  late TextEditingController _nagMessageController;
  late TextEditingController _categoryController; // New category controller
  late TextEditingController _bellSoundController; // New bell sound controller
  late TextEditingController _subdivisionsController;
  late TextEditingController _subdivisionBellSoundController;
  TextEditingController? _incrementController;
  late TextEditingController _incrementMinutesController;
  late TextEditingController _incrementSecondsController;
  ItemType _selectedItemType = ItemType.minutes;
  TimeOfDay? _selectedNagTime;
  final _log = Logger('AddEditDailyItemView');

  // New state variables for the unified interval widget
  IntervalType _selectedIntervalType = IntervalType.byDays;
  int _intervalValue = 1;
  List<int> _selectedWeekdays = [];
  List<String> _uniqueCategories = [];

  bool _didChangeDependencies = false;
  String? _selectedBellSoundPath; // New state variable for bell sound
  String? _selectedSubdivisionBellSoundPath;
  bool _isUpdatingFromIncrement = false;

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
    _nagTimeController = TextEditingController();
    _nagMessageController = TextEditingController();
    _categoryController = TextEditingController(
        text:
            (existingItem?.category == null || existingItem?.category == 'None')
                ? ''
                : existingItem!
                    .category); // Initialize category controller properly

    _incrementController = TextEditingController();
    _incrementMinutesController = TextEditingController();
    _incrementSecondsController = TextEditingController();

    _startValueController.addListener(_updateIncrementField);
    _endValueController.addListener(_updateIncrementField);
    _durationController.addListener(_updateIncrementField);
    _incrementMinutesController.addListener(_updateDurationFromIncrement);
    _incrementSecondsController.addListener(_updateDurationFromIncrement);

    // Set initial increment value after all controllers are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final increment = _calculateIncrement();
      _incrementController!.text = increment;
      _updateIncrementMinutesAndSecondsFields(
          double.tryParse(increment) ?? 0.0);
    });

    if (existingItem != null) {
      _log.info('Editing existing item: ${existingItem.name}');
      _selectedItemType = existingItem.itemType;
      _selectedIntervalType = existingItem.intervalType;
      _intervalValue = existingItem.intervalValue;
      _selectedWeekdays = existingItem.intervalWeekdays;
      if (existingItem.nagTime != null) {
        _selectedNagTime = TimeOfDay.fromDateTime(existingItem.nagTime!);
      }
      _nagMessageController.text = existingItem.nagMessage ?? '';
      _selectedBellSoundPath = existingItem.bellSoundPath ??
          'assets/bells/bell1.mp3'; // Initialize bell sound path with default
      _subdivisionsController = TextEditingController(
          text: existingItem.subdivisions?.toString() ?? '1');
      _selectedSubdivisionBellSoundPath = existingItem.subdivisionBellSoundPath;
    } else {
      _log.info('Creating new item');
      _selectedBellSoundPath =
          'assets/bells/bell1.mp3'; // Set default for new items
      _subdivisionsController = TextEditingController(text: '1');
      // Initialize subdivision bell sound path for new items
      _selectedSubdivisionBellSoundPath = null;
    }
    _bellSoundController = TextEditingController(
        text: _selectedBellSoundPath?.split('/').last ?? 'bell1.mp3');
    _subdivisionBellSoundController = TextEditingController(
        text: _selectedSubdivisionBellSoundPath?.split('/').last);

    // Load unique categories for autofill (type-specific)
    _loadUniqueCategoriesForSelectedType();
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
    _startValueController.removeListener(_updateIncrementField);
    _endValueController.removeListener(_updateIncrementField);
    _durationController.removeListener(_updateIncrementField);
    _iconController.dispose();
    _nameController.dispose();
    _startDateController.dispose();
    _startValueController.dispose();
    _durationController.dispose();
    _endValueController.dispose();
    _nagTimeController.dispose();
    _nagMessageController.dispose();
    _categoryController.dispose(); // Dispose category controller
    _bellSoundController.dispose(); // Dispose bell sound controller
    _subdivisionsController.dispose();
    _subdivisionBellSoundController.dispose();
    _incrementController?.dispose();
    _incrementMinutesController.dispose();
    _incrementSecondsController.dispose();
    super.dispose();
  }

  String _calculateIncrement() {
    try {
      final startValue = double.tryParse(_startValueController.text) ?? 0.0;
      final endValue = double.tryParse(_endValueController.text) ?? 0.0;
      final duration = int.tryParse(_durationController.text);

      if (duration == null || duration <= 0) return '0.0';

      final increment = (endValue - startValue) / duration;
      return increment.toStringAsFixed(2);
    } catch (e) {
      return '0.0';
    }
  }

  void _updateIncrementField() {
    if (_isUpdatingFromIncrement) return;
    if (_incrementController != null) {
      final increment = _calculateIncrement();
      _incrementController!.text = increment;
      _updateIncrementMinutesAndSecondsFields(
          double.tryParse(increment) ?? 0.0);
      setState(() {});
    }
  }

  void _updateIncrementMinutesAndSecondsFields(double increment) {
    final minutes = increment.truncate();
    final seconds = ((increment - minutes) * 60).round();
    _incrementMinutesController.text = minutes.toString();
    _incrementSecondsController.text = seconds.toString();
  }

  void _updateDurationFromIncrement() {
    _isUpdatingFromIncrement = true;
    try {
      final minutes = int.tryParse(_incrementMinutesController.text) ?? 0;
      final seconds = int.tryParse(_incrementSecondsController.text) ?? 0;
      final increment = minutes + (seconds / 60.0);

      if (increment == 0) {
        _isUpdatingFromIncrement = false;
        return;
      }

      _incrementController!.text = increment.toStringAsFixed(2);

      final startValue = double.tryParse(_startValueController.text) ?? 0.0;
      final endValue = double.tryParse(_endValueController.text) ?? 0.0;

      if (increment == 0) return;

      final newDuration = ((endValue - startValue) / increment).round();
      if (newDuration > 0) {
        _durationController.text = newDuration.toString();
        setState(() {});
      }
    } catch (e) {
      _log.warning('Error calculating duration from increment: $e');
    }
    _isUpdatingFromIncrement = false;
  }

  void _updateDurationFromIncrementReps() {
    _isUpdatingFromIncrement = true;
    try {
      final increment = double.tryParse(_incrementController!.text) ?? 0.0;

      if (increment == 0) {
        _isUpdatingFromIncrement = false;
        return;
      }

      final startValue = double.tryParse(_startValueController.text) ?? 0.0;
      final endValue = double.tryParse(_endValueController.text) ?? 0.0;

      if (increment == 0) return;

      final newDuration = ((endValue - startValue) / increment).round();
      if (newDuration > 0) {
        _durationController.text = newDuration.toString();
        setState(() {});
      }
    } catch (e) {
      _log.warning('Error calculating duration from increment: $e');
    }
    _isUpdatingFromIncrement = false;
  }

  /// Load unique categories for autofill for the currently selected type
  Future<void> _loadUniqueCategoriesForSelectedType() async {
    _log.info('Loading unique categories for type $_selectedItemType');
    try {
      final categories = await widget.dataManager
          .getUniqueCategoriesForType(_selectedItemType);
      setState(() {
        _uniqueCategories = categories;
      });
    } catch (e, s) {
      _log.severe('Error loading type-specific unique categories', e, s);
    }
  }

  void _submitDailyItem() async {
    _log.info('Attempting to submit daily item');
    if (_formKey.currentState!.validate()) {
      _log.info('Form is valid');
      try {
        // Trim all text inputs
        _iconController.text = _iconController.text.trim();
        _nameController.text = _nameController.text.trim();
        _categoryController.text = _categoryController.text.trim();
        _nagMessageController.text = _nagMessageController.text.trim();

        final startDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(_startDateController.text.trim());

        // For CHECK items, use default values since the fields are hidden
        final double startValue;
        final int duration;
        final double endValue;

        if (_selectedItemType == ItemType.check) {
          startValue = 0.0; // Always start unchecked
          duration = 1; // Duration is irrelevant for check items
          endValue = 1.0; // End value is checked state
        } else {
          startValue = double.parse(_startValueController.text.trim());
          duration = int.parse(_durationController.text.trim());
          endValue = double.parse(_endValueController.text.trim());
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
          final oldStartDate = widget.dailyThing!.startDate;

          if (oldStartValue != startValue ||
              oldEndValue != endValue ||
              oldDuration != duration ||
              oldStartDate != startDate) {
            // Progression parameters changed, update history entries
            updatedHistory =
                HistoryManager.updateHistoryEntriesWithNewParameters(
              history: widget.dailyThing!.history,
              newStartValue: startValue,
              newEndValue: endValue,
              newDuration: duration,
              newStartDate: startDate,
            );
          }
        }

        // Handle interval logic
        var finalIntervalType = _selectedIntervalType;
        var finalIntervalValue = _intervalValue;
        var finalIntervalWeekdays = _selectedWeekdays;

        if (_selectedIntervalType == IntervalType.byWeekdays) {
          if (finalIntervalWeekdays.isEmpty) {
            // No weekdays selected, revert to default
            finalIntervalType = IntervalType.byDays;
            finalIntervalValue = 1;
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
          category: _categoryController.text.isEmpty
              ? 'None'
              : _categoryController.text,
          intervalType: finalIntervalType,
          intervalValue: finalIntervalValue,
          intervalWeekdays: finalIntervalWeekdays,
          bellSoundPath:
              _selectedBellSoundPath, // Pass the selected bell sound path
          subdivisions: int.tryParse(_subdivisionsController.text),
          subdivisionBellSoundPath: _selectedSubdivisionBellSoundPath,
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
                DropdownButtonFormField<ItemType>(
                  initialValue: _selectedItemType,
                  items: ItemType.values.map((type) {
                    return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.toString().split('.').last.toUpperCase(),
                        ));
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;

                    final currentDailyThing = DailyThing(
                      name: _nameController.text,
                      itemType: _selectedItemType,
                      startDate: DateTime.now(),
                      startValue:
                          double.tryParse(_startValueController.text) ?? 0.0,
                      duration: int.tryParse(_durationController.text) ?? 30,
                      endValue:
                          double.tryParse(_endValueController.text) ?? 0.0,
                    );

                    final converted =
                        ValueConverter.convert(currentDailyThing, value);
                    final newCategories = await widget.dataManager
                        .getUniqueCategoriesForType(value);

                    final currentCategory = _categoryController.text.trim();
                    String newCategoryText = _categoryController.text;
                    if (currentCategory.isNotEmpty &&
                        !newCategories.contains(currentCategory)) {
                      newCategoryText = '';
                    }

                    setState(() {
                      _selectedItemType = value;
                      _startValueController.text =
                          converted.startValue.toString();
                      _endValueController.text = converted.endValue.toString();
                      _uniqueCategories = newCategories;
                      _categoryController.text = newCategoryText;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  key: ValueKey(_selectedItemType), // rebuild when type changes
                  initialValue:
                      TextEditingValue(text: _categoryController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final source = _uniqueCategories;
                    if (textEditingValue.text.isEmpty) {
                      return source;
                    }
                    return source.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _categoryController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    // Post-build callback to safely update the controller
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted &&
                          fieldTextEditingController.text !=
                              _categoryController.text) {
                        fieldTextEditingController.text =
                            _categoryController.text;
                      }
                    });

                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onChanged: (value) {
                        _categoryController.text = value;
                      },
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. Health, Work, etc.',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                IntervalSelectionWidget(
                  initialIntervalType: _selectedIntervalType,
                  initialIntervalValue: _intervalValue,
                  initialWeekdays: _selectedWeekdays,
                  onChanged: (type, value, weekdays) {
                    setState(() {
                      _selectedIntervalType = type;
                      _intervalValue = value ?? 1;
                      _selectedWeekdays = weekdays ?? [];
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Progress Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.today),
                      tooltip: "Use today's date",
                      onPressed: () {
                        final today =
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        _startDateController.text = today;
                      },
                    ),
                  ],
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (days)',
                            hintText: '30',
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (_selectedItemType == ItemType.minutes) {
                                _updateIncrementField();
                              } else {
                                _updateIncrementField();
                              }
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a duration';
                            }
                            final duration = int.tryParse(value);
                            if (duration == null) {
                              return 'Please enter a valid number';
                            }
                            if (duration <= 0) {
                              return 'Duration must be positive';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_selectedItemType == ItemType.minutes) ...[
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _incrementMinutesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Incr. Min',
                                    hintText: '0',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    if (_selectedItemType == ItemType.minutes) {
                                      _updateDurationFromIncrement();
                                    } else {
                                      _updateDurationFromIncrementReps();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _incrementSecondsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sec',
                                    hintText: '0',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    if (_selectedItemType == ItemType.minutes) {
                                      _updateDurationFromIncrement();
                                    } else {
                                      _updateDurationFromIncrementReps();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: TextFormField(
                            controller: _incrementController,
                            decoration: const InputDecoration(
                              labelText: 'Increment',
                              hintText: '0.0',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (_selectedItemType == ItemType.minutes) {
                                _updateDurationFromIncrement();
                              } else {
                                _updateDurationFromIncrementReps();
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an increment';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // TextFormField(
                //   controller: _nagTimeController,
                //   decoration: const InputDecoration(
                //     labelText: 'Nag Time',
                //     hintText: 'HH:mm',
                //     prefixIcon: Icon(Icons.alarm),
                //   ),
                //   readOnly: true,
                //   onTap: () async {
                //     final TimeOfDay? picked = await showTimePicker(
                //       context: context,
                //       initialTime: _selectedNagTime ?? TimeOfDay.now(),
                //     );
                //     if (picked != null && picked != _selectedNagTime) {
                //       setState(() {
                //         _selectedNagTime = picked;
                //         _nagTimeController.text = picked.format(context);
                //       });
                //     }
                //   },
                //   validator: (value) {
                //     if (_nagMessageController.text.isNotEmpty &&
                //         (value == null || value.isEmpty)) {
                //       return 'Please select a nag time when a nag message is provided.';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 16),
                // TextFormField(
                //   controller: _nagMessageController,
                //   textCapitalization: TextCapitalization.sentences,
                //   decoration: const InputDecoration(
                //     labelText: 'Nag Message',
                //     hintText: 'e.g. Time to do your daily reading!',
                //   ),
                // ),
                if (_selectedItemType == ItemType.minutes)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _bellSoundController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Bell Sound',
                          hintText: 'Default (bell1.mp3)',
                          prefixIcon: const Icon(Icons.notifications_active),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () async {
                              final selectedPath = await showDialog<String?>(
                                context: context,
                                builder: (context) => CustomBellSelectorDialog(
                                  initialBellSoundPath: _selectedBellSoundPath,
                                ),
                              );
                              if (selectedPath != null) {
                                setState(() {
                                  _selectedBellSoundPath = selectedPath;
                                  _bellSoundController.text =
                                      selectedPath.split('/').last;
                                });
                              }
                            },
                          ),
                        ),
                        onTap: () async {
                          final selectedPath = await showDialog<String?>(
                            context: context,
                            builder: (context) => CustomBellSelectorDialog(
                              initialBellSoundPath: _selectedBellSoundPath,
                            ),
                          );
                          if (selectedPath != null) {
                            setState(() {
                              _selectedBellSoundPath = selectedPath;
                              _bellSoundController.text =
                                  selectedPath.split('/').last;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                if (_selectedItemType == ItemType.minutes) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _subdivisionsController,
                    decoration: const InputDecoration(
                      labelText: 'Subdivisions',
                      hintText: 'e.g. 2',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final subdivisions = int.tryParse(value);
                        if (subdivisions == null || subdivisions < 1) {
                          return 'Must be a positive number';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Automatically set bell3 as default subdivision bell when subdivisions > 1
                      if (value.isNotEmpty) {
                        final subdivisions = int.tryParse(value);
                        if (subdivisions != null &&
                            subdivisions > 1 &&
                            _selectedSubdivisionBellSoundPath == null) {
                          _selectedSubdivisionBellSoundPath =
                              'assets/bells/bell3.mp3';
                          _subdivisionBellSoundController.text = 'bell3.mp3';
                        }
                      }
                      setState(() {});
                    },
                  ),
                  if (int.tryParse(_subdivisionsController.text) != null &&
                      (int.tryParse(_subdivisionsController.text) ?? 0) > 1)
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _subdivisionBellSoundController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Subdivision Bell Sound',
                            hintText: 'Default (bell1.mp3)',
                            prefixIcon: const Icon(Icons.notifications_active),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () async {
                                final selectedPath = await showDialog<String?>(
                                  context: context,
                                  builder: (context) =>
                                      CustomBellSelectorDialog(
                                    initialBellSoundPath:
                                        _selectedSubdivisionBellSoundPath,
                                  ),
                                );
                                if (selectedPath != null) {
                                  setState(() {
                                    _selectedSubdivisionBellSoundPath =
                                        selectedPath;
                                    _subdivisionBellSoundController.text =
                                        selectedPath.split('/').last;
                                  });
                                }
                              },
                            ),
                          ),
                          onTap: () async {
                            final selectedPath = await showDialog<String?>(
                              context: context,
                              builder: (context) => CustomBellSelectorDialog(
                                initialBellSoundPath:
                                    _selectedSubdivisionBellSoundPath,
                              ),
                            );
                            if (selectedPath != null) {
                              setState(() {
                                _selectedSubdivisionBellSoundPath =
                                    selectedPath;
                                _subdivisionBellSoundController.text =
                                    selectedPath.split('/').last;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                ],
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
