# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure
- Flutter clinic appointment system using clean architecture
- Features organized in /lib/features/ with data, domain, presentation layers
- Core utilities in /lib/core/ including UI components, navigation, error handling

## Commands
- Build: `flutter build [platform]`
- Run: `flutter run`
- Format code: `flutter format lib/`
- Lint: `flutter analyze`
- Generate code: `flutter pub run build_runner build --delete-conflicting-outputs`
- Run tests: `flutter test` (or specific test: `flutter test path/to/test.dart`)

## Code Style Guidelines
- Follow Flutter/Dart style conventions (enforced by flutter_lints)
- File naming: snake_case (e.g., appointment_service.dart)
- Classes: PascalCase, variables/methods: camelCase
- Riverpod for state management with code generation (@riverpod annotations)
- Use Result<T> for error handling from core/utils/result.dart
- Structure screens with BaseScreen from core/ui/base_screen.dart
- Organize imports: dart:core first, then packages, then relative imports