# Linking + Session: Implementation Retrospective (Senior notes for beginners)

This doc explains what we built (linking), the problems we hit (gesture, state, routing/session), how we fixed them, and why we chose these patterns. It’s written to be approachable for newer devs and complete enough for seniors to audit.

## 1. Background and Goals
- Add “link” capability to the note editor.
  - Draw a rectangle on a page and create a link to another note.
  - Render saved links on the page.
  - Tap a saved link to navigate to the target note.
- Keep architecture clean: Providers + Repositories + layered widgets.
- Make navigation/session stable (no disappearing canvas after back navigation).

## 2. Starting Point (Problems and Constraints)
- Links: UI-only prototypes existed (rect overlay), no schema or persistence.
- Session: Manual session set/unset and a route `onExit` that cleared session.
  - Bug: After navigating back from a linked note, canvas disappeared because session was null → providers returned no-op.
- Canvas gestures: InteractiveViewer sometimes swallowed linker drag.

## 3. Design Overview
- Domain model and repositories
  - `LinkModel` (page → note; optional future: page → page)
  - `LinkRepository` interface: `create/update/delete`, `watchByPage`, `watchBacklinksToNote`.
  - Memory implementation: `MemoryLinkRepository` with indexes and per-key streams.
- Providers (Riverpod + codegen)
  - `linkRepositoryProvider` (keepAlive)
  - `linksByPageProvider(pageId)` → stream of links for painting
  - `backlinksToNoteProvider(noteId)`
  - `linkRectsByPageProvider(pageId)` → derived `List<Rect>`
  - `linkAtPointProvider(pageId, Offset)` → hit-test
- UI layers separation (single source of truth)
  - `SavedLinksLayer` (CustomPaint): paints persisted rectangles only.
  - `LinkerGestureLayer`: handles drag/tap input and draws in-progress rectangle only.
  - `NotePageViewItem`: orchestrates layers, opens dialogs, calls controller; no persistence itself.
- Creation UX
  - On drag end → “Create Link” dialog:
    - Input title or select existing note; if not found, create a blank note (1 page) and link to it.
  - Controller (`LinkCreationController`) handles orchestration and persistence.
- Policy (v1)
  - Links are page→note (navigate to note’s first page). No page→page links yet.
  - Self-link (same note) is disallowed.

## 4. Implementation Steps
1) Data + Providers
- Added `lib/features/canvas/models/link_model.dart`.
- Added `lib/shared/repositories/link_repository.dart` and memory repo:
  - `lib/features/canvas/data/memory_link_repository.dart`
- Added Riverpod providers with annotations:
  - `lib/features/canvas/providers/link_providers.dart` (codegen-ready).

2) UI layers
- `SavedLinksLayer`: reads `linkRectsByPageProvider(pageId)`.
- `LinkDragOverlayPainter`: draws in-progress rectangle.
- `LinkerGestureLayer`:
  - Pointer policy (all vs stylusOnly). Separate supportedDevices for drag and tap.
  - Emits `onRectCompleted(Rect)` and `onTapAt(Offset)`.
- `NotePageViewItem`: wires everything; opens dialogs and calls controller.

3) Link creation
- Dialog: `lib/features/canvas/widgets/dialogs/link_creation_dialog.dart`.
- Controller: `lib/features/canvas/providers/link_creation_controller.dart`.
  - Resolves/creates target note, builds LinkModel, calls `LinkRepository.create`.
  - Prevents self-link (source noteId == target noteId → throws StateError).

4) Navigation and session (RouteAware-only)
- Removed legacy `onExit` cleanup from editor route.
- Added global `RouteObserver` (GoRouter observers: `[appRouteObserver]`).
- `NoteEditorScreen` implements `RouteAware`:
  - `didPush` → schedule `enterNote(noteId)` (post-frame)
  - `didPop` → schedule `exitNote()` (post-frame)
  - `didPopNext` → double-post-frame re-enter, with `ModalRoute.isCurrent` guard
  - No provider writes during build (uses `addPostFrameCallback`).
- Therefore session now follows route visibility, no manual enter/exit on button taps.

5) Gesture/panning
- In linker mode, `InteractiveViewer.panEnabled=false`; gestures go to `LinkerGestureLayer` for rectangle drag.

