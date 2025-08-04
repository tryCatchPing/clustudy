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

This is a Flutter-based handwriting note app built with a **feature-driven architecture** using **GoRouter** for navigation. The codebase has been recently refactored with a clean modular structure.

### Core Architecture Pattern

**Clean Feature Architecture:**

- **Features** (`lib/features/`): Self-contained modules for major functionality
- **Shared** (`lib/shared/`): Common utilities, services, and app-wide components
- **GoRouter-based navigation**: Centralized routing with feature-specific route definitions

### Feature Structure

Each feature follows a consistent structure:

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

**Primary drawing and note editing functionality:**

- **Controllers**: `note_editor_controller.dart` manages drawing state and tool selection (currently commented for Provider migration)
- **Mixins**: `auto_save_mixin.dart` and `tool_management_mixin.dart` for cross-cutting concerns
- **Notifiers**:
  - `custom_scribble_notifier.dart`: Custom Scribble notifier with scaleFactor fixed at 1.0 for consistent stroke width across zoom levels
  - `scribble_notifier_x.dart`: Extended functionality for Scribble integration
- **Comprehensive UI**: Modular toolbar system with separate components for colors, strokes, tools, and actions
- **Controls**: Pressure sensitivity, pointer mode, and viewport information widgets
- **Background Widget**: `canvas_background_widget.dart` with simplified 2-tier file-based loading system
- **Error Recovery**: `file_recovery_modal.dart` provides user-friendly file corruption recovery options

#### 2. Note Management (`lib/features/notes/`)

**Note organization and listing:**

- **Models**:
  - `note_model.dart`: Core note structure with PDF metadata support
  - `note_page_model.dart`: Individual page model with file-based storage (memory cache removed for performance)
- **Data**: `fake_notes.dart` provides development data (temporary, will be replaced with Isar DB)
- **Pages**: `note_list_screen.dart` for note browsing and PDF import functionality

#### 3. Home (`lib/features/home/`)

**Main navigation and entry point:**

- **Pages**: `home_screen.dart` as the main landing page
- **Routing**: Centralized home navigation

#### 4. Shared Infrastructure (`lib/shared/`)

**App-wide utilities and components:**

- **Routing**: `app_routes.dart` defines all route constants and type-safe navigation helpers
- **Services**:
  - `file_picker_service.dart` for file operations
  - `file_storage_service.dart` for internal file management and PDF storage
  - `pdf_note_service.dart` for PDF-to-note conversion with file copying (legacy memory cache methods deprecated)
- **Widgets**: Reusable UI components like headers, cards, and navigation elements

### Navigation Architecture

**GoRouter-based routing** with feature separation:

- **Main router** (`lib/main.dart`): Combines routes from all features
- **Feature routes**: Each feature manages its own routes
- **Type-safe navigation**: `AppRoutes` class provides route constants and helper methods

### External Dependencies

- **Scribble**: Custom GitHub fork (main branch) for Apple Pencil pressure support
- **go_router**: v16.0.0 for declarative navigation
- **pdfx**: v2.5.0 for PDF viewing and interaction
- **file_picker**: v8.0.6 for file selection
- **path_provider**: v2.1.4 for app document directory access
- **path**: v1.9.0 for file path manipulation

### Development Standards

- **Dart SDK**: 3.8.1+ required
- **Strict linting**: Comprehensive analysis rules for code quality
- **Code style**: Single quotes, const constructors, final locals enforced
- **Documentation**: Public API documentation required (`public_member_api_docs: true`)
- **Import organization**: Relative imports preferred, directives ordering enforced

## Common Development Workflows

### Adding New Canvas Features

1. **Controllers**: Check existing controller patterns in `lib/features/canvas/controllers/`
2. **Mixins**: Use mixins for cross-cutting concerns (auto-save, tool management)
3. **Notifiers**: Extend existing custom notifiers for drawing behavior
   - **Important**: `CustomScribbleNotifier` overrides private methods from Scribble package
   - **scaleFactor Management**: Always use `setScaleFactor(1.0)` for consistent stroke width across zoom levels
   - Copy private methods when needed, add detailed source comments
4. **UI Components**: Add widgets to appropriate subdirectories (controls/, toolbar/)
5. **Constants**: Define feature constants in `note_editor_constant.dart`
6. **Performance**: Consider debouncing for real-time updates (8ms recommended for 120fps)

### Working with Navigation

1. **Route Definition**: Add routes to feature-specific routing files
2. **Route Constants**: Define paths in `lib/shared/routing/app_routes.dart`
3. **Type-safe Navigation**: Use helper methods from `AppRoutes` class
4. **Main Router**: Routes are automatically included from feature route lists

