# Plan — History add-row: Target must match today's target

Read `spec.md` in this directory first. It contains the worked 20-vs-1 example
and the verified facts this plan depends on.

## Architecture Decisions

- **No new calculation.** `DailyThing.todayValue` (`lib/src/models/daily_thing.dart:75`)
  already delegates to `IncrementCalculator.calculateTodayValue` and is what the
  main daily list renders. The history view calls it directly. A wrapper helper
  was considered and rejected as reinventing an existing getter.
- **`valueForDate` is deleted, not kept "just in case".** Once the date-change
  auto-fill goes, it has zero callers. Leaving a dead public static invites the
  same mistake again.
- **The add-row stays.** Folding it into the normal entry rows would delete far
  more code, but existing rows have a read-only date and backdating must remain
  possible. See "Rejected alternative" in the spec.
- ~~**Done copies a parsed number, not display text.**~~ **WITHDRAWN AFTER
  REVIEW.** The rationale was inverted — the verbatim string copy is the
  lossless one. See Phase 5. The Done handler is unchanged by this thread.
- **Test is a widget test.** The defect lives in the view's wiring, not in the
  calculator — a calculator unit test cannot catch it. `testWidgets` is already
  used in `test/widget_test.dart` and `DataManager()` has no constructor side
  effects, so `HistoryView` can be pumped without storage mocking.

## Phase 1: Reproduce the bug with a failing test

- [x] Create `test/history_add_row_target_test.dart`. Build a `DailyThing` with
      `itemType: ItemType.minutes`, `startValue: 1`, `endValue: 20`,
      `duration: 66`, `startDate` = 200 days before today, and a single
      `HistoryEntry` dated 10 days ago with `targetValue: 5.0`,
      `doneToday: false`. Call `IncrementCalculator.setGracePeriod(1)` in
      `setUp` — it is static global state and must not be inherited from
      another test file.
      → verify: `flutter test --no-pub test/history_add_row_target_test.dart`
      compiles and the fixture builds; assert
      `IncrementCalculator.valueForDate(item, DateTime.now())` is `20` and
      `item.todayValue` is `1`, proving the two calculations diverge as the
      spec's worked example claims. Paste the actual printed values into this
      file under the task.

      RESULT: `valueForDate=20.0 todayValue=1.0` — divergence confirmed, test passed.

- [x] In the same file, add a `testWidgets` case: pump
      `MaterialApp(home: HistoryView(item: item, onHistoryUpdated: () {}))`,
      tap the `Icons.add` in the `AppBar`, `pumpAndSettle`, then read the
      add-row's Target field. The add-row is the first `DataRow`, so its four
      `TextFormField`s are indices 0–3 of `find.byType(TextFormField)` —
      date 0, target 1, actual 2, comment 3. Assert the target field's
      controller text equals `NumberFormat('0.##').format(item.todayValue)`
      i.e. `'1'`.
      → verify: run `flutter test --no-pub test/history_add_row_target_test.dart`.
      This test MUST FAIL, reporting `'20'` where `'1'` was expected. Paste the
      actual failure output into this file under this task before starting
      Phase 2. If it fails for any other reason (widget not found, index wrong,
      exception), fix the test until it fails for the right reason.

      RESULT — failed for the right reason:
      ```
      add-row Target pre-fills with today's real target [E]
      Expected: '1'
        Actual: '20'
      history_add_row_target_test.dart line 74
      ```

- [x] Add a second `testWidgets` case in the same file: after tapping `+`,
      tap the add-row's `Checkbox` (the first `Checkbox` in the tree), then
      assert the Actual field (index 2) reads the same string as the Target
      field (index 1).
      → verify: run the file. This test fails too, showing both fields holding
      `'20'` rather than `'1'`. Paste the output. (It fails on the value, not
      the copy mechanism — the copy itself works today.)

      RESULT — failed for the right reason:
      ```
      ticking Done copies Target into Actual [E]
      Expected: '1'
        Actual: '20'
      history_add_row_target_test.dart line 96
      ```

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: `flutter test --no-pub` — the three new assertions fail as
      described, every pre-existing test still passes.

      RESULT: baseline before this thread was `95` tests, all passing (recorded
      at the BASELINE GATE). The two new widget tests fail as designed; the
      divergence unit test passes. No pre-existing failures.

## Phase 2: Point the add-row at today's real target

- [x] In `lib/src/views/history_view.dart` `initState` (~line 53), replace
      `IncrementCalculator.valueForDate(widget.item, DateTime.now())` with
      `widget.item.todayValue`.
      → verify: `flutter analyze` clean; the first `testWidgets` case now passes.

