## Overview
Show the alarm (nagTime) in the expanded item footer so users can quickly see which items need alarm edits.

## What it should do
- Footer row: left = category, centre = start→end+increment, right = alarm icon + HH:mm
- CHECK items: left = category, centre = empty, right = alarm icon + HH:mm
- Only show alarm section when nagTime is not null
- Alarm text and icon in amber to distinguish from other footer text

## Assumptions & uncertainties
- nagTime is DateTime? on DailyThing — confirmed
- Footer is the ExpansionTile children in daily_thing_item.dart
- Colors.amber is visible on the dark theme

## Constraints
- Touch only daily_thing_item.dart and justfile

## How we'll know it's done
- Item with alarm: footer shows category | start→end +inc | 🔔 HH:mm
- Item without alarm: footer shows category | start→end +inc | (empty)
- Alarm section is amber, other text is unchanged

## What's not included
- Editing alarm from the footer
- Showing alarm on collapsed items
