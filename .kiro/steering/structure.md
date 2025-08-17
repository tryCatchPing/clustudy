---
inclusion: always
---

# Project Structure & Architecture Guidelines

## Core Architecture Rules

**Feature-based modular architecture** - Each feature is self-contained with clear boundaries:

- Features: `canvas/`, `home/`, `notes/` - domain-driven modules
- Shared: Cross-feature utilities in `shared/` directory
- State: Riverpod providers with `@riverpod` code generation
- Navigation: GoRouter with feature-specific routing

## Directory Structure Requirements

```
lib/
├── features/{feature_name}/
│   ├── data/                    # Repositories & data sources
│   ├── models/                  # Domain entities
│   ├── pages/                   # UI screens
│   ├── providers/               # Riverpod providers
│   ├── routing/                 # Route definitions
│   └── widgets/                 # Feature-specific components
└── shared/
    ├── constants/               # App-wide constants
    ├── services/                # Business logic services
    └── widgets/                 # Reusable UI components
```

## File Naming Conventions

**REQUIRED suffixes for clarity:**

- `_model.dart` - Data models
- `_service.dart` - Business logic services
- `_repository.dart` - Data repositories
- `_provider.dart` - Riverpod providers
- `_notifier.dart` - State notifiers
- `_page.dart` - Screen widgets
- `_widget.dart` - UI components

**Directory naming:** Snake case, plural for collections (`models/`, `services/`)

## Import Organization (Enforced by Linter)

1. `dart:*` imports
2. `package:flutter/*` imports
3. `package:*` third-party imports
4. Relative imports (same feature)
5. `shared/` module imports

**Style rules:**

- Relative imports within same feature
- Absolute imports for shared modules
- Avoid `show`/`hide` unless necessary

## Architecture Patterns

### Dependency Direction

- Features → Shared modules ✓
- Shared → Features ✗
- UI → Business logic ✓
- Business logic → UI ✗

### State Management Pattern

```dart
@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  @override
  ExampleState build() => ExampleState.initial();
  // Implementation
}
```

### Repository Pattern

- Interfaces in `/data/` directories
- Dependency injection via Riverpod
- Separate business logic from UI

## Key Services (Shared Module)

- `FileStorageService` - File system operations
- `NoteService` - Cross-feature note operations
- `PdfProcessor` - PDF handling
- `NoteDeletionService` - Cleanup operations

## File Storage Structure

```
/Application Documents/notes/{noteId}/
├── source.pdf              # Original PDF
├── pages/                  # Pre-rendered images
├── thumbnails/             # Cached thumbnails
└── metadata.json           # Note metadata
```

Managed by `FileStorageService` for efficient organization and caching.