- [x] In `_startAddingEntry` (~line 181), make the same replacement.
      → verify: `flutter test --no-pub test/history_add_row_target_test.dart` —
      the Target assertion passes. Paste the passing output.

      RESULT:
      ```
      +0: projection and today value diverge for an item past its ramp
      valueForDate=20.0 todayValue=1.0
      +1: add-row Target pre-fills with today's real target
      +2: ticking Done copies Target into Actual
      +3: All tests passed!
      ```

- [x] Delete the `_maybeAutoFillTarget` method (~lines 116–132), the
      `_lastAutoFilledTarget` field declaration (~line 37) and its two remaining
      assignments, and the `_maybeAutoFillTarget(_newDateController.text);` line
      inside the date-controller listener in `initState`. Leave the
      `_validateDate(_newDateController.text);` call in that listener — it does
      the duplicate-date check and is unrelated.
      → verify: `flutter analyze` reports no unused field and no undefined
      method; `flutter test --no-pub` passes.

- [x] DRIFT — unplanned but required. Removing the last `IncrementCalculator`
      call from the view left `import '.../increment_calculator.dart';` unused
      at `history_view.dart:7`, which `flutter analyze` reports as a warning.
      Deleted the import.
      → verify: `flutter analyze` — the unused_import warning is gone.

- [x] REVERTED IN PHASE 5 — this task was completed, then undone in review.
      Its premise was wrong; the Done handler now stands as it was before the
      thread. Kept here for the record, not as work still standing.
      In the add-row's Done `Checkbox` `onChanged` (~line 470), replace
      `_newActualValueController.text = _newTargetValueController.text;` with a
      parse-then-format: read `double.tryParse(_newTargetValueController.text)`
      and, when non-null, write `_numberFormat.format(parsed)` into
      `_newActualValueController`. When the parse fails, leave Actual untouched
      rather than copying junk.
      → verify: the Done `testWidgets` case passes. Additionally confirm by
      inspection that a target of `12.345` no longer round-trips through the
      formatter twice.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: `flutter test --no-pub` — all three new cases pass, no
      pre-existing test regressed.

      RESULT: `98` tests, all passed (95 baseline + 3 new). `flutter analyze`
      reports one issue, pre-existing and untouched:
      `'onReorder' is deprecated • lib/src/views/daily_things_view.dart:1264`

## Phase 3: Remove the dead code

- [x] Delete `IncrementCalculator.valueForDate`
      (`lib/src/core/increment_calculator.dart`, the method and its doc comment,
      ~lines 118–147). Before deleting, re-run
      `rg --hidden 'valueForDate' lib/ test/` and confirm the only remaining
      hits are the Phase 1 divergence assertion.
      → verify: paste the `rg` output. Then remove that divergence assertion
      from the test file too — it only existed to prove the bug and cannot
      survive the deletion. `flutter analyze` clean.

      RESULT — `rg --hidden -n 'valueForDate' lib/ test/` before deleting:
      ```
      test/history_add_row_target_test.dart:56:        IncrementCalculator.valueForDate(item, DateTime.now());
      test/history_add_row_target_test.dart:58:    print('valueForDate=$projected todayValue=${item.todayValue}');
      lib/src/core/increment_calculator.dart:125:  static double valueForDate(DailyThing item, DateTime date) {
      ```
      Only the Phase 1 divergence assertion, as predicted.

      DRIFT — the plan said to remove that assertion outright. Instead it was
      replaced with a one-line guard asserting the fixture's `todayValue` is
      `1.0`. Rationale: the fixture is only meaningful because its projection
      (20.0) is far from its real target (1.0); without a guard, a future edit
      to the fixture could make the two coincide and the widget tests would
      pass vacuously. The guard costs one line and cannot reference the deleted
      function.

- [x] Delete `lib/src/views/widgets/add_history_entry_dialog.dart`. Before
      deleting, re-run `rg --hidden 'AddHistoryEntryDialog|add_history_entry_dialog' lib/ test/`
      and confirm the only hits are inside the file itself.
      → verify: paste the `rg` output, then `flutter analyze` — clean, no
      unresolved import anywhere.

      RESULT — `rg --hidden -n 'AddHistoryEntryDialog|add_history_entry_dialog' lib/ test/`
      before deleting returned four hits, all inside the file itself (lines
      7, 11, 18, 21). Nothing external referenced it.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: `flutter test --no-pub` passes and `flutter analyze` is clean.
      Check `git status` for an unexpected `analysis_options.yaml` rewrite (see
      CLAUDE.md — the analyzer edits it by itself on a fresh clone).

      RESULT: `98` tests, all passed. `flutter analyze` reports only the
      pre-existing `onReorder` deprecation. `git status` shows no
      `analysis_options.yaml` change — the tree holds exactly two modified
      files, one deletion, and the new test file.

## Phase 4: Confirm on a real device