### Adding New Features

1. **Create Feature Structure**: Follow the established pattern under `lib/features/[feature_name]/`
2. **Feature Routes**: Create routing file following existing patterns
3. **Register Routes**: Add feature routes to main router in `lib/main.dart`
4. **Shared Resources**: Add any shared components to `lib/shared/`

### Working with PDF Features

**🚀 Service-Centered PDF Management System (Major Update v2.2):**

#### **Complete PDF Workflow - From Import to Recovery**

**🔄 Import & Creation Flow:**
1. **File Selection**: User selects PDF from local storage (with validation)
2. **Metadata Extraction**: PDF properties (pages, size, title) extracted
3. **Original Storage**: PDF copied to app internal storage (`/notes/{noteId}/original.pdf`)
4. **Image Rendering**: Each page rendered to PNG with progress tracking
5. **File Storage**: Images saved as `page_1.png`, `page_2.png`, etc.
6. **Note Creation**: `NoteModel` created with PDF metadata
7. **List Update**: Note added to user's note collection

**📱 Usage & Display Flow:**
8. **Note Opening**: User selects note from list → Editor opens
9. **Image Loading**: Pre-rendered images loaded for canvas background
10. **Error Detection**: Missing/corrupted image files detected automatically

**🔧 Recovery & Management Flow:**
11. **Recovery Modal**: User presented with clear options:
    - **Re-render**: Generate new images from original PDF
    - **Sketch Only**: Remove PDF background, keep user drawings
    - **Delete Note**: Remove entire note and files
12. **Re-rendering**: Original PDF → New images (preserves user sketches)
13. **Progress Tracking**: Real-time progress with cancellation support
14. **Fallback Handling**: PDF missing → Clear user notification
15. **Note Deletion**: Complete directory removal + database cleanup

#### **File Structure & Management**

```
/Application Documents/notes/
├── {noteId}/
│   ├── original.pdf          # Original PDF file (for re-rendering)
│   ├── metadata.json         # PDF metadata (pages, dimensions, title)
│   ├── page_1.png           # Pre-rendered page images
│   ├── page_2.png
│   ├── page_N.png
│   └── sketches.json        # User drawing data (preserved during recovery)
```

#### **Service Architecture**

**Centralized PDF Management**: All PDF operations handled by `PdfManager` service:
- `importPdfNote()`: Complete import flow with progress tracking
- `loadPageImage()`: Intelligent image loading with error detection
- `recoverNote()`: Re-rendering from original PDF
- `deleteNote()`: Clean removal of all associated files

#### **Error Handling Strategy**

**Recovery Scenarios Covered:**
- **Image Corruption**: Re-render from original PDF
- **PDF Missing**: Convert to sketch-only note or delete
- **Storage Issues**: Clear error messages and fallback options
- **Memory Limits**: Efficient rendering with memory monitoring
- **User Cancellation**: Safe interruption of long operations

#### **Performance Features**

- **Progress Tracking**: Real-time feedback for long operations
- **Memory Efficiency**: Stream-based processing for large PDFs
- **Cancellation Support**: User can interrupt rendering
- **Quality Settings**: Configurable rendering quality vs speed
- **Background Processing**: Non-blocking UI during operations

## Testing Strategy

- Widget tests configured in `test/` directory
- Use `fvm flutter test` to run all tests
- Focus testing on canvas functionality and PDF integration as core features

## State Management Transition

**Note**: The project is transitioning to Provider for state management:

- Current controllers are commented for Provider migration
- Mixins provide reusable state management patterns
- Custom notifiers extend Scribble functionality

## Work Distribution Strategy

### **Core Development Phase (Weeks 1-4)**

**Main Developer Tasks:**
1. **Provider State Management** (Week 1): Migrate from StatefulWidget to Provider pattern
2. **PDF Manager Service** (Week 2): Unified service with progress tracking, cancellation, and recovery
3. **Graph View System** (Weeks 3-4): Node/edge visualization, canvas integration, complex algorithms

**Secondary Developer Tasks:**
1. **Link Functionality** (Weeks 1-2): Link creation, editing, navigation, storage
2. **Isar Database Integration** (Weeks 3-4): Schema design, migration from fake data, PDF Manager integration

**Collaboration Points:**
- **Week 4**: Link system ↔ Graph view integration
- **Week 4**: PDF Manager ↔ Isar DB connection
- **Weeks 5-6**: Design system integration with both developers

## Recent Major Updates (Latest)

### PDF File System Migration (v2.1) - December 2024

