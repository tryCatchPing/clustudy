# Vault Delete Feature Plan

## Current State
- **Repository layer**: `VaultTreeRepository.deleteVault(...)` is implemented in
  both memory and Isar variants, cascading removal of folders and note
  placements.
- **Service/UI**: `VaultNotesService` and the presentation layer do not expose
  vault deletion. No orchestrated cleanup (notes, links, files) currently
  happens when deleting a vault.

## Goals
1. Provide a high-level method to delete a vault along with its contents,
   ensuring consistency across notes, links, and file storage.
2. Surface the capability in the UI with appropriate confirmation and state
   refresh.

## Implementation Steps

### 1. Service Layer Orchestration
- Add `Future<void> deleteVault(String vaultId)` to `VaultNotesService`.
- Logic overview:
  1. Resolve all notes contained in the vault (including nested folders) using
     existing traversal helpers (`watchVaults`, `watchFolderChildren`, etc.).
  2. Within `dbTxn.writeWithSession`, iterate through the collected note IDs
     and invoke link/notes/vault repositories with the shared session:
     - `linkRepo.deleteByTargetNote`
     - `linkRepo.deleteBySourcePages` for each note’s pages
     - `notesRepo.delete`
     - `vaultTree.deleteNote`
  3. After notes are cleared, call `vaultTree.deleteVault`
     (passing the session) to remove folders, placements, and the vault record.
  4. Outside the transaction, delete note file directories via
     `FileStorageService.deleteNoteFiles` for each note.
- Consider returning a result or throwing descriptive errors when the vault is
  missing, and log warnings for partial cleanup issues.

### 2. UI Integration
- Identify the vault list screen (likely under `lib/features/vaults/...`).
- Add a delete affordance (menu or long-press action) per vault with a
  confirmation dialog describing the cascading deletion.
- Invoke `vaultNotesService.deleteVault(vaultId)` and refresh state by relying
  on existing Riverpod providers streaming vault lists.

### 3. Testing
- Extend `Isar` integration tests (`test/integration/isar_end_to_end_test.dart`)
  to cover vault deletion, verifying:
  - Notes, folders, placements, and links are removed.
  - Repositories throw no nested transaction errors.
  - File deletion S3 mocked or verified via a fake storage service in tests.
- Add unit tests for `VaultNotesService.deleteVault` using fake repositories and
  stubs to assert orchestration order and error handling.

### 4. Documentation
- Update README or feature documentation to mention the new capability.
- Add usage notes to `docs/` if needed (e.g., warnings about irreversible
  deletion and expected lifecycle).

## Risks & Mitigations
- **Large vaults**: Deletion loops may be long-running. Ensure UI shows
  progress/spinner and consider batching file operations.
- **Error handling**: Partial failures (e.g., file deletion failure) should be
  logged and not leave database entries behind. Structuring the transaction as
  above prevents DB inconsistencies.
- **Undo/Recovery**: The current scope is hard deletion; if undo is desired
  later, consider introducing archival state instead of permanent removal.
