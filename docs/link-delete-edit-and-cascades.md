# Link Delete/Edit + Cascades — How It Works

This note documents what we implemented for link deletion and editing, and how link cascades run when deleting notes/pages. It summarizes the user flows, data path, files, and how to verify.

## TL;DR
- Delete link: Actions sheet → confirm → `LinkRepository.delete(id)` → streams update → SavedLinksLayer refreshes.
- Edit link: Actions sheet → reuse creation dialog → controller retargets (self‑link blocked) → `LinkRepository.update(updated)` → streams update.
- Delete page: `PageManagementService.deletePage` deletes outgoing links for that page, then the page.
- Delete note: `NoteDeletionService.deleteNoteCompletely` deletes outgoing links for all pages + incoming links to the note, then deletes the note.

## User Flows

### Delete Link (UI)
1) Tap a saved link (panel or canvas) → Actions sheet
2) Select “링크 삭제” → confirm dialog
3) On confirm: `linkRepo.delete(link.id)`
4) Result: Saved rectangle disappears immediately; any backlinks list updates

### Edit Link (UI)
1) Tap a saved link → Actions sheet
2) Select “링크 수정” → reuse LinkCreationDialog (pick/enter target note)
3) Controller retargets (and label update if supplied); self‑link is blocked
4) On success: Backlinks reflect new target; outgoing stays (same source page)

### Delete Page (Service cascades)
- `PageManagementService.deletePage(noteId, pageId, notesRepo, linkRepo: …)`
  - Deletes all outgoing links for `pageId` via `linkRepo.deleteBySourcePage(pageId)`
  - Deletes the page and remaps pageNumber (existing behavior)

### Delete Note (Service cascades)
- `NoteDeletionService.deleteNoteCompletely(noteId, repo: notesRepo, linkRepo: …)`
  - Deletes outgoing links for all pages of the note: `deleteBySourcePage(pageId)`
  - Deletes incoming links to that note: `deleteByTargetNote(noteId)`
  - Deletes the note from `NotesRepository`

## Data Path and Files

- UI
  - Actions sheet: `lib/features/canvas/widgets/dialogs/link_actions_sheet.dart`
  - Editor wiring: `lib/features/canvas/widgets/note_page_view_item.dart`
    - Delete: confirm → `linkRepo.delete(link.id)`
    - Edit: open `LinkCreationDialog` → `linkCreationController.updateTargetLink(…)`
- Controller
  - `lib/features/canvas/providers/link_creation_controller.dart`
    - `updateTargetLink(link, {targetNoteId|targetTitle, label?})`
    - Resolves target note (creates if needed), blocks self‑link, calls `linkRepo.update`
- Repository (interface + memory)
  - `lib/shared/repositories/link_repository.dart`
    - Added cascade APIs: `deleteBySourcePage`, `deleteByTargetNote`, `deleteBySourcePages`
  - `lib/features/canvas/data/memory_link_repository.dart`
    - Implemented cascades using in‑memory indexes; emits affected streams
- Services
  - `lib/shared/services/page_management_service.dart`
    - `deletePage(…, linkRepo: …)` deletes outgoing links, then page
  - `lib/shared/services/note_deletion_service.dart`
    - `deleteNoteCompletely(…, linkRepo: …)` deletes outgoing+incoming links, then note delete
  - Callers updated to pass `linkRepo` where needed

## Streams and UI Refresh
- Outgoing (page): `linksByPageProvider(pageId)` updates → `linkRectsByPageProvider` → `SavedLinksLayer` redraws
- Backlinks (note): `backlinksToNoteProvider(noteId)` updates (when edit/delete retargets/clears)
- No manual UI refresh required; providers drive repaint

## Safety and Guards
- Self‑link blocked in both create and update flows
- Streams emit even when deletes find nothing (clear stale views)
- Confirm dialogs shown for delete link and delete note (page delete confirm is handled by the host UI)

## Logging (debug)
- Link edit (controller):
  - `[LinkEdit] start …` / `[LinkEdit] updated link …`
- Link edit/delete (UI):
  - `[LinkEdit/UI] …`, `[LinkDelete/UI] …`
- Cascades (repo/service):
  - `🧹 [LinkRepo] deleteBySourcePage …`, `deleteByTargetNote …`, `deleteBySourcePages …`
  - `🧹 [LinkCascade] Outgoing deleted: X …`, `Incoming deleted: Y …`

## How to Verify (Manual)
- Create a link; open Actions sheet; delete → rect disappears
- Edit a link; retarget to another note → outgoing rect remains; backlinks on new target show item; old target’s backlinks remove item
- Delete a page → its links disappear from the page; backlinks update
- Delete a note → both outgoing and incoming links related to that note disappear

## Future Enhancements
- Backlinks panel (incoming + outgoing lists) with on‑tap navigation
- Label field for edit dialog and label rendering near rects
- Multi‑select delete UI
- Isar implementation (transactions + indexed deletes)
