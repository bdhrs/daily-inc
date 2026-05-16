# Plan — Sequence Expanded View Adaptations

## Architecture Decisions
- Keep all UI logic in `daily_thing_item.dart`. The conditional rendering is
  small and localised; adding a separate widget would be premature abstraction.
- Add one tiny helper to `sequence_helper.dart` that returns the summed
  (start, end, increment) for MINUTES children. Keeps the widget readable.
- Replace `(widget.item.category).isNotEmpty` with `hasCategory` =
  `category.isNotEmpty && category != 'None'`. No new constant.

## Phase 1 — Helper for child sums

- [ ] Add `static ({double start, double end, double increment, int count}) sumMinutesChildren(DailyThing seq, List<DailyThing> allItems)` to `SequenceHelper`.
  Iterates `resolveChildren`, filters `itemType == ItemType.minutes`, sums each field, returns count too so caller can decide visibility.
  → verify: `flutter analyze` has no new errors.

## Phase 2 — UI changes in daily_thing_item.dart

- [ ] At top of `build`, compute `final hasCategory = widget.item.category.isNotEmpty && widget.item.category != 'None';`.
  → verify: read diff, single source of truth.

- [ ] In the action-button row (around lines 492-545), wrap edit-history, edit-note, and pause/resume IconButtons (with their trailing `SizedBox(width:4)` spacers) in `if (!isSequenceTile) ...[ ... ]`.
  → verify: expanding a sequence shows only graph, edit, duplicate, archive, delete.

- [ ] Replace the outer guard at line 599 with: `if (isSequenceTile || hasCategory || (widget.item.notificationEnabled && widget.item.nagTime != null)) ...[ <bottom row> ]`.
  → verify: a CHECK item with no category and no alarm renders no bottom row.

- [ ] In the bottom row's left column, render category text only when `hasCategory`; otherwise `const SizedBox.shrink()` inside the `Expanded`.
  → verify: any item with category 'None' shows blank left column.

- [ ] Restructure centre cluster as:
  - `if (isSequenceTile)` → compute sums via `SequenceHelper.sumMinutesChildren`. If `count > 0`, render start → end + increment using `TimeConverter.toMmSsString` for all three (with sign on increment); else `SizedBox.shrink()`.
  - `else if (widget.item.itemType != ItemType.check)` → existing `_formatValue` cluster unchanged.
  - `else` → blank centre (existing CHECK behaviour: `Spacer()`).
  → verify: sequence with children 1→5 step 0:30 and 2→10 step 1:00 shows `03:00 → 15:00  +01:30`.

- [ ] Keep right (alarm) column logic unchanged across all branches.
  → verify: an item with alarm still shows it.

→ phase verify: `flutter test --no-pub` passes; `flutter analyze` no new warnings.

## Phase 3 — Manual UX check

- [ ] User builds and launches the app; expand a sequence, a non-sequence MINUTES item, and a CHECK item.
  → verify: matches spec.
