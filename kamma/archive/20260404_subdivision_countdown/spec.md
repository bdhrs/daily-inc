---
## Overview
Fix the top-right subdivision timer in the countdown timer view so it counts down instead of up.

## What it should do
The top-right timer in the SubdivisionDisplayWidget should show remaining time in the current subdivision, counting down toward 0:00, rather than elapsed time counting up from 0:00.

## Constraints
- Only change the display logic, not any timing/state logic.
- The `/ total` portion of the display should remain so the user can see context.

## How we'll know it's done
When the timer is running with subdivisions, the top-right value starts at the subdivision duration and counts down to 0:00.

## What's not included
- Overtime display (separate code path)
- Stopwatch mode
- Any other UI changes
