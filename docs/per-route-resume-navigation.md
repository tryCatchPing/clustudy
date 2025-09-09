# Per‑Route Resume Navigation: Design, Implementation, and Lessons Learned

This document explains why and how we implemented per‑route resume memory for the note editor, the problems we hit along the way, and the final data flow. It is written so junior developers can understand the reasoning, reproduce the fixes, and avoid similar pitfalls.

---

## Goal

- Preserve and restore the last viewed page for each editor route instance independently.
- Eliminate page counter vs. visible page mismatches at entry/return.
- Respect Riverpod’s lifecycle constraints (no provider writes during build/initialization).
- Keep “cold re‑open” behavior predictable (optional last known page per note).

---

## Background

- Routing: `GoRouter` creates the editor with `MaterialPage(maintainState: false)`. Leaving the editor disposes it; returning recreates it.
- State before change:
  - `currentPageIndexProvider(noteId)`: live index for the visible page (reinitialized to 0 on screen recreate).
  - `resumePageIndexProvider(noteId)`: single-slot per note to restore the page when returning.
  - `pageControllerProvider(noteId)`: kept `PageView` in sync with the provider value.

Problematic flows showed that a single resume slot per note was insufficient and that first-frame mismatches occurred.

---

## Problems Observed

1. Wrong page restored after multi-instance navigation

- Flow: A(a) → B → A(a) → A(aa) → B(back) → A(back)
- Cause: A(aa) wrote `resumePageIndexProvider(A)=aa`, overwriting A(a)’s earlier `a`.
- Result: Returning to the older A instance restored `aa` instead of `a`.

2. Counter vs. visible page mismatch on (re)entry

- The `PageController` was created with `initialPage=0` while restore happened post-frame, yielding: counter shows restored index, but the view shows page 1 briefly.

3. Riverpod lifecycle violations

- We wrote to providers in restricted phases:
  - didPushNext (during route transition) → “Tried to modify a provider while the widget tree was building”.
  - Provider build (inside `pageControllerProvider`) → “Providers are not allowed to modify other providers during their initialization”.

4. Page Controller modal could not navigate the editor

- The modal was opened inside a separate `ProviderScope`, thus using a different `ProviderContainer`. Its updates and controller reads did not act on the editor route’s state/controller.

---

## Design Decisions

- Per‑route 1‑shot resume memory
  - Keep a `Map<routeId, int>` per note, not a single int.
  - “Resume” is one‑shot per route instance: read once, then remove.
- Last‑known per note (optional)
  - For cold re‑opens: `lastKnownPageIndexProvider(noteId) → int?`.
- Safe timing
  - Do not write providers during route transitions, build, or provider initialization.
  - Use post‑frame callbacks for cross‑provider writes triggered by lifecycle events.
- Maintain `maintainState: false`
  - Continue to avoid duplicate editor instances and GlobalKey conflicts.

---

## Implementation Summary

New/updated providers (in `lib/features/canvas/providers/note_editor_provider.dart`):

- `noteRouteIdProvider(noteId)` (keepAlive)
  - Tracks the active routeId for a given note (set on didPush/didPopNext/build‑guard, cleared on didPop).
- `resumePageIndexMapProvider(noteId)` (keepAlive)
  - Map of `routeId → pageIndex` with methods: `save`, `peek`, `take`, `remove`.
  - Used to store per‑route resume just before navigating away and to restore on return.
- `lastKnownPageIndexProvider(noteId)` (keepAlive)
  - Optional “last known” page index for cold re‑open scenarios.
- `pageControllerProvider(noteId, routeId)`
  - Computes `initialPage` using resume/lastKnown as read‑only inputs.
  - No provider writes during initialization. All sync writes happen post‑frame in the screen.

Editor Screen (in `lib/features/canvas/pages/note_editor_screen.dart`):

- Receives `routeId` from the router (`state.pageKey`).
- Lifecycle:
  - didPush/build‑guard/didPopNext: set session + `noteRouteId`, then schedule `_scheduleSyncInitialIndexFromResume` post‑frame.
  - didPop: save sketch, set `lastKnown`, remove this route’s entry from resume map, exit session + clear routeId.
- `_scheduleSyncInitialIndexFromResume({allowLastKnown})`
  - Reads `resumeMap.peek(routeId)` (or lastKnown if allowed), clamps to page bounds, sets `currentPageIndexProvider` post‑frame, and consumes resume (`take`).
  - We call it with `allowLastKnown=true` on initial entry; `false` on didPopNext so modal choices aren’t overwritten by lastKnown.

Backlink/Link taps (in panels/items):

- Before navigating: save current page sketch, then
  - `resumeMap.save(routeId, currentIndex)` and `lastKnown.setValue(currentIndex)` (safe timing; user event handler).

Page Controller modal (in `lib/features/notes/pages/page_controller_screen.dart`):

