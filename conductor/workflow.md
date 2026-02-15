# Development Workflow

## Principles
- **No Automated Commits:** The agent MUST NOT perform git commits. All committing is handled manually by the user.
- **Focus on Critical Testing:** Tests are required for core logic, especially progression calculations and notification scheduling.
- **Task Verification:** Every task must be verified by the agent before being marked complete.

## Task Execution Protocol
1. **Understand:** Read the `spec.md` and current code.
2. **Plan:** Outline the changes.
3. **Implement:** Write the code.
4. **Test:** Run `flutter test` and `flutter analyze`.
5. **Verify:** Confirm with the user that the requirement is met.

## Phase Completion Verification
At the end of each phase, the agent will prompt the user for manual verification.
- Meta-task: `- [ ] Task: Conductor - User Manual Verification '<Phase Name>'`
