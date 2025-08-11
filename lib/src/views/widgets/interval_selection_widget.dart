import 'package:flutter/material.dart';
import 'package:daily_inc/src/models/interval_type.dart';

class IntervalSelectionWidget extends StatefulWidget {
  final IntervalType initialIntervalType;
  final int? initialIntervalValue;
  final List<int>? initialWeekdays;
  final Function(IntervalType, int?, List<int>?) onChanged;

  const IntervalSelectionWidget({
    super.key,
    required this.initialIntervalType,
    this.initialIntervalValue,
    this.initialWeekdays,
    required this.onChanged,
  });

  @override
  State<IntervalSelectionWidget> createState() =>
      _IntervalSelectionWidgetState();
}

class _IntervalSelectionWidgetState extends State<IntervalSelectionWidget> {
  late IntervalType _selectedType;
  late TextEditingController _frequencyController;
  late List<bool> _selectedWeekdays;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialIntervalType;
    _frequencyController = TextEditingController(
        text: widget.initialIntervalValue?.toString() ?? '1');
    _selectedWeekdays = List.generate(7, (_) => false);

    if (widget.initialWeekdays != null) {
      for (final day in widget.initialWeekdays!) {
        if (day >= 1 && day <= 7) {
          _selectedWeekdays[day - 1] = true;
        }
      }
    }

    _frequencyController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _frequencyController.removeListener(_onChanged);
    _frequencyController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final freqValue = int.tryParse(_frequencyController.text);
    final selectedDays = _selectedWeekdays
        .asMap()
        .entries
        .where((e) => e.value)
        .map((e) => e.key + 1)
        .toList();

    widget.onChanged(_selectedType, freqValue, selectedDays);
  }

  void _onWeekdayPressed(int index) {
    setState(() {
      _selectedWeekdays[index] = !_selectedWeekdays[index];
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<IntervalType>(
          segments: const [
            ButtonSegment(value: IntervalType.byDays, label: Text('By Days')),
            ButtonSegment(
                value: IntervalType.byWeekdays, label: Text('By Weekday')),
          ],
          selected: {_selectedType},
          onSelectionChanged: (newSelection) {
            setState(() {
              _selectedType = newSelection.first;
              _onChanged();
            });
          },
        ),
        const SizedBox(height: 16),
        if (_selectedType == IntervalType.byDays)
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
                return 'Must be a number greater than 0';
              }
              return null;
            },
          )
        else
          ToggleButtons(
            isSelected: _selectedWeekdays,
            onPressed: _onWeekdayPressed,
            children: const [
              Text('Mon'),
              Text('Tue'),
              Text('Wed'),
              Text('Thu'),
              Text('Fri'),
              Text('Sat'),
              Text('Sun'),
            ],
          ),
      ],
    );
  }
}
