## Architecture Decisions
- 3-column Row: left Expanded (category), centre Row min-size (values), right Expanded (alarm)
- Alarm right-aligned inside its Expanded using MainAxisAlignment.end
- No new widgets — inline in daily_thing_item.dart footer

## Phase 1

- [x] Restructure non-check footer row: left=category, centre=start→end+increment, right=alarm+time
  → verify: dart analyze passes; item with alarm shows 3-column layout

- [x] Restructure check footer row: left=category, centre=spacer, right=alarm+time
  → verify: dart analyze passes

- [x] Add android-install-debug recipe to justfile
  → verify: recipe present in justfile
