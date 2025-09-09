# Post–Backlinks Panel Refactor: Navigation, Saving, Providers

> Base commit: a2d3cf3d28955a4dd177c1301c448f139563ed3f (Backlinks panel + navigation)
>
> Status: Completed. This document records the problems we hit, why they were problems, what we planned, and how we implemented and verified the fixes. It is written so newer teammates can follow the reasoning and seniors can quickly validate the trade‑offs.

---

## 1. What Started Breaking (Symptoms)

- GlobalKey collision during link navigation
  - “Multiple widgets used the same GlobalKey.”
  - Cause context: Two editor screens existed in the tree at once.
- Session not re‑entering on back
  - With `maintainState=false`, old instances don’t receive `didPopNext`.
- Autosave crashed editing + erased undo/redo
  - Periodic autosave triggered repo emits → providers recreated CSNs mid‑gesture → “used after disposed”.
- Page change didn’t always save the page you left
  - Toolbar/programmatic navigation sometimes skipped the previous page save.
- Programmatic jumps drifted (+1)
  - `animateToPage` fired intermediate onPageChanged callbacks → index/state drift.
- New pages: immediate jump sometimes landed on an earlier page
  - Controller not attached yet or `itemCount` not updated at tap time.
- Pointer input policy inconsistent
  - Scribble vs Linker didn’t always share the same policy source.
- CSNs (CustomScribbleNotifiers) were recreated on JSON save
  - Provider was watching the full note stream; any save emitted and caused rebuilds.

Why each symptom mattered

- GlobalKey: Flutter requires unique ownership per tree; collisions crash.
- Session timing: Users land in editor with no active session; CSN tree becomes invalid.
- Autosave: Mid‑gesture provider churn destroys UX and can corrupt runtime state.
- Saving: Users expect “leave page = save what I drew there”.
- Jumps: Editors should land exactly on the requested page, not pass through others.
- Races: Modern UIs require embracing attach/itemCount readiness; code must be resilient.
- Policy: Input should behave uniformly across tools and surfaces.
- CSN stability: Runtime drawing state must be the single source of truth while editing.

---

## 2. Design Principles We Chose

- One editor screen at a time
  - Use `MaterialPage(maintainState=false, key: state.pageKey)` to avoid double mounts.
- Guard session re‑entry
  - Add a build‑time guard to enter the session when the route becomes current.
- Save only at meaningful boundaries
  - Page change → save the page you’re leaving.
  - Link/backlink push and back pop → save before transition.
  - No periodic autosave. No “save all pages” (we tried, then removed).
- Keep CSNs stable
  - Do not watch note/JSON streams. Initialize once from a snapshot; then apply changes via setters.
- Make jumps precise, resilient, and idempotent
  - Use `jumpToPage` instead of `animateToPage`.
  - Support pending jumps when controller isn’t attached or pages aren’t ready; retry after `itemCount` updates.
  - Ignore spurious `onPageChanged` while a programmatic jump is in progress (target guard).
- Use one global pointer policy
  - App‑wide `ScribblePointerMode` drives both Scribble and Linker.
- Providers watch only what they must
  - Structure‑only watchers (page IDs/count), not JSON content.

---

## 3. Implementation Summary (Files + Rationale)

Routing & Session

- `lib/features/canvas/routing/canvas_routes.dart`
  - Switch to `pageBuilder` → `MaterialPage(maintainState=false, key: state.pageKey)`.
  - Rationale: Prevent two editors in the tree; unique page key avoids Navigator key duplication.
- `lib/features/canvas/pages/note_editor_screen.dart`
  - RouteAware: `didPush`/`didPop` → session enter/exit.
  - Build guard: if current route and session isn’t this note → enter session.
  - Rationale: With `maintainState=false`, the old instance won’t get `didPopNext`. Guard ensures re‑entry.

Save Policy