6) Logging + noise reduction
- Added rich logs for debugging; then gated/reduced noise:
  - `note_editor_provider.dart`: `canvasPageNotifier` logs behind `_kCanvasProviderVerbose` flag; suppressed common “Page not found” during transitions.
  - `link_providers.dart`: logs behind `_kLinkProvidersVerbose`.
  - `SavedLinksLayer`: removed per-frame rect count logs.
  - `MemoryLinkRepository`: removed routine verbose logs.

## 5. Key Bugs and Fixes
- Problem: “Provider modified during build”
  - Cause: Session writes inside RouteAware callbacks triggered during build.
  - Fix: Wrap `enterNote/exitNote` in `WidgetsBinding.instance.addPostFrameCallback`.

- Problem: Returning from a linked note → session=null (no-op)
  - Cause: `onExit` cleared session on push; no automatic re-entry on pop.
  - Fix: RouteAware-only. `didPopNext` re-enters session with a two-frame defer so it runs after `didPop` exit. Removed `onExit`.

- Problem: Linker drag didn’t draw; page panned
  - Cause: InteractiveViewer captured drag.
  - Fix: When `ToolMode.linker`, set `panEnabled=false`.

- Problem: Navigation races causing target page “Page not found”
  - Cause: Underlying route rebuilding and scheduling old session enters during push.
  - Fix: Don’t write session in `didChangeDependencies`; only in `didPush/didPopNext` with isCurrent checks and defers.
  - It is still expected to see old pageIds request providers during teardown; we suppressed those logs.

## 6. Why these patterns
- Single source of truth: saved links are streamed from a repository → providers → painter. Gesture layer never stores/persists links.
- RouteAware-only for session: aligns session with route visibility; avoids onExit clearing too early, and removes manual session calls.
- Deferring provider writes: respects Riverpod’s rule for state changes outside of build.
- Memory repo first: fastest iteration; Isar remains a future optimization.

## 7. Testing Guide (manual)
- Create a blank note; open editor.
- Switch to linker; drag to open dialog.
  - Enter new title → link created, target note created.
  - Enter existing title → link created.
  - Try same-note title → error snackbar (“동일 노트로는 링크를 생성할 수 없습니다.”).
- Tap saved link → navigate to target note.
- Back navigation
  - Canvas should remain visible on the previous note.
- Gestures
  - Linker mode: rectangle drag; non-linker: Scribble + panning.

## 8. Future Work
- Isar implementation (`@collection LinkEntity`) and repo swap.
- Backlinks UI and navigation to the exact source page (already have `sourcePageId`).
- Link editing/deletion.
- Optional: page→page links (add `targetPageId` back); dialog picks target page.
- URL-derived session (remove manual session state entirely).
- Optimistic UI for link creation/deletion.

## 9. File Map (main additions/changes)
- Models/Repos/Providers
  - `lib/features/canvas/models/link_model.dart`
  - `lib/shared/repositories/link_repository.dart`
  - `lib/features/canvas/data/memory_link_repository.dart`
  - `lib/features/canvas/providers/link_providers.dart`
  - `lib/features/canvas/providers/link_creation_controller.dart`
- UI
  - `lib/features/canvas/widgets/saved_links_layer.dart`
  - `lib/features/canvas/widgets/linker_gesture_layer.dart`
  - `lib/features/canvas/widgets/link_drag_overlay_painter.dart`
  - `lib/features/canvas/widgets/dialogs/link_creation_dialog.dart`
  - `lib/features/canvas/widgets/dialogs/link_actions_sheet.dart`
  - `lib/features/canvas/widgets/note_page_view_item.dart` (wiring)
- Routing/Session
  - `lib/shared/routing/route_observer.dart`
  - `lib/features/canvas/pages/note_editor_screen.dart` (RouteAware, session defers)
  - `lib/features/canvas/routing/canvas_routes.dart` (removed onExit)
  - `lib/main.dart` (register RouteObserver)

## 10. Practical Tips (for beginners)
- Don’t mutate providers during `build`/lifecycle – use `addPostFrameCallback`.
- Separate “input” from “paint”. Persisted data should come from providers; gestures should not own long-lived state.
- Streams + providers: always prefer watch/StreamProvider to manual get for reactivity and correctness.
- RouteAware is your friend for session/context you want aligned with the visible screen.
- Don’t be scared of “no-op notifier” during transitions: it’s normal for teardown frames.

## 11. Summary
We introduced a robust linking system and stabilized session management using RouteAware. The solution respects Flutter/Riverpod constraints, separates concerns (input/paint/persistence), and leaves clear hooks for Isar and advanced linking later. This approach is scalable, testable, and easy for newcomers to follow.