- Removed separate `ProviderScope` so the modal shares the same container as the editor.
- On page tap: if routeId present, `jumpToPage(index)` + set `currentPageIndexProvider(index)`; else fallback to provider set.
- We do not treat modal as a “leave editor” event: didPushNext no longer writes resume/lastKnown for overlays.

Router wiring (in `lib/features/canvas/routing/canvas_routes.dart`):

- Pass `routeId` to `NoteEditorScreen` using `state.pageKey`.

---

## Error Timeline and Fixes

1. didPushNext provider write → build‑time mutation error

- Symptom: “Tried to modify a provider while the widget tree was building”.
- Cause: Writing resume/lastKnown inside `didPushNext` (route transition phase).
- Fix: Defer writes with `WidgetsBinding.instance.addPostFrameCallback`.

2. Provider init writing another provider → init‑time mutation error

- Symptom: “Providers are not allowed to modify other providers during their initialization”.
- Cause: `pageControllerProvider` wrote `currentPageIndexProvider` and consumed resume during its own build.
- Fix: Make `pageControllerProvider` read‑only; move all mutation to screen post‑frame (`_scheduleSyncInitialIndexFromResume`).

3. Page Controller modal didn’t move the editor

- Symptom: Thumbnail tap did not change the editor page.
- Cause: Modal opened under a separate `ProviderScope`, so it read/wrote in a different container; `jumpToPage` called on the wrong controller instance.
- Fix: Remove modal `ProviderScope`; share container with editor. Also keep provider set as fallback.

---

## Final Behavior (Acceptance)

- A(a) → B → A(a) → A(aa) → B(back) → A(back)
  - A2 restores `aa`, then A1 restores `a`. No overwrite between instances.
- On return to an editor, page counter and visible page match from the first interactive frame; no flicker/mismatch.
- Page Controller modal: tapping a page immediately navigates the editor to that page and persists.

---

## End‑to‑End Data Flow

1. Navigate away from a route (link/backlink tap)

- Save sketch → read `routeId` → `resumeMap.save(routeId, currentIndex)` → `lastKnown.setValue(currentIndex)` → push route.

2. Return to a route (back from the next screen)

- didPopNext/build‑guard: set session + routeId → post‑frame:
  - read `resumeMap.peek(routeId)`; if null and initial entry, optionally use `lastKnown`.
  - clamp and set `currentPageIndexProvider` → if resume was used, `resumeMap.take(routeId)`.

3. Pop editor route

- Save sketch → post‑frame: `lastKnown.setValue(currentIndex)` and `resumeMap.remove(routeId)` → exit session + clear routeId.

4. Page Controller modal page tap

- If controller has clients: `jumpToPage(index)` → set `currentPageIndexProvider(index)` → close modal.
- Else: set provider first; controller listener performs the jump when attached.

---

## Riverpod & Flutter Lifecycle Rules We Follow

- Do not write providers during:
  - Widget build, initState, dispose, didUpdateWidget, didChangeDependencies.
  - Provider initialization (inside provider factories/build methods).
  - Route transitions (didPush/didPushNext) unless deferred to post‑frame.
- Use `WidgetsBinding.instance.addPostFrameCallback` for cross‑provider writes triggered by lifecycle events.
- Distinguish overlays (dialogs/sheets) from real route changes; avoid treating overlays as “leave editor”.

---

## Testing Checklist

- Unit
  - resumeMap: save/peek/take/remove behavior
  - initial index computation (clamp, fallbacks)
- Widget
  - A(a) → B → A(a) → A(aa) → B(back) → A(back)
  - Page Controller modal select page → editor moves & persists
  - Cold re‑open returns to `lastKnown`

---

## Opportunities to Clean Up (Same Logic, Cleaner Structure)

- Resume Coordinator

  - Create a small module (`route_resume_coordinator.dart`) exposing:
    - `saveBeforeNavigate(ref, noteId, routeId, index)`
    - `syncOnEnter(ref, noteId, routeId, {bool allowLastKnown})`
    - `onPop(ref, noteId, routeId, index)`
  - Centralizes policy and post‑frame scheduling; removes duplication from screen/widgets.

- Navigation Facade

  - `NavigationActions.navigateToNote(ref, context, currentNoteId, targetNoteId, {targetPageId})`
  - Performs sketch save, per‑route resume save, route push, and optional target page set uniformly.

- Initial Index Provider

  - `initialPageIndexProvider(noteId, routeId)` returns pure initial index (no side effects).
  - `pageControllerProvider` depends only on this value for `initialPage`.

- Route Lifecycle Helper

  - Utility with `enter(noteId, routeId)`, `reenter(noteId, routeId)`, `exit(noteId)` that internally schedules `syncOnEnter`.

- Frame Scheduler Utility

  - `FrameScheduler.runPostFrameOnce(key, fn)` to avoid duplicate post‑frame calls.

- Strong Typing for Route Ids
  - Introduce a `RouteInstanceId` value object to replace raw strings.

These refactors keep the logic identical but make responsibilities explicit and remove repeated wiring from widgets.

---