- `lib/shared/services/sketch_persist_service.dart`
  - Centralized repo‑based JSON saves (emit and silent variants). No periodic autosave usage.
- Save calls (save‑before‑change)
  - `lib/features/canvas/widgets/note_editor_canvas.dart` (PageView.onPageChanged → save previous index)
  - `lib/features/canvas/widgets/controls/note_editor_page_navigation.dart` (toolbar prev/next/jump)
  - `lib/features/canvas/widgets/panels/backlinks_panel.dart` (panel taps)
  - `lib/features/canvas/widgets/note_page_view_item.dart` (link action sheet navigate)
  - Rationale: Users switch at these moments; saves won’t interrupt drawing.

Models/Repository

- `lib/features/notes/models/note_page_model.dart`
  - `jsonData`/`showBackgroundImage` → `final`; removed in‑place mutators.
- `lib/features/notes/data/notes_repository.dart`
  - Added `updatePageJson`, `updatePageJsonSilent` interfaces.
- `lib/features/notes/data/memory_notes_repository.dart`
  - Implemented both methods; silent variant doesn’t emit → avoids CSN churn.

CSN Stability & Provider Dependencies

- `lib/features/canvas/providers/note_editor_provider.dart`
  - `canvasPageNotifier(pageId)`
    - Watch: `noteSessionProvider`, `noteProvider(noteId).select(hasValue)`.
    - Read: `noteProvider(noteId).value` (snapshot) → `setSketch()` once.
    - Listen: Tool settings, SimulatePressure, PointerPolicy → setters (no recreation).
  - `notePageIdsProvider(noteId)`
    - Derived page IDs; structure only.
  - `currentNotifier(pageId)` / `pageNotifier(noteId, index)`
    - Watch: `currentPageIndexProvider(noteId)`, `notePageIdsProvider(noteId)`.
    - Return CSN via `canvasPageNotifier(pageId)`.
  - `pageController(noteId)`
    - Listens to `currentPageIndexProvider` & `notePagesCountProvider`.
    - Uses `jumpToPage`, pending retry, and target guard (`pageJumpTargetProvider`).
  - Rationale: CSNs are not recreated on JSON saves; only structure changes cause dependent rebuilds.

PageView Sync & Guards

- `lib/features/canvas/providers/note_editor_provider.dart`
  - `PageController`: pending jump + retry on page count; `jumpToPage` only.
  - `pageJumpTargetProvider`: flag to ignore spurious onPageChanged while jumping.
- `lib/features/canvas/widgets/note_editor_canvas.dart`
  - `onPageChanged`: ignore mismatching indices during a programmatic jump; save prev page and update current index otherwise.

Global Pointer Policy (Scribble + Linker)

- `lib/features/canvas/providers/pointer_policy_provider.dart` (new)
  - `StateProvider<ScribblePointerMode>`; default `all`.
- `lib/features/canvas/widgets/controls/note_editor_pointer_mode.dart`
  - UI toggles global pointer policy (not per‑page CSN state).
- `lib/features/canvas/widgets/note_page_view_item.dart`
  - `LinkerGestureLayer.pointerMode` now derived from global policy.
- `lib/features/canvas/providers/note_editor_provider.dart`
  - CSNs apply initial policy and listen for changes via setter.

Cleanup

- Removed deprecated `canvasSessionProvider` alias; added a small note to `docs/histories/session_problem_solving.md` clarifying `noteSessionProvider` is the canonical name.

---

## 4. Troubleshooting Journey (What We Tried & Learned)

1. GlobalKey collision

- Observed: Two editors alive; crash.
- Fix: `maintainState=false` + `state.pageKey`. One editor at a time, unique keys.

2. Session re‑entry

- Observed: With `maintainState=false`, old instance doesn’t receive `didPopNext`.
- Fix: Build‑guard re‑enters if current; still keep RouteAware enter/exit for push/pop.

3. Autosave causing crashes/history loss

