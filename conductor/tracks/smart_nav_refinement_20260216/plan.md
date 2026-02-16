# Implementation Plan - Smart Navigation Refinement

## Phase 1: Research & Setup
- [x] Task: Identify the controller logic responsible for "Next Item" navigation.
- [x] Task: Locate the existing eligibility checks (active, visible, incomplete, due) in the codebase.
- [x] Task: Conductor - User Manual Verification 'Research & Setup' (Protocol in workflow.md)

## Phase 2: Logic Implementation
- [x] Task: Refactor the navigation logic to filter the item list based on the new eligibility criteria.
- [x] Task: Implement the "Termination Logic" to return to the main list if no eligible items follow.
- [x] Task: Conductor - User Manual Verification 'Logic Implementation' (Protocol in workflow.md)

## Phase 3: Verification & Cleanup
- [x] Task: Verify the "Next" arrow behavior with a mix of archived, hidden, completed, and non-due items.
- [x] Task: Run `flutter analyze` and `flutter test` to ensure no regressions.
- [x] Task: Conductor - User Manual Verification 'Verification & Cleanup' (Protocol in workflow.md)