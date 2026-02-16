# Implementation Plan - Smart Navigation Refinement

## Phase 1: Research & Setup
- [ ] Task: Identify the controller logic responsible for "Next Item" navigation.
- [ ] Task: Locate the existing eligibility checks (active, visible, incomplete, due) in the codebase.
- [ ] Task: Conductor - User Manual Verification 'Research & Setup' (Protocol in workflow.md)

## Phase 2: Logic Implementation
- [ ] Task: Refactor the navigation logic to filter the item list based on the new eligibility criteria.
- [ ] Task: Implement the "Termination Logic" to return to the main list if no eligible items follow.
- [ ] Task: Conductor - User Manual Verification 'Logic Implementation' (Protocol in workflow.md)

## Phase 3: Verification & Cleanup
- [ ] Task: Verify the "Next" arrow behavior with a mix of archived, hidden, completed, and non-due items.
- [ ] Task: Run `flutter analyze` and `flutter test` to ensure no regressions.
- [ ] Task: Conductor - User Manual Verification 'Verification & Cleanup' (Protocol in workflow.md)