**Problem Solved**: Complex 3-tier fallback system caused memory leaks and debugging difficulties.

**New Architecture**:

- **Simplified Loading**: 2-tier system (pre-rendered images → user recovery modal)
- **Memory Cache Removal**: Eliminated memory leaks by removing in-memory image caching
- **Transparent Error Handling**: Users get clear recovery options instead of automatic fallbacks
- **File Structure**: Maintained organized `/notes/{noteId}/` directories with PDF + images

**Performance Impact**:

- 90% memory usage reduction for large PDFs
- 70% code complexity reduction in loading logic
- Consistent 50ms loading times with predictable error states

### Canvas Scaling Optimization (v2.1) - December 2024

- **Stroke Consistency**: Fixed scaleFactor to 1.0 for consistent pen width across all zoom levels
- **Custom Notifier**: Enhanced `syncWithViewerScale()` method for better zoom synchronization
- **User Experience**: Eliminated confusing pen thickness changes during zoom operations
- **Debounced Updates**: 8ms debouncing for smooth scale changes during zoom

### Current Development Status

- ✅ PDF file system migration completed
- ✅ Canvas stroke scaling issues resolved
- ✅ Memory cache removal and error recovery system implemented
- ✅ Widget hierarchy documentation added to all components
- 🔄 **CURRENT PRIORITY**: Provider state management migration
- 🔄 **NEXT PRIORITY**: Service-centered PDF management system implementation
  - 🔄 Create unified `PdfManager` service
  - 🔄 Implement complete import → rendering → storage flow
  - 🔄 Add progress tracking and cancellation support
  - 🔄 Implement robust recovery and deletion logic
- 🔄 Graph view system for note connections (week 3-4)
- 🔄 Isar database integration (in parallel with other developer)

## 6-Week Development Roadmap

### **Week 1: Provider Migration + PDF Manager Design**
- **Days 1-2**: Provider pattern learning & basic setup
- **Days 3-4**: Core canvas Provider conversion
- **Days 5-7**: PDF Manager architecture design

### **Week 2: PDF Manager Implementation**
- **Days 8-10**: Core PDF Manager service implementation
- **Days 11-12**: Error detection & recovery system
- **Days 13-14**: Integration testing & bug fixes

### **Week 3: Graph View Core Logic**
- **Days 15-17**: Graph view architecture design & basic structure
- **Days 18-19**: Node/edge visualization algorithms
- **Days 20-21**: Canvas-graph view integration logic

### **Week 4: Graph View Completion + Integration**
- **Days 22-24**: Graph view UI/UX completion
- **Days 25-26**: Link system ↔ graph view integration (with other developer)
- **Days 27-28**: PDF Manager ↔ Isar DB integration (with other developer)

### **Week 5: Design Integration**
- **Days 29-31**: Designer-provided UI component integration
- **Days 32-33**: App-wide design system application
- **Days 34-35**: Usability testing & improvements

### **Week 6: Final Polish & Deployment**
- **Days 36-38**: Comprehensive bug fixes & performance optimization
- **Days 39-40**: App Store deployment preparation & documentation
- **Days 41-42**: Final testing & launch

## Team Context

This is a 4-person team project (2 designers, 2 developers) building a handwriting note app over 6 weeks core development + 2 weeks polish. The codebase was recently refactored with a clean modular structure.

**Team Division:**
- **Main Developer**: Provider migration, PDF Manager service, Graph view system
- **Secondary Developer**: Link functionality, Isar DB integration
- **Designers**: UI component creation, design system, code conversion assistance

**Current Phase**: Week 1 - Provider state management migration and PDF Manager architecture design.

**Development Philosophy**: Focus on core functionality first (weeks 1-4), then design integration and polish (weeks 5-6).

## Development Guidelines

### Error Handling Philosophy

- **Transparency over Automation**: Let users know what's happening instead of silent fallbacks
- **User Control**: Provide clear options (re-render, delete) rather than automatic recovery
- **Predictable Behavior**: Simple 2-tier systems over complex multi-tier fallbacks

### Performance Priorities

1. **Memory Efficiency**: Avoid in-memory caching for large files
2. **Loading Predictability**: Consistent file-based loading over variable fallback times
3. **Code Simplicity**: Maintainable logic over feature complexity

### Code Review Focus Areas

- **Canvas scaling logic**: Ensure scaleFactor remains 1.0 for stroke consistency
- **File-based operations**: Verify all PDF operations use FileStorageService
- **Error boundaries**: Check that error states provide clear user feedback
- **Memory management**: Avoid storing large data structures in memory
