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

Flutter-based handwriting note app with **Riverpod state management** and **Repository pattern** for data persistence.

### Current Architecture (2025-08-20)

**Clean Architecture with Riverpod:**

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│    (ConsumerWidget + Riverpod)          │
├─────────────────────────────────────────┤
│         Business Logic Layer            │
│  (Services + Provider Notifiers)        │
├─────────────────────────────────────────┤
│            Data Layer                   │
│ (Repository Pattern + File Storage)     │
└─────────────────────────────────────────┘
```

### Key Components

#### 1. State Management - Riverpod

- **Provider Pattern**: Family providers for noteId-based state management
- **CustomScribbleNotifiers**: Per-page drawing state management
- **Tool Settings**: Global toolbar state with per-note sharing
- **Page Controllers**: Automatic lifecycle management

#### 2. Data Layer - Repository Pattern

- **NotesRepository Interface**: Abstraction for data persistence
- **MemoryNotesRepository**: Current implementation (temporary)
- **IsarNotesRepository**: Planned implementation (by secondary developer)
- **Seamless switching**: Interface-based design allows easy implementation swap

#### 3. PDF System

- **PdfProcessor**: Unified PDF processing (90% performance improvement)
- **PdfRecoveryService**: Complete corruption detection and user-controlled recovery
- **File-based architecture**: No memory caching for better performance

#### 4. Canvas System

- **Scribble Integration**: Custom fork with Apple Pencil pressure support
- **Per-page notifiers**: Isolated drawing state per page
- **scaleFactor**: Fixed at 1.0 for consistent stroke width

## Current Status (85% Complete)

### ✅ Completed Major Features

1. **Riverpod Migration** (85% complete)

   - Core providers migrated to Riverpod
   - Family pattern for note-specific state
   - Automatic lifecycle management

2. **Repository Pattern** (100% complete)

   - Interface-based data abstraction
   - Memory implementation fully functional
   - Fake data completely removed

3. **PDF System** (100% complete)

   - File system migration completed
   - PDF processor architecture optimized
   - Complete recovery system implemented

4. **Page Controller** (95% complete)

   - Thumbnail generation and caching
   - Drag & drop reordering
   - Page add/delete functionality
   - Integration with repository pattern

5. **PDF Export** (100% complete)
   - Canvas-to-PDF rendering
   - Progress tracking and cancellation

### 🔄 Current Tasks

1. **Page-level Notifier Issues** (In Progress)

   - Provider link disconnection during page operations
   - Being addressed in separate Claude Code session

2. **Memory Implementation Testing** (In Progress)
   - Validating all features with repository pattern
   - Preparing for Isar DB integration

## Next Development Phase

### Week 1 Priority: Provider Stabilization

1. **Fix page-level notifier lifecycle management**

   - Resolve provider link issues
   - Ensure stable Canvas state during page operations

2. **PDF processing improvements**
   - Enhanced error handling
   - Large file optimization

### Week 2-3: Database Integration

1. **Repository pattern completion**

   - Interface-based full abstraction
   - Transaction support preparation

2. **Isar DB integration** (Secondary developer)
   - Seamless repository implementation swap
   - Performance-optimized schema

### Week 3-4: Advanced Features

1. **Graph View System**

   - Note connection visualization
   - Link system integration

2. **Link functionality completion**
   - Page-to-page linking
   - Graph view integration

## Development Guidelines

### Architecture Principles

- **Repository Pattern**: Always access data through repository interfaces
- **Provider-First**: Use Riverpod providers for all state management
- **Service Layer**: Business logic separated from UI and data layers
- **Interface-Based**: Design for easy implementation swapping

### Canvas Development

- **scaleFactor**: Always maintain 1.0 for consistent stroke width
- **Per-page isolation**: Each page has independent drawing state
- **Provider lifecycle**: Let Riverpod manage notifier creation/disposal

### Data Persistence

- **Repository only**: Never access fake data or direct storage
- **Interface contracts**: Ensure all implementations follow same interface
- **Async operations**: All data operations are Future-based

### Error Handling

- **User transparency**: Clear error messages and recovery options
- **Graceful degradation**: System continues functioning during partial failures
- **Recovery options**: Always provide user choice in error scenarios

## File Structure

```
lib/
├── features/
│   ├── canvas/
│   │   ├── providers/          # Riverpod state management
│   │   ├── widgets/           # UI components
│   │   └── notifiers/         # Custom notifiers
│   ├── notes/
│   │   ├── data/              # Repository implementations
│   │   ├── models/            # Data models
│   │   └── pages/             # UI screens
│   └── page_controller/       # Page management
├── shared/
│   ├── services/              # Business logic services
│   ├── repositories/          # Repository interfaces
│   └── widgets/               # Reusable components
```

## Dependencies

- **riverpod**: v2.x for state management
- **go_router**: v16.0.0 for navigation
- **scribble**: Custom fork for drawing
- **pdfx**: v2.5.0 for PDF handling
- **file_picker**: v8.0.6 for file selection

## Team Context

**Current Phase**: Architecture stabilization and feature completion
**Target**: 4-person team building production-ready handwriting note app
**Timeline**: 4-5 weeks remaining for core features + 2 weeks polish

### Developer Responsibilities

- **Main**: Provider issues, PDF optimization, Graph view
- **Secondary**: Isar DB integration, Link functionality
- **Designers**: UI refinement, design system completion
