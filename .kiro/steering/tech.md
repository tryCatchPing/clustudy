---
inclusion: always
---

# Technology Stack & Development Guidelines

## Flutter Framework Requirements

- **Flutter SDK**: 3.32.5 (Dart SDK 3.8.1+) - Use FVM for version management
- **Primary Platform**: iOS with Apple Pencil support
- **Secondary Platforms**: Android, Web (limited functionality)
- **Always use `fvm flutter` commands** instead of direct `flutter` commands

## State Management Architecture

- **Required**: Riverpod 2.6.1 with code generation using `@riverpod` annotations
- **Pattern**: Feature-based modular architecture with providers in `/providers/` directories
- **Code Generation**: Run `fvm flutter packages pub run build_runner build` after modifying providers
- **State Notifiers**: Use for complex state management, simple state can use basic providers

## Critical Dependencies & Usage

### Canvas Implementation

- **scribble**: Custom fork for pressure sensitivity - handle drawing performance at 55+ FPS
- **Material 3**: Use Material Design 3 components and theming

### PDF Integration

- **pdfx 2.5.0**: For PDF rendering - ensure non-blocking UI during processing
- **file_picker 8.0.6**: For file selection interface

### Navigation

- **go_router 16.0.0**: Use declarative routing with feature-based route organization

### File Management

- **path_provider**: Access platform directories for note storage
- **uuid**: Generate unique identifiers for notes and pages

## Essential Commands

### Code Generation Workflow

```bash
# After modifying @riverpod providers, always run:
fvm flutter packages pub run build_runner build

# For continuous development:
fvm flutter packages pub run build_runner watch
```

### Development Commands

```bash
# Standard development workflow:
fvm flutter pub get                    # Install dependencies
fvm flutter run                        # Run app
fvm flutter test                       # Run tests
fvm flutter analyze                    # Static analysis
fvm flutter format .                   # Format code
```

## Code Style Requirements

### Mandatory Conventions

- **Line length**: 80 characters maximum
- **Quotes**: Single quotes for strings
- **Variables**: Use `final` for immutable variables, `const` for compile-time constants
- **Logging**: Use `debugPrint()` instead of `print()`
- **Documentation**: Public APIs must have dartdoc comments

### Import Organization (enforced by linter)

1. Dart SDK imports (`dart:*`)
2. Flutter imports (`package:flutter/*`)
3. Third-party packages (`package:*`)
4. Relative imports (within same feature)
5. Shared module imports

### File Naming

- **Snake case**: `file_name.dart`
- **Suffixes**: `_model.dart`, `_service.dart`, `_provider.dart`, `_page.dart`, `_widget.dart`

## Performance Requirements

### Critical Metrics

- **Canvas rendering**: Maintain 55+ FPS during drawing operations
- **Memory efficiency**: 1000 strokes must use < 5MB storage
- **Startup time**: < 3 seconds on target devices
- **UI responsiveness**: File operations must not block UI thread

### Implementation Guidelines

- Use `async`/`await` for file operations
- Implement proper canvas optimization for smooth drawing
- Cache thumbnails and pre-rendered pages for performance
- Use efficient data structures for stroke storage

## Platform-Specific Implementation

### iOS (Primary Target)

- **Apple Pencil**: Implement pressure sensitivity support
- **Compatibility**: iOS 12+ minimum
- **Performance**: Optimize for iPad drawing experience

### Android & Web

- **Android**: Basic stylus support where available
- **Web**: Limited canvas performance, demonstration purposes only
- **File Access**: Handle platform-specific file system restrictions

## Architecture Patterns

### Provider Pattern

```dart
@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  @override
  ExampleState build() => ExampleState.initial();

  // State management methods
}
```

### Repository Pattern

- Implement data repositories in `/data/` directories
- Use dependency injection through Riverpod providers
- Separate business logic from UI components

### Feature Organization

- Each feature in `/lib/features/` is self-contained
- Shared utilities in `/lib/shared/`
- Follow consistent directory structure across features
