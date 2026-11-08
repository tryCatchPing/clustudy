---
inclusion: always
---

# Technology Stack & Development Guidelines

## Critical Commands & Setup

**ALWAYS use FVM**: `fvm flutter` instead of `flutter` commands
**Flutter SDK**: 3.32.5 (Dart SDK 3.8.1+)
**After modifying @riverpod providers**: `fvm flutter packages pub run build_runner build`

## State Management (MANDATORY)

- **Riverpod 2.6.1** with `@riverpod` code generation annotations
- **Pattern**: Feature-based providers in `/providers/` directories
- **Template**:

```dart
@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  @override
  ExampleState build() => ExampleState.initial();
}
```

## Key Dependencies & Usage

- **scribble**: Custom fork for Apple Pencil pressure sensitivity (55+ FPS requirement)
- **pdfx 2.5.0**: PDF rendering (non-blocking UI operations)
- **go_router 16.0.0**: Declarative routing with feature-based organization
- **Material 3**: Required design system
- **path_provider**: Platform directories for note storage
- **uuid**: Unique identifiers for notes/pages

## Code Style (ENFORCED)

- **Line length**: 80 characters max
- **Strings**: Single quotes only
- **Variables**: `final` for immutable, `const` for compile-time constants
- **Logging**: `debugPrint()` never `print()`
- **File naming**: Snake case with suffixes (`_model.dart`, `_service.dart`, `_provider.dart`, `_page.dart`, `_widget.dart`)

## Import Order (STRICT)

1. `dart:*` (SDK)
2. `package:flutter/*` (Framework)
3. `package:*` (Third-party)
4. Relative imports (same feature)
5. `../../shared/` imports

## Performance Requirements

- **Canvas**: 55+ FPS drawing performance
- **Memory**: 1000 strokes < 5MB storage
- **Startup**: < 3 seconds
- **File operations**: Always async, never block UI

## Platform Priorities

- **Primary**: iOS with Apple Pencil support (iOS 12+)
- **Secondary**: Android (basic stylus), Web (demo only)

## Architecture Rules

- **Features**: Self-contained in `/lib/features/`
- **Shared**: Cross-feature utilities only
- **Data access**: Through repositories in `/data/` directories
- **Dependency injection**: Via Riverpod providers
- **UI separation**: No direct business logic in widgets
