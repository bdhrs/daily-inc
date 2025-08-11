# Intervals

Intervals determine how frequently a task is due. The type of interval is set automatically based on the input provided in the Add/Edit screen.

## Setting Intervals

The Add/Edit screen uses a unified widget to set the interval. First, the user chooses the type of interval:

-   **By Days:** The task repeats every `x` days.
-   **By Weekday:** The task repeats on specific days of the week.

Based on the selection, the appropriate controls are shown.

### Default Behavior

-   If no interval is specified, the task defaults to repeating **every 1 day**.
-   If "By Weekdays" is chosen but no days are selected, it also defaults to **every 1 day**.

## Interval by Days Logic

-   Set by entering a number `x` in the "Frequency (days)" field.
-   The item becomes due `x` days after the last completed date.
-   If a due day is missed, the task carries over and remains due on subsequent days until completed.

## Interval by Weekdays Logic

-   Set by selecting one or more days in the weekday selector.
-   The item is due on every selected weekday.
-   This is independent of when the task was last completed.
-   If a due day is missed, the task carries over and remains due on subsequent days until completed.
