# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Development Commands

```bash
# Use FVM for Flutter version consistency (team uses Flutter 3.32.5)
fvm flutter pub get              # Install dependencies
fvm flutter run                  # Run app in debug mode
fvm flutter run --release        # Run app in release mode
fvm flutter clean               # Clean build artifacts
```

### Quality Assurance Commands

```bash
fvm flutter analyze            # Static code analysis (strict mode enabled)
fvm flutter test              # Run all tests
fvm flutter doctor            # Check development environment
```

### iOS-specific Commands (macOS only)

```bash
cd ios && pod install && cd ..  # Install iOS dependencies after pubspec changes
```

## Architecture Overview

This is a Flutter-based handwriting note app built with a **feature-driven architecture** using **GoRouter** for navigation.

### Core Architecture Pattern

**Clean Feature Architecture:**

- **Features** (`lib/features/`): Self-contained modules for major functionality
- **Shared** (`lib/shared/`): Common utilities, services, and app-wide components
- **GoRouter-based navigation**: Centralized routing with feature-specific route definitions

### Feature Structure

```
lib/features/[feature_name]/
├── constants/     # Feature-specific constants
├── controllers/   # Business logic and state management
├── mixins/        # Reusable behavior mixins
├── models/        # Data models
├── notifiers/     # Custom notifiers and state providers
├── pages/         # Screen/page widgets
├── routing/       # Feature-specific routes
└── widgets/       # UI components
    ├── controls/  # Control widgets
    └── toolbar/   # Toolbar components
```

### Key Features

#### 1. Canvas System (`lib/features/canvas/`)

- Drawing state management with Provider migration in progress
- Custom Scribble notifier with scaleFactor fixed at 1.0 for consistent stroke width
- Modular toolbar system with controls for colors, strokes, tools
- PDF Recovery System with corruption detection

#### 2. Note Management (`lib/features/notes/`)

- Core note structure with PDF metadata support
- File-based storage (memory cache removed for performance)
- Note browsing and PDF import functionality
- Temporary fake data (will be replaced with Isar DB)

#### 3. Shared Infrastructure (`lib/shared/`)

- **Services**: File operations, PDF processing, note creation, storage management
- **Routing**: GoRouter-based navigation with type-safe helpers
- **Widgets**: Reusable UI components

### External Dependencies

- **Scribble**: Custom GitHub fork for Apple Pencil pressure support
- **go_router**: v16.0.0 for navigation
- **pdfx**: v2.5.0 for PDF viewing
- **file_picker**: v8.0.6 for file selection

### Development Standards

- **Dart SDK**: 3.8.1+ required
- **Strict linting** with comprehensive analysis rules
- **Code style**: Single quotes, const constructors, final locals enforced
- **Documentation**: Public API documentation required

## Development Guidelines

### Canvas Development

- **scaleFactor Management**: Always use `setScaleFactor(1.0)` for consistent stroke width
- **Performance**: Use 8ms debouncing for real-time updates (120fps)
- **Custom Notifiers**: Override private Scribble methods with detailed source comments

### Adding New Features

1. Follow feature structure pattern under `lib/features/[feature_name]/`
2. Create feature-specific routing files
3. Register routes in main router
4. Add shared components to `lib/shared/`

### PDF System Architecture

**Current Implementation:**

- **NoteService**: Orchestrates note creation, delegates PDF processing
- **PdfProcessor**: Handles all PDF operations (selection, rendering, storage)
- **PdfRecoveryService**: Corruption detection and recovery options

**Key Usage:**

```dart
// Unified note creation
final note = await NoteService.instance.createPdfNote();
final blankNote = await NoteService.instance.createBlankNote();
```

**File Structure:**

```
/Application Documents/notes/
├── {noteId}/
│   ├── source.pdf           # Original PDF file
│   └── pages/
│       ├── page_1.jpg       # Pre-rendered page images
│       └── page_N.jpg
```

**Performance Features:**

- Single PDF opening (90% performance improvement)
- File-based storage (memory efficiency)
- Pure constructors (Isar DB ready)

## Current Status

