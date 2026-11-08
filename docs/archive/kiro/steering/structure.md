---
inclusion: always
---

# Project Structure & Architecture Guidelines

## Mandatory Architecture Rules

**Feature-based modular architecture** - Each feature MUST be self-contained:

- **Features**: `canvas/`, `home/`, `notes/`, `vaults/` - domain-driven modules
- **Shared**: Cross-feature utilities only in `shared/` directory
- **State**: Riverpod providers with `@riverpod` code generation REQUIRED
- **Navigation**: GoRouter with feature-specific routing in `/routing/` directories

## Required Directory Structure

When creating new features or files, ALWAYS follow this structure:

```
lib/
├── features/{feature_name}/
│   ├── data/                    # Repositories & data sources
│   ├── models/                  # Domain entities & DTOs
│   ├── pages/                   # UI screens (StatelessWidget)
│   ├── providers/               # Riverpod providers (@riverpod)
│   ├── routing/                 # GoRouter route definitions
│   └── widgets/                 # Feature-specific UI components
├── shared/
│   ├── constants/               # App-wide constants
│   ├── services/                # Business logic services
│   ├── repositories/            # Cross-feature data access
│   └── widgets/                 # Reusable UI components
└── design_system/               # UI tokens, components, themes
```

## File Naming Rules (ENFORCED)

**MUST use these suffixes:**

- `_model.dart` - Data models and entities
- `_service.dart` - Business logic services
- `_repository.dart` - Data access layer
- `_provider.dart` - Riverpod providers
- `_notifier.dart` - State notifiers
- `_page.dart` - Full screen widgets
- `_widget.dart` - Reusable UI components

**Directory naming:** Snake case, plural for collections (`models/`, `services/`)

## Import Organization (STRICT ORDER)

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter framework
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 4. Relative imports (same feature)
import '../models/note_model.dart';

// 5. Shared module imports
import '../../shared/services/file_storage_service.dart';
```

## Code Generation Requirements

**ALWAYS run after modifying providers:**

```bash
fvm flutter packages pub run build_runner build
```

## Architecture Constraints

### Dependency Direction (ENFORCED)

- Features → Shared modules ✓
- Shared → Features ✗ (FORBIDDEN)
- UI → Business logic ✓
- Business logic → UI ✗ (FORBIDDEN)

### State Management Pattern (REQUIRED)

```dart
@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  @override
  ExampleState build() => ExampleState.initial();

  // State mutations here
}
```

### Repository Pattern (MANDATORY)

- All data access through repositories in `/data/` directories
- Dependency injection via Riverpod providers
- NO direct database/file access from UI components

## Critical Services (lib/shared/services/)

When working with these domains, ALWAYS use these services:

- `FileStorageService` - File system operations
- `NoteService` - Note CRUD operations
- `PdfProcessor` - PDF rendering and processing
- `NoteDeletionService` - Safe deletion with cleanup
- `PageManagementService` - Page ordering and management
- `VaultNotesService` - Vault-level note operations

## File Storage Convention

**MUST follow this structure for note storage:**

```
/Application Documents/notes/{noteId}/
├── source.pdf              # Original PDF (if applicable)
├── pages/                  # Pre-rendered page images
├── thumbnails/             # Cached thumbnails
└── metadata.json           # Note metadata
```

**ALWAYS use `FileStorageService` for file operations - never direct file I/O**
