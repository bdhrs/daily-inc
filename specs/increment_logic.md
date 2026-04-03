## ItemType: MINUTES and REPS
### when start value is less than end value

how many days since doneToday?
if 0
    already done today
if 1
    increment by increment value
if 2
    no change
if 3 or more
    decrement by increment x (days - 1)

### configurable grace period
- The default grace period is 1 day, which matches the base rule above:
  - `daysSinceDone == 2` means one missed day and no change
  - `daysSinceDone >= 3` applies the penalty
- Setting grace period to `0` removes the buffer and applies the penalty on the first missed day.
- Setting grace period to `2` allows two missed days with no change for normal daily items.
- Exception: for `byDays` interval items, if `daysSinceDone == intervalValue`, the value increments on that exact due day even when it falls inside the grace-period branch.
- When the grace period is exceeded, the penalty still uses the full `daysSinceDone - 1` calculation; the grace period delays when the penalty starts, but does not reduce its size.

### special case: start date is today or in the future
- If the start date is today or in the future, return the start value
- This applies regardless of history entries
- This allows resetting the progression by changing the start date to today

today value bounds:
- if start < end: never go below startValue (clamp to [startValue, endValue])
- if start > end: never go above startValue (clamp to [endValue, startValue])

increment and decrement are reversed when start value is greater than end value
