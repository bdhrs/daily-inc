# Instructions for AI coding agents

## AGENTS.md

- you MUST always read this file docs/AGENTS.md and follow all instructions precisely.

## Conductor Directory

All project information is contained in the `conductor/` directory:

| File | When Useful |
|------|-------------|
| `conductor/product.md` | Product vision, goals, and key features |
| `conductor/product-guidelines.md` | Tone, visual identity, notification behavior, UX principles |
| `conductor/tech-stack.md` | Frameworks, packages, and dependencies used |

- you MUST update `conductor/tech-stack.md` if dependencies or technical architecture changes.
- you MUST update `conductor/product.md` if features or product vision changes.

## project_map.md
- you MUST always read docs/project_map.md to understand the context of the project.
- you MUST always update docs/project_map.md if there are any code changes.

## Dependencies
- you MUST add or delete dependencies to `pubspec.yaml`
- you MUST then run `flutter pub get` to update the dependencies 

## Reading files
- you MUST always read the whole file to get the whole context
- you MUST NEVER read files in chunks, otherwise you miss the bigger context

## Building and Running
- you MUST NEVER run the project with `flutter run`, the user will take care of that
- you MUST NEVER build the project with `flutter build`, the user will take care of that

## Testing, Analysis & Auto-formatting
- you MUST run `flutter analyze` after completing a coding task to check for syntax errors
- you MUST run `flutter test` after completing a coding task to check for breaking changes
- you MUST run `dart format lib` after completing a coding task to auto-format all Dart files


## Coding conventions
- you MUST follow the existing code style and conventions when making changes.
- you MUST follow follow Material Design principles and existing app styling when adding UI elements 

## Searching
- you MUST always use grep to search within the project.
- you MUST NEVER use SearchText, it frequently fails.

## Edits
- you MUST always edit the whole code block. Edits within code blocks frequently fail. 
- If the edit fails repeatedly, you MUST **REWRITE THE WHOLE FILE** in one go.

## Completion
- After completing any task, you MUST follow these instructions
1. you MUST ask the user if they are happy with the changes and have tested them
2. you MUST NEVER run `git commit` or any git command that modifies the repository state.


## Gemini CLI
- If today is Sunday, you MUST run `npm install -g @google/gemini-cli@latest` to update to the latest version.
