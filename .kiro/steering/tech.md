# Technology Stack & Build System

## Flutter Framework

- **Flutter SDK**: 3.32.5 (Dart SDK 3.8.1+)
- **Version Management**: FVM (Flutter Version Management) - mandatory for team consistency
- **Target Platforms**: iOS (primary), Android, Web (limited support)

## State Management & Architecture

- **State Management**: Riverpod 2.6.1 with code generation
- **Architecture Pattern**: Feature-based modular architecture
- **Code Generation**:
  - `riverpod_generator` for providers
  - `build_runner` for code generation

## Key Dependencies

### Canvas & Drawing

- **scribble**: Custom fork from GitHub (pressure sensitivity support)
- **flutter/material.dart**: Material 3 design system

### PDF Processing

- **pdfx**: 2.5.0 - PDF rendering and manipulation
- **file_picker**: 8.0.6 - File selection interface

### Navigation & Routing

- **go_router**: 16.0.0 - Declarative routing

### Storage & File Management

- **path_provider**: 2.1.4 - Platform-specific directories
- **path**: 1.9.0 - Cross-platform path manipulation
- **uuid**: 4.5.1 - Unique identifier generation

### Development Tools

- **flutter_lints**: 5.0.0 - Dart/Flutter linting rules
- **build_runner**: 2.5.4 - Code generation runner

## Build Commands

### Environment Setup

```bash
# Install FVM and set Flutter version
dart pub global activate fvm
fvm install 3.32.5
fvm use 3.32.5

# Verify installation
fvm flutter doctor
fvm list  # Should show ● in Local column
```

### Development Workflow

```bash
# Install dependencies
fvm flutter pub get

# Code generation (run after modifying providers)
fvm flutter packages pub run build_runner build

# Run app (development)
fvm flutter run

# Run with specific device
fvm flutter run -d chrome  # Web
fvm flutter run -d ios     # iOS Simulator
```

### Testing & Quality

```bash

# not yet.....
# # Run tests
# fvm flutter test

# Static analysis
fvm flutter analyze

# Format code
fvm flutter format .

# Clean build artifacts
fvm flutter clean
```

### Build & Release

```bash
# Build for iOS
fvm flutter build ios --release

# Build for Android
fvm flutter build apk --release

# Build for Web
fvm flutter build web --release
```

## Code Style & Linting

### Analysis Options

- **Strict mode**: Implicit casts and dynamic disabled
- **Documentation**: Public API documentation required
- **Line length**: 80 characters maximum
- **Import ordering**: Directives ordering enforced
- **Const usage**: Prefer const constructors and declarations

### Key Linting Rules

- Single quotes preferred
- Final variables encouraged
- Avoid print statements (use debugPrint)
- Public member API documentation required
- Relative imports for lib/ files

## Performance Targets

- **Canvas rendering**: 55+ FPS during drawing
- **Memory usage**: Efficient stroke storage (1000 strokes < 5MB)
- **App startup**: < 3 seconds on target devices
- **File operations**: Non-blocking UI during PDF processing

## Platform-Specific Considerations

### iOS

- Apple Pencil pressure sensitivity support
- TestFlight deployment for team testing
- iOS 12+ compatibility

### Android

- Stylus input support where available
- APK distribution for testing

### Web

- Limited canvas performance
- File system access restrictions
- Primarily for demonstration purposes
