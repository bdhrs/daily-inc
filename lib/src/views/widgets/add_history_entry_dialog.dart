import 'package:flutter/material.dart';
import 'dart:io';

import 'package:daily_inc/src/models/history_entry.dart';
import 'package:intl/intl.dart';

class AddHistoryEntryDialog extends StatefulWidget {
  final DateTime initialDate;
  final double initialTargetValue;

  const AddHistoryEntryDialog({
    super.key,
    required this.initialDate,
    required this.initialTargetValue,
  });

  @override
  State<AddHistoryEntryDialog> createState() => _AddHistoryEntryDialogState();
}

class _AddHistoryEntryDialogState extends State<AddHistoryEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _targetValueController;
  late TextEditingController _actualValueController;
  late TextEditingController _commentController;
  bool _doneToday = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.initialDate),
    );
    _targetValueController = TextEditingController(
      text: widget.initialTargetValue.toStringAsFixed(2),
    );
    _actualValueController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _targetValueController.dispose();
    _actualValueController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final date = _selectedDate ?? widget.initialDate;
      final targetValue = double.tryParse(_targetValueController.text) ?? 0.0;
      final actualValue = _actualValueController.text.isEmpty
          ? null
          : double.tryParse(_actualValueController.text);

      final entry = HistoryEntry(
        date: date,
        targetValue: targetValue,
        doneToday: _doneToday,
        actualValue: actualValue,
        comment: _commentController.text,
      );

      Navigator.of(context).pop(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add History Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date field with picker
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  try {
                    DateFormat('yyyy-MM-dd').parse(value);
                    return null;
                  } catch (e) {
                    return 'Invalid date format';
                  }
                },
              ),
              const SizedBox(height: 16),

              // Target Value
              TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  prefixIcon: Icon(Icons.flag),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Actual Value (optional)
              TextFormField(
                controller: _actualValueController,
                decoration: const InputDecoration(
                  labelText: 'Actual Value (optional)',
                  prefixIcon: Icon(Icons.check),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Done Today checkbox
              Row(
                children: [
                  const Icon(Icons.done),
                  const SizedBox(width: 8),
                  const Text('Done Today'),
                  const Spacer(),
                  Checkbox(
                    value: _doneToday,
                    onChanged: (value) {
                      setState(() {
                        _doneToday = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Comment
              TextFormField(
                controller: _commentController,
                textCapitalization: Platform.isAndroid
                    ? TextCapitalization.sentences
                    : TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Add Entry'),
        ),
      ],
    );
  }
}
