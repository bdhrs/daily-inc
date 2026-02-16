# Specification - Smart Navigation Refinement

## Overview
Refine the "Next Item" navigation logic (right arrow) in the timer view to ensure it only navigates to items that are currently visible and actionable in the main list.

## Functional Requirements
1. **Eligibility Criteria:** An item is only eligible for "Next" navigation if it meets ALL of the following:
    - **Active:** Not archived.
    - **Visible:** Not hidden.
    - **Incomplete:** The daily target has not yet been reached.
    - **Due:** The item is scheduled for today (respects daily/weekday intervals).
2. **Termination Logic:** If no more eligible items exist in the sequence after the current item, clicking the "Next" arrow must exit the timer view and return the user to the main list.

## Acceptance Criteria
- [ ] Clicking the "Next" arrow never navigates to a hidden or archived item.
- [ ] Clicking the "Next" arrow never navigates to an item that is already completed for the day.
- [ ] Clicking the "Next" arrow never navigates to an item that is not due today.
- [ ] If the current item is the last eligible item in the list, the "Next" arrow navigates back to the main list.

## Out of Scope
- Implementation of a "Previous" arrow.
- Changes to the main list filtering logic itself (this track consumes existing eligibility logic).