- [ ] Build and install with `just update`. Never `adb uninstall` or `pm clear`
      — that wipes user data.
      → verify: the app launches and the daily list renders.

- [ ] Pick an item whose main-list target is **not** its end value — ideally one
      with missed days or a pause, so the old projection would have shown
      something obviously different. Write down the target shown on the main
      list.
      → verify: the noted number is recorded in this file.

- [ ] Open that item's history, tap `+`.
      → verify: the Target field shows exactly the number noted in the previous
      task. Record both numbers here.

- [ ] Tick the Done checkbox in the add-row.
      → verify: the Actual field fills with the same number as Target.

- [ ] Type a past date into the add-row's date field.
      → verify: the Target field does **not** change — backdating is now a
      manual edit, as the spec intends. The duplicate-date red highlight still
      appears if that date already has an entry.

- [ ] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: save the new entry, reopen the history, and confirm the entry
      persisted with the expected target and actual values.

## Phase 5: Review (added after review — not in the original plan)

Two reviews ran in parallel: `coderabbit review --agent --uncommitted
--include-untracked` (0 findings across all six files) and an independent
adversarial audit that re-verified every factual claim in this thread's spec
and plan against the code, including a revert-and-retest coverage proof.

- [x] REVERTED — the Done-handler parse-then-format change.
      The audit proved the spec's justification was inverted. The original
      `_newActualValueController.text = _newTargetValueController.text;` copies
      the string verbatim, so a hand-typed `12.345` reaches Actual intact. The
      replacement parsed and re-formatted through `NumberFormat('0.##')`,
      rounding it to `12.35`; `_saveNewEntry` parses the controller text as the
      saved value, so the rounding would have persisted to disk. The two paths
      are byte-identical for a pre-filled target, so the change could only ever
      differ where it made things worse.
      → verify: `flutter test --no-pub` — 98 pass; the handler is back to its
      original two lines.

- [x] COVERAGE PROOF — recorded from the audit's revert-and-retest pass.
      Reverting both prefill call sites (restoring `valueForDate`, its two
      callers and the import): **2 of 3 tests fail**. The core fix is genuinely
      guarded. Reverting only the Done handler: **3 of 3 pass** — that change
      was never guarded, which is part of why it is gone. The audit confirmed
      the tree was restored byte-identically (md5) with no git commands used.

- [x] Hardened the widget tests against the index-based `TextFormField` lookup.
      Added `expect(find.byIcon(Icons.close), findsOneWidget)` after tapping `+`
      in both cases. Without it, a fixture entry carrying an `actualValue` would
      let the tests pass even if the add-row never rendered.
      → verify: `flutter test --no-pub` — 98 pass.

- [x] Removed the stale `add_history_entry_dialog.dart` section from
      `docs/project_map.md:308-309`. The spec's "referenced by nothing" sweep
      was scoped to `lib/` and `test/` and missed `docs/`.
      → verify: `rg --hidden 'add_history_entry_dialog'` over the repo returns
      only this thread's own files.

- [x] Corrected three inaccurate claims in `spec.md`: the inverted precision
      rationale, the assertion that the main list renders `todayValue` (it
      renders `displayValue`, which agrees here for a structural reason worth
      stating), and the `1.0 / 0.0 for check` bullet (that branch never reaches
      the pre-fill).

- [x] RESOLVED — backdating pre-filled today's target into a historical row.
      The user chose to blank the field; implemented in Phase 6.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: `flutter analyze` — only the pre-existing `onReorder`
      deprecation. `flutter test --no-pub` — 98 tests, all pass.

## Phase 6: Blank Target for backdated rows (user decision after review)

- [x] Add `_syncTargetToDate` to the date-controller listener. Clears the Target
      field when the parsed date is not today; restores `widget.item.todayValue`
      when it returns to today. Acts only on the today/not-today flip, tracked by
      the new `_targetIsForToday` field, so a hand-typed target is not clobbered
      by further date edits. `_startAddingEntry` resets the flag.
      → verify: `flutter test --no-pub` — 100 tests, all pass.

- [x] Two new widget tests: a past date blanks Target and returning to today
      restores it; a hand-typed Target survives further date editing.
      → verify: COVERAGE PROOF — removing the `_syncTargetToDate(...)` call and
      re-running fails **1 of 5** tests in the file (the blanking test). The
      clobber test passes without the feature by design: it guards the
      implementation, not the feature's presence. The file was backed up, edited
      via a scripted rewrite, and restored in the same command; `md5sum -c`
      confirmed byte-identical restoration. No git commands used.

- [x] PHASE COMPLETE: verify all tasks done and no regressions introduced
      → verify: `flutter analyze` — only the pre-existing `onReorder`
      deprecation. `flutter test --no-pub` — `100` tests, all pass (95 baseline
      + 5 new).
