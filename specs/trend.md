# TREND Type Specification

## Overview
The **TREND** type tracks qualitative progress with three possible states: improving, staying the same, or getting worse. This is ideal for subjective assessments like mood tracking, skill development, or habit quality where numerical measurement isn't appropriate.

## Type Name: TREND
- **Name**: TREND
- **Icon**: 📈 (trending up/down/neutral)
- **Description**: Tracks qualitative progress with three states: improving, staying the same, or getting worse

## Core Behavior

### Data Representation
- **Internal Values**:
  - `-1.0` = Getting worse
  - `0.0` = Staying the same
  - `1.0` = Improving
- **Display Values**: Uses consistent arrow representation:
  - `↘️` = Getting worse (down-right arrow)
  - `➡️` = Staying the same (right arrow)
  - `↗️` = Improving (up-right arrow)

### Input Mechanism
- **Input Dialog**: Three-button selection (similar to CHECK but with three options)
- **Interaction**: Single tap to select state for the day
- **Default State**: No selection (trend not entered yet)

## Integration Points

### 1. ItemType Enum (`lib/src/models/item_type.dart`)
```dart
enum ItemType { minutes, reps, check, percentage, trend }
```

### 2. IncrementCalculator (`lib/src/core/increment_calculator.dart`)
#### calculateDisplayValue()
```dart
if (item.itemType == ItemType.trend) {
  final todaysEntry = item.history.where((entry) {
    final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
    return entryDate == todayDate && entry.actualValue != null;
  }).toList();

  if (todaysEntry.isNotEmpty) {
    return todaysEntry.first.actualValue!;
  }
  return 0.0; // Default to "not entered" state
}
```

#### determineStatus()
```dart
if (item.itemType == ItemType.trend) {
  // TREND is considered "done" if any value is entered (not 0.0)
  return currentValue != 0.0 ? Status.green : Status.red;
}
```

#### isDone()
```dart
if (item.itemType == ItemType.trend) {
  // TREND is done if any value is entered (not 0.0)
  return currentValue != 0.0;
}
```

### 3. DailyThingItem (`lib/src/views/daily_thing_item.dart`)
#### _formatValue()
```dart
} else if (itemType == ItemType.trend) {
  if (value == -1.0) return '↘️';
  if (value == 0.0) return '→';
  if (value == 1.0) return '↗️';
  return '❓'; // Unknown state
}
```

#### Color Coding
- **Not entered**: `ColorPalette.warningOrange` (orange)
- **Entered**: `ColorPalette.primaryBlue` (blue) - regardless of trend direction

### 4. TrendInputDialog (`lib/src/views/trend_input_dialog.dart`)
New dialog component with three large buttons:
- ↗️ Improving (sets value to 1.0)
- ➡️ Same (sets value to 0.0)  
- ↘️ Worse (sets value to -1.0)

### 5. AddEditDailyItemView (`lib/src/views/add_edit_daily_item_view.dart`)
#### Dropdown Item
```dart
case ItemType.trend:
  icon = Icons.trending_up;
  name = 'Trend';
  break;
```

#### Field Visibility
- Hide start/end/duration fields (like CHECK and PERCENTAGE)
- TREND items don't use incremental progression

### 6. ValueConverter (`lib/src/core/value_converter.dart`)
Add TREND conversion logic:
- From TREND to other types: treat as boolean (improving = true, same/worse = false)
- To TREND from other types: non-zero = improving, zero = same

### 7. DataManager (`lib/src/data/data_manager.dart`)
- No special serialization needed (uses existing JSON structure)
- Values stored as doubles: -1.0, 0.0, 1.0

## UI/UX Design

### Main List Display
```
[↗️] Morning Mood       ↗️
[➡️] Work Focus        →
[↘️] Sleep Quality     ↘️
[❓] Exercise Quality  ❓ (not entered)
```

### Input Dialog Design
```
┌─────────────────────────────┐
│         Daily Trend         │
│                             │
│   [ ↗️ Improving  ]         │
│   [ ➡️ Same       ]         │
│   [ ↘️ Worse      ]         │
│                             │
│   [ Cancel ] [ Save ]       │
└─────────────────────────────┘
```

## Use Cases
1. **Mood tracking**: "How was your mood today?"
2. **Skill development**: "Did your piano practice feel better, same, or worse?"
3. **Habit quality**: "How well did you follow your meditation routine?"
4. **Health tracking**: "How do you feel compared to yesterday?"

## Implementation Checklist

### Core Files to Modify:
- [ ] `lib/src/models/item_type.dart` - Add TREND enum value
- [ ] `lib/src/core/increment_calculator.dart` - Update display logic, status, and completion
- [ ] `lib/src/views/daily_thing_item.dart` - Add formatting and color handling
- [ ] `lib/src/views/add_edit_daily_item_view.dart` - Add dropdown option and field visibility

### New Files:
- [ ] `lib/src/views/trend_input_dialog.dart` - Three-button input dialog

### Integration:
- [ ] `lib/src/views/daily_things_view.dart` - Add trend dialog integration
- [ ] `lib/src/core/value_converter.dart` - Add trend conversion logic
- [ ] Update project documentation

## Backward Compatibility
- Fully compatible with existing data structure
- No breaking changes to existing types
- Uses same history entry format as other types

## Testing Considerations
- Verify all three states save correctly
- Test color coding (orange for not entered, blue for entered)
- Test conversion to/from other types
- Verify graph view handles trend values appropriately