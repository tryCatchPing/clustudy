# Isar Vault Tree Repository Notes (Task 5)

These notes describe how the vault/folder/note-tree repository was
ported to Isar and how the supporting APIs were updated.

## Repository contracts

- Extended `VaultTreeRepository` with:
  - `getFolder` for fetching a single folder.
  - `getFolderAncestors`/`getFolderDescendants` for hierarchy traversal.
  - `searchNotes` for indexed note lookups.
- Memory implementation grew matching behavior so existing call sites
  continue to work outside Isar (e.g., unit tests, fallback modes).

## IsarVaultTreeRepository highlights

- Watch APIs (`watchVaults`, `watchFolderChildren`) use
  `Stream.multi` + Isar’s `watch` to deliver reactive updates. Folder
  and note placement watches run in parallel and emit only after both
  streams report (mirrors the previous in-memory semantics).
- CRUD helpers `_requireVault`, `_requireFolder`, `_requirePlacement`
  centralize existence checks and surface consistent errors.
- Move operations validate cross-vault constraints and guard against
  cycles by traversing parents before committing.
- Cascading deletes for folders collect descendant IDs and clear
  placements in a single transaction to keep the tree consistent.
- Note/placement creation reuses `NameNormalizer` rules and attempts to
  link Isar relationships (`vault`, `parentFolder`, `note`) when the
  linked entities exist.
- `searchNotes` pushes filtering to Isar (case-insensitive `contains`
  when needed) and then scores in memory (exact > prefix > substring),
  returning normalized order and respecting caller-provided limits.

## Service integration

- `VaultNotesService.searchNotesInVault` now delegates to the repository
  and only concerns itself with resolving parent folder names
  (cached per request). Legacy BFS scoring logic is gone.

## Memory repository parity

- Added ancestor/descendant helpers and a repository-level
  `searchNotes` implementation that preserves the previous scoring
  behavior so existing flows (and tests when running in-memory) stay the
  same.

## Testing & verification

- Analyzer runs clean aside from pre-existing lint info messages.
- `fvm flutter test` cannot currently run because the sandboxed macOS
  image lacks an accepted Xcode/git setup; repo state compiles, and the
  new repository is ready for integration tests once the environment
  allows `git` execution.

These changes set up the vault tree layer to operate directly on Isar
while keeping compatibility with the legacy memory implementation until
it is retired.
