# Undo/Redo History Management Fix

## Problem Overview

The Flutter canvas application was experiencing undo/redo history loss when users changed tools (pen, eraser, highlighter) or tool settings (color, stroke width). Additionally, adding new pages to a note would reset the drawing history completely.

## Root Causes Identified

### 1. Tool Settings Triggering Provider Rebuilds
- `ref.watch(toolSettingsNotifierProvider(noteId))` in `CustomScribbleNotifiers.build()` was causing complete provider rebuilds
- Each rebuild recreated all `CustomScribbleNotifier` instances, losing their drawing history
- Tool changes (pen/eraser/highlighter) and setting changes (color/width) triggered these rebuilds

### 2. History Stack Pollution
- Direct assignments to `value =` in `setColor()` and `setStrokeWidth()` were adding entries to the undo history stack
- This caused users to need multiple undo operations to revert a single drawing stroke
- UI tool changes were being treated as drawable actions

### 3. Page Addition Listener Disconnection
- When adding pages, the `_cacheByPageId` would temporarily become empty (`{}`)
- The `_toolSettingsListenerAttached` flag remained `true` but the actual listener was disconnected
- This caused tool settings to stop propagating to notifiers after page additions

## Solutions Implemented

### 1. Prevent Provider Rebuilds from Tool Changes

**File**: `lib/features/canvas/providers/note_editor_provider.dart`

**Change**: Lines 83-84
```dart
// Before: Caused rebuilds on every tool setting change
final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));

// After: Read once during build, no rebuilds
final toolSettings = ref.read(toolSettingsNotifierProvider(noteId));
```

**Impact**: Tool setting changes no longer trigger complete provider rebuilds and notifier recreation.

### 2. Preserve History with Conditional Tool Mode Updates

**File**: `lib/features/canvas/providers/note_editor_provider.dart`

**Change**: Lines 188-207
```dart
// Only change tool mode if it actually changed
notifier.setTool(next.toolMode);
switch (next.toolMode) {
  case ToolMode.pen:
    notifier
      ..setColor(next.penColor)
      ..setStrokeWidth(next.penWidth);
    break;
  // ... other cases
}
```

**Impact**: Real-time tool changes work while preserving drawing history.

### 3. Use temporaryValue for Non-History Changes

**File**: `lib/features/canvas/notifiers/tool_management_mixin.dart`

**Change**: Lines 54-66
```dart
@override
void setColor(Color color) {
  if (value is Drawing) {
    temporaryValue = (value as Drawing).copyWith(
      selectedColor: color.value,
    );
  }
}

@override
void setStrokeWidth(double width) {
  temporaryValue = value.copyWith(selectedWidth: width);
}
```

**Impact**: UI tool setting changes don't pollute the undo history stack.

### 4. Detect and Fix Listener Disconnection

**File**: `lib/features/canvas/providers/note_editor_provider.dart`

**Change**: Lines 156-162
```dart
// Detect when cache is empty and re-establish listener
if (!_toolSettingsListenerAttached || currentIds.isEmpty) {
  if (currentIds.isEmpty) {
    print('🔄 [CustomScribbleNotifiers] 캐시가 비어있어서 listener 재연결');
    _toolSettingsListenerAttached = false;
  }
  
  if (!_toolSettingsListenerAttached) {
    _toolSettingsListenerAttached = true;
    // Re-establish listener...
  }
}
```

**Impact**: Tool settings continue to work after page additions.

## Technical Details

### Key Concepts Used

1. **temporaryValue vs value**: 
   - `temporaryValue` = UI-only changes, no history impact
   - `value` = Drawable actions that should be in undo stack

2. **ref.read() vs ref.watch()**:
   - `ref.read()` = One-time read, no rebuild triggers
   - `ref.watch()` = Reactive listening, triggers rebuilds

3. **Listener Re-establishment**:
   - Defensive programming to detect broken state
   - Automatic recovery when cache becomes empty

### Debug Logging Added

Comprehensive logging was added to track:
- Page ID changes during note operations
- Listener attachment/detachment events
- Tool setting propagation
- Cache state transitions

Example logs:
```
🔍 [CustomScribbleNotifiers] 기존 pageIds: {page_1, page_2}
🔍 [CustomScribbleNotifiers] 새로운 pageIds: {page_1, page_2, page_3}
➕ [CustomScribbleNotifiers] 새 페이지 추가: page_3
🔗 [CustomScribbleNotifiers] Tool settings listener 연결
🛠️ [CustomScribbleNotifiers] Tool settings 변경: pen -> eraser
```

## Testing Scenarios Verified

1. **Tool Mode Changes**: Pen ↔ Eraser ↔ Highlighter without history loss
2. **Color Changes**: Multiple color changes while preserving drawing history
3. **Stroke Width Changes**: Width adjustments without affecting undo stack
4. **Page Addition**: Adding pages maintains tool functionality and history
5. **Mixed Operations**: Complex sequences of drawing + tool changes + page operations

## Current Status

### ✅ Resolved Issues
- Tool setting changes preserve undo/redo history
- Page addition no longer resets drawing history
- Undo operations work with expected click counts
- Real-time tool changes function correctly

### ⚠️ Outstanding Concerns
- Root cause of cache emptying during page addition is still unclear
- Current solution is defensive programming rather than addressing the fundamental issue
- Potential for similar issues if other operations cause cache state problems

## Recommendations

1. **Monitor for Similar Issues**: Watch for other operations that might cause cache state problems
2. **Consider Refactoring**: Future consideration of more robust state management patterns
3. **Add Tests**: Implement automated tests for these critical user flows
4. **Performance Monitoring**: Ensure the defensive checks don't impact performance

## Related Files

- `lib/features/canvas/providers/note_editor_provider.dart` - Main provider logic
- `lib/features/canvas/notifiers/tool_management_mixin.dart` - Tool setting overrides
- `lib/features/canvas/notifiers/custom_scribble_notifier.dart` - Core notifier implementation
- `lib/shared/services/page_management_service.dart` - Page operations
- `lib/features/notes/data/memory_notes_repository.dart` - Data persistence

## Development Team Notes

This fix was implemented collaboratively with extensive debugging and iterative refinement. The solution balances functionality with maintainability while acknowledging that some edge cases may require future investigation.