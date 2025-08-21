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

### special case: start date is today or in the future
- If the start date is today or in the future, return the start value
- This applies regardless of history entries
- This allows resetting the progression by changing the start date to today

today value bounds:
- if start < end: never go below startValue (clamp to [startValue, endValue])
- if start > end: never go above startValue (clamp to [endValue, startValue])

increment and decrement are reversed when start value is greater than end value