- Observed: “used after disposed” mid‑draw; undo/redo resets.
- Root cause: notes stream watch → emit on save → CSN recreated.
- Fix: Removed periodic autosave; only save at transitions. CSNs no longer watch note content.

4. Page change save gaps

- Observed: Programmatic changes sometimes didn’t save previous page.
- Fix: Save via tracked `prevIndex` (not provider’s updated index); ensure toolbar/panel saves before changing.

5. Programmatic jump drift

- Observed: animateToPage fired multiple onPageChanged; drifted to current+1.
- Fix: Use `jumpToPage` and a jump target guard to ignore spurious callbacks.

6. New pages jump race

- Observed: Tap a just‑added page; landed at index 1.
- Root cause: controller attach/itemCount not ready.
- Fix: Pending jump with retries after page count; modal tap does immediate/scheduled jump + provider update + next‑frame pop.

7. Pointer policy inconsistency

- Observed: Scribble and Linker could diverge.
- Fix: Global `pointerPolicyProvider`; CSNs and Linker read the same policy; UI toggles global state.

8. CSN recreation on save

- Observed: notes stream watch caused CSNs to recreate on every emit.
- Fix: canvasPageNotifier watches only session + data readiness; reads snapshot once; listens to setters for runtime changes.

---

## 5. Verification Checklist (How to Know It’s Working)

- Navigation
  - Backlinks/links land exactly on target page.
  - Page controller modal tap jumps exactly to tapped page, including newly added ones.
  - Toolbar prev/next/jump always saves before changing and lands accurately.
- Stability
  - No “Multiple widgets used the same GlobalKey.”
  - No “used after being disposed” during drawing.
  - Undo/redo history preserved when switching pages.
- Saving
  - Logs show save on transitions only (no periodic autosave).
  - Previous page saves occur from onPageChanged with the correct prev index.
- Input
  - Pointer mode toggles update both Scribble and Linker uniformly.

---

## 6. Provider Dependency Map (Minimal Watch Surface)

- CSN per page (`canvasPageNotifier(pageId)`)
  - Watch: `noteSessionProvider`, `noteProvider(noteId).select(hasValue)`
  - Read once: `noteProvider(noteId).value` → `setSketch()`
  - Listen: `toolSettings`, `simulatePressure`, `pointerPolicy` (setter only)
- Current/page CSN selectors (`currentNotifier`, `pageNotifier`)
  - Watch: `currentPageIndex`, `notePageIds` (structure only)
  - Return: `canvasPageNotifier(pageId)`
- PageView sync (`pageController`, `pageJumpTarget`)
  - Listen: `currentPageIndex`, `notePagesCount` (retry pending)
- Structure derivations
  - `notePageIds`, `notePagesCount` from `noteProvider(noteId)`
- Global policies
  - `pointerPolicyProvider`, `simulatePressureProvider`

---

## 7. Future Work (Optional)

- Dirty‑flag autosave (silent) with 10–30s throttle and “not drawing” guard.
- Offload large JSON serialization to `compute`/isolate for smoother UI.
- Route‑key viewport restore on back pops (page index + matrix).
- Trim debug logs behind feature flags.

---

## 8. Takeaways for Juniors

- Only watch what you must. Watching large streams (like full note content) will rebuild too much and cause runtime state churn.
- Save at user‑intent boundaries, not in the middle of interaction. This keeps the UX responsive and state stable.
- Embrace attach/itemCount readiness. Use pending retries and guard flags to make programmatic navigation predictable.
- Prefer setters on long‑lived runtime objects (like CSNs) instead of recreating them.

---

## 9. Glossary

- CSN: CustomScribbleNotifier — our runtime drawing state holder per page.
- Emit: Repository stream push; causes watchers to rebuild.
- Programmatic jump: A jump triggered by code (toolbar, modal, backlink), not a user swipe.
- Spurious callback: An `onPageChanged` call that doesn’t match the intended target during a programmatic jump.