**State Management Transition:**

- Transitioning to Provider for state management
- Current controllers commented for Provider migration
- Custom notifiers extend Scribble functionality

**Testing:**

- Use `fvm flutter test` to run all tests
- Focus on canvas functionality and PDF integration

## Work Distribution Strategy

**Main Developer Tasks:**

1. **Provider State Management** (Week 1): Migrate from StatefulWidget to Provider pattern
2. **PDF Manager Service** (Week 2): Unified service with progress tracking, cancellation, and recovery
3. **Graph View System** (Weeks 3-4): Node/edge visualization, canvas integration, complex algorithms

**Secondary Developer Tasks:**

1. **Link Functionality** (Weeks 1-2): Link creation, editing, navigation, storage
2. **Isar Database Integration** (Weeks 3-4): Schema design, migration from fake data, PDF Manager integration

**Recent Completions:**

- PDF Processing Architecture with clean service separation
- Canvas stroke scaling optimization (scaleFactor fixed at 1.0)
- Complete PDF Recovery System with corruption detection
- Unified note creation system

**🔄 Next Development Priorities:**

1. **Provider State Management Migration** (Week 1): Replace StatefulWidget patterns
2. **Graph View System** (Weeks 2-3): Node/edge visualizations for note connections
3. **Isar Database Integration** (Week 3-4): Migration from fake data to persistent storage
4. **Advanced PDF Features** (Week 4): Enhanced recovery options and performance optimizations

## 6-Week Development Roadmap

### **Week 1: Provider Migration + PDF Manager Design**

- **Days 1-2**: Provider pattern learning & basic setup
- **Days 3-4**: Core canvas Provider conversion
- **Days 5-7**: PDF Manager architecture design

### **Week 2: Graph View Foundation**

- **Days 8-10**: Graph view architecture design & basic structure
- **Days 11-12**: Node/edge visualization core logic
- **Days 13-14**: Canvas-graph view integration foundation

### **Week 3: Graph View Completion + Isar DB**

- **Days 15-17**: Graph view UI/UX completion
- **Days 18-19**: Isar database schema design & basic implementation
- **Days 20-21**: Graph view ↔ database integration

### **Week 4: Full System Integration**

- **Days 22-24**: Complete Isar DB migration from fake data
- **Days 25-26**: Link system ↔ graph view integration (with other developer)
- **Days 27-28**: PDF Recovery ↔ Isar DB integration and testing

### **Week 5: Design Integration**

- **Days 29-31**: Designer-provided UI component integration
- **Days 32-33**: App-wide design system application
- **Days 34-35**: Usability testing & improvements

### **Week 6: Final Polish & Deployment**

- **Days 36-38**: Comprehensive bug fixes & performance optimization
- **Days 39-40**: App Store deployment preparation & documentation
- **Days 41-42**: Final testing & launch

## Team Context

4-person team (2 designers, 2 developers) building a handwriting note app over 6 weeks core development + 2 weeks polish.

**Team Division:**

- **Main Developer**: Provider migration, PDF Manager service, Graph view system
- **Secondary Developer**: Link functionality, Isar DB integration
- **Designers**: UI component creation, design system, code conversion assistance

**Current Phase**: Week 1 - Provider state management migration with solid PDF architecture foundation established.

## Development Philosophy

### Error Handling

- **Transparency over Automation**: Clear user feedback instead of silent fallbacks
- **User Control**: Provide options (re-render, delete) rather than automatic recovery
- **Predictable Behavior**: Simple systems over complex fallbacks

### Performance Priorities

1. **Memory Efficiency**: Avoid in-memory caching for large files
2. **Loading Predictability**: Consistent file-based loading
3. **Code Simplicity**: Maintainable logic over feature complexity

### Code Review Focus

- **Canvas scaling**: Ensure scaleFactor remains 1.0 for stroke consistency
- **Service architecture**: Proper separation between services
- **Pure constructors**: Isar DB compatibility
- **Memory management**: Avoid storing large data structures in memory
- **Singleton usage**: Use `NoteService.instance` for consistent state management