## Files Touched (for reference)

- Providers: `lib/features/canvas/providers/note_editor_provider.dart`
- Router: `lib/features/canvas/routing/canvas_routes.dart`
- Editor Screen: `lib/features/canvas/pages/note_editor_screen.dart`
- Canvas: `lib/features/canvas/widgets/note_editor_canvas.dart`
- Backlinks/Link taps: `lib/features/canvas/widgets/panels/backlinks_panel.dart`, `lib/features/canvas/widgets/note_page_view_item.dart`
- Page Controller Modal: `lib/features/notes/pages/page_controller_screen.dart`

---

## TL;DR

- Use per‑route resume (Map<routeId,int>) and consume on restore.
- Never write providers during provider build or route transition; defer with post‑frame.
- Share ProviderContainer across UI that needs to cooperate (e.g., editor and modal).
- Keep last‑known per note for cold re‑open, but don’t let it overwrite modal selections on return.

---

> Key Things To Know

- Per-route resume is live - Use resumePageIndexMapProvider(noteId) (Map<routeId,int>) for storing “return-to-here” indices. Don’t use the old single-slot
  resumePageIndexProvider. - Use noteRouteIdProvider(noteId) to fetch the active routeId inside the editor route. - Optional cold re-open: lastKnownPageIndexProvider(noteId). - Optional cold re-open: lastKnownPageIndexProvider(noteId).
- PageController now requires routeId - pageControllerProvider(noteId, routeId) is the source of truth for the PageView controller. - NoteEditorCanvas and any other consumer must pass routeId. Without routeId, jumps may not apply.
- No provider writes during forbidden phases - Don’t modify providers during: - Widget build/initState/dispose/didUpdateWidget/didChangeDependencies - Provider initialization (inside provider factories) - Route transitions (didPush/didPushNext) unless deferred
- If you must write as part of a lifecycle, wrap in WidgetsBinding.instance.addPostFrameCallback.
- Modal must share provider container - Do not wrap the page controller modal in a separate ProviderScope. It must share the editor’s container to control the same
  PageController and providers.
- Navigation entrypoints must save resume before push - For new link/backlink entrypoints: - Save sketch for current note (fire-and-forget). - Read `routeId = ref.read(noteRouteIdProvider(noteId))`. - Save resume with `resumePageIndexMapProvider(noteId).notifier.save(routeId, currentIndex)`. - Optionally update `lastKnownPageIndexProvider(noteId)`. - Then push the new route.
- Treat overlays (dialogs/sheets) as not leaving the editor: don’t save resume/lastKnown in didPushNext for these.
- Restore happens post-frame - The screen calls a post-frame sync that: - Reads resume by routeId (or lastKnown on first entry), clamps to bounds - Updates `currentPageIndexProvider(noteId)` and consumes resume (take)
- Do not reintroduce provider writes inside pageControllerProvider build.
- PageView jump coordination - Keep using pageJumpTargetProvider(noteId) to ignore spurious onPageChanged callbacks during programmatic jumps. - If adding new ways to change pages, set currentPageIndexProvider and let the controller listener jump; or jump and set both in the same
  event handler.

Common Pitfalls To Avoid

- Forgetting routeId - Not passing routeId to pageControllerProvider or reading noteRouteIdProvider from a different container (e.g., a modal with its own
  ProviderScope) will break jumps. - Not passing routeId to pageControllerProvider or reading noteRouteIdProvider from a different container (e.g., a modal with its own
  ProviderScope) will break jumps.
- Writing during route transitions - Writing resume or lastKnown in didPushNext or similar will cause “modify provider while building” asserts. Always defer with post-
  frame.
- Overwriting user selection on return - Don’t let lastKnown overwrite the page chosen via modal when returning from overlays. On didPopNext for overlays, prefer resume only
  (the screen already does this).

Where To Look

- Data flow and policies: docs/per-route-resume-navigation.md
- Providers and controller:
  - lib/features/canvas/providers/note_editor_provider.dart
- Editor lifecycle with resume:
  - lib/features/canvas/pages/note_editor_screen.dart
- Canvas and controller usage:
  - lib/features/canvas/widgets/note_editor_canvas.dart
- Navigation save points:
  - lib/features/canvas/widgets/panels/backlinks_panel.dart
  - lib/features/canvas/widgets/note_page_view_item.dart
- Page controller modal (shares container, jumps + provider set):
  - lib/features/notes/pages/page_controller_screen.dart

Implementation Tips

- Add a new navigation action?
  - Save sketch → resumeMap.save(routeId, idx) → lastKnown.setValue(idx) → navigate → optionally set target page on arrival (post-frame).
- Add a new modal/overlay?
  - Don’t treat it as leaving the editor; don’t save resume in lifecycle. Ensure it uses the same ProviderContainer.
- Changing page programmatically? - If in an event handler, call controller.jumpToPage(idx) when hasClients, and update currentPageIndexProvider too. If no clients,
  schedule post-frame.
