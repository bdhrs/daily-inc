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
- Keep this file updated as changes get made
