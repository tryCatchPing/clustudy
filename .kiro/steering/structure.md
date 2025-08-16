# Project Structure & Organization

## Architecture Pattern

**Feature-based modular architecture** with clear separation of concerns:

- Each feature is self-contained with its own routing, pages, models, and business logic
- Shared utilities and services are centralized in the `shared/` directory
- Riverpod providers handle state management and dependency injection

## Directory Structure

```
lib/
├── main.dart                    # App entry point with router configuration
├── features/                    # Feature modules (domain-driven)
│   ├── canvas/                  # Drawing and canvas functionality
│   │   ├── constants/           # Canvas-specific constants
│   │   ├── models/              # Canvas data models
│   │   ├── notifiers/           # Riverpod state notifiers
│   │   ├── pages/               # Canvas UI screens
│   │   ├── providers/           # Riverpod providers
│   │   ├── routing/             # Canvas route definitions
│   │   └── widgets/             # Canvas-specific widgets
│   ├── home/                    # Home screen and navigation
│   │   ├── pages/               # Home UI screens
│   │   └── routing/             # Home route definitions
│   └── notes/                   # Note management functionality
│       ├── data/                # Repository implementations
│       ├── models/              # Note data models
│       ├── pages/               # Note UI screens
│       └── routing/             # Note route definitions
└── shared/                      # Cross-feature shared code
    ├── constants/               # App-wide constants (breakpoints, etc.)
    ├── routing/                 # Shared routing utilities
    ├── services/                # Business logic services
    └── widgets/                 # Reusable UI components
```

## Feature Module Organization

Each feature follows a consistent internal structure:

### `/models/` - Data Models

- Domain entities and data transfer objects
- Immutable classes with proper equality and serialization
- Example: `NoteModel`, `NotePageModel`, `ThumbnailMetadata`

### `/data/` - Data Layer

- Repository interfaces and implementations
- Data source abstractions (local storage, API, etc.)
- Example: `NotesRepository`, `MemoryNotesRepository`

### `/providers/` - State Management

- Riverpod providers for dependency injection
- State notifiers for complex state management
- Generated providers using `riverpod_generator`

### `/pages/` - UI Screens

- Top-level screen widgets
- Route-specific UI logic
- Integration with providers for state management

### `/widgets/` - Feature Components

- Reusable widgets specific to the feature
- Complex UI components that don't belong in shared/
- Feature-specific custom widgets

### `/routing/` - Navigation

- Route definitions using GoRouter
- Route parameters and navigation logic
- Feature-specific route guards or middleware

## Shared Module Organization

### `/services/` - Business Logic

Core business services that multiple features depend on:

- `FileStorageService` - File system operations and storage management
- `NoteService` - Cross-feature note operations
- `PdfProcessor` - PDF handling and processing
- `NoteDeletionService` - Cleanup and deletion logic

### `/widgets/` - Reusable Components

UI components used across multiple features:

- `AppBrandingHeader` - Consistent app branding
- `InfoCard` - Information display component
- `NavigationCard` - Navigation UI elements

### `/constants/` - App Constants

- `Breakpoints` - Responsive design breakpoints
- Theme constants and design tokens
- App-wide configuration values

## File Naming Conventions

### Dart Files

- **Snake case**: `file_name.dart`
- **Descriptive suffixes**:
  - `_model.dart` for data models
  - `_service.dart` for business logic services
  - `_repository.dart` for data repositories
  - `_provider.dart` for Riverpod providers
  - `_notifier.dart` for state notifiers
  - `_page.dart` for screen widgets
  - `_widget.dart` for reusable components

### Directories

- **Snake case**: `directory_name/`
- **Plural for collections**: `models/`, `services/`, `widgets/`
- **Singular for single purpose**: `routing/`, `data/`

## Import Organization

### Import Order (enforced by linter)

1. Dart SDK imports (`dart:*`)
2. Flutter framework imports (`package:flutter/*`)
3. Third-party package imports (`package:*`)
4. Relative imports (same feature)
5. Shared module imports

### Import Style

- **Relative imports** for files within the same feature
- **Absolute imports** for shared modules and external packages
- **Explicit imports** - avoid `show` and `hide` unless necessary

## Code Organization Principles

### Single Responsibility

- Each file has one primary purpose
- Classes and functions do one thing well
- Clear separation between UI, business logic, and data

### Dependency Direction

- Features can depend on shared modules
- Shared modules should not depend on specific features
- UI depends on business logic, not the reverse

### Testability

- Business logic separated from UI
- Repository pattern for data access
- Dependency injection through Riverpod providers

## File Storage Structure

The app maintains a structured file system for note storage:

```
/Application Documents/
├── notes/
│   ├── {noteId}/
│   │   ├── source.pdf          # Original PDF copy
│   │   ├── pages/              # Pre-rendered page images
│   │   ├── sketches/           # Sketch data (future)
│   │   ├── thumbnails/         # Page thumbnail cache
│   │   └── metadata.json       # Note metadata (future)
```

This structure is managed by `FileStorageService` and supports:

- Efficient file organization per note
- Thumbnail caching for performance
- Future extensibility for additional data types
