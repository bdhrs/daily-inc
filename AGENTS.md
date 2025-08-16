# Build/Lint/Test Commands
- Build: `flutter build apk` (Android), `flutter build linux` (Linux)
- Test: `flutter test` (all tests), `flutter test test/widget_test.dart` (single test)
- Lint: `flutter analyze`
- Format: `flutter format .`

# Code Style Guidelines
- Use `flutter_lints` recommended rules from analysis_options.yaml
- Import order: dart, flutter, package, local (src/)
- Use const constructors where possible
- Prefer single quotes for strings
- Use null safety features consistently
- Logging: Use `logging` package with Logger instances
- Error handling: Use try-catch with logging for async operations
- Naming: camelCase for variables/functions, PascalCase for classes/types

# Project Map
- A map of the project can be found in `project_map.md`. 
- Read the project map to see where things are.
- Keep this file updated as changes get made


# Competition
- After completing any task, give a one line, lowercase, simple git commit message. DO NOT COMMIT, allow the user to handle that.

# `apply_diff` Tool Rules
1.  **Read First, Then Write**: Before every `apply_diff` attempt, I **must** use the `<read_file>` tool to get the most up-to-date and exact content of the target file.
2.  **`start_line` is gospel**: The `<start_line>` number must correspond to the exact line number in the file where the `SEARCH` block begins.
3.  **The `content` block is sacred**:
    *   The `<content>` parameter must **only** contain the text inside the `<![CDATA[...]]>` wrapper.
    *   This text must start with `<<<<<<< SEARCH`, have one `=======` separator, and end with `>>>>>>> REPLACE`.
    *   No other text, parameters, or comments should be inside the `CDATA` block.
4.  **Whitespace is Everything**: The text in the `SEARCH` block must match the file content character-for-character, including spaces, tabs, and newlines.
