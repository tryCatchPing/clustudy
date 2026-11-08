# Isar Mapper Implementation Notes (Task 3)

Use this document when you revisit the mapper layer. It explains the
intent behind each extension, why certain helpers exist, and how the
tests exercise the conversions. The goal is to make it easy to rebuild
or extend the mappers without guessing.

## Overview

Task 3 delivers bidirectional mappers between Isar entities and the
existing domain models. These helpers will be consumed by the upcoming
Isar repositories so the persistence layer can stay thin and avoid
manual field copying.

Key goals:

- Do not mutate the domain models; use mappers to construct new
  instances when data crosses the persistence boundary.
- Preserve Isar `Id` values when updating existing rows so repositories
  can perform upserts without duplicating records.
- Map enums explicitly to avoid surprises if we later add enum cases.
- Provide predictable ordering (e.g. note pages sorted by
  `pageNumber`).

## Vault, Folder, and NotePlacement mappers

File: `lib/shared/mappers/isar_vault_mappers.dart`

- `VaultEntityMapper` → `VaultModel`
  - Straight field mapping for `vaultId`, `name`, timestamps.
  - No attempt to load backlinks here; repository code will decide when
    to call `.load()`.
- `VaultModelMapper` → `VaultEntity`
  - Accepts an optional `existingId` so we can reuse the stored Isar id
    during updates. If `existingId` is omitted it behaves like a fresh
    insert.
- `FolderEntityMapper`/`FolderModelMapper`
  - Handles nullable `parentFolderId` correctly (root folders remain
    `null`).
  - Similar optional id preservation pattern.
- `NotePlacementEntityMapper`/`NotePlacementModelMapper`
  - Keeps the placement metadata (`vaultId`, `parentFolderId`, `name`).
  - Exposing this mapper lets the vault-tree repository hydrate the
    tree without touching note content.

## Note & NotePage mappers

File: `lib/shared/mappers/isar_note_mappers.dart`

- Enum conversion helpers (`_mapNoteSourceType` etc.) keep the switch
  statements local. When we add new enum values, the compiler will force
  us to update the helper instead of silently defaulting.
- `NoteEntity.toDomainModel`
  - Accepts an optional iterable of `NotePageEntity`. We purposely keep
    the load control outside the mapper so repositories can decide when
    to fetch pages.
  - Pages are converted then sorted by `pageNumber` to guarantee domain
    consumers see the expected order even if Isar returns them
    unsorted.
- `NoteModel.toEntity`
  - Mirrors the entity fields and preserves `existingId` when provided.
  - `toPageEntities()` produces the child entities from the domain
    pages. When we attach them in repositories, we can directly set
    their links.
- `NotePageModel.toEntity`
  - Allows overriding the note id with `parentNoteId` so repositories
    can associate pages with an entity id even if the model was built in
    isolation.

## Link mappers

File: `lib/shared/mappers/isar_link_mappers.dart`

- Very direct field mapping between `LinkEntity` and `LinkModel`.
- Optional id is preserved on the entity side as with the other
  mappers.
- Bounding box and metadata fields (`label`, `anchorText`) are copied
  verbatim so we can add validation in repositories without rewriting
  conversion logic.

## Test suite

Directory: `test/shared/mappers`

- `isar_vault_mappers_test.dart`
  - Covers both directions for vault, folder, and placement mappers.
  - Verifies optional ids and nullable parent folder values behave as
    expected.
- `isar_note_mappers_test.dart`
  - Checks enum conversions, note page sorting, and that overridding
    the `noteId` via `parentNoteId` works.
  - Confirms page metadata (like PDF background fields) survives the
    round trip.
- `isar_link_mappers_test.dart`
  - Ensures bounding box, metadata, and ids map correctly in both
    directions.

To run the suite:

```bash
fvm flutter test test/shared/mappers
```

If you touch enums, add a failing test first to prove the mapper breaks
without the new branch in the helper method.

## Extending the mappers

- When new fields are added to domain models or entities, update the
  mapper and add a test that asserts the field survives both directions.
- For new relationships (e.g. backlinks), keep the mapper lightweight.
  Load IsarLinks in the repository, pass the raw entities into the
  mapper, and let the mapper focus on transformation only.
- Maintain line length and documentation guidelines from
  `analysis_options.yaml`; we already provide short descriptions above
  each extension to satisfy the documentation lint.

This mapper layer sits between the repositories and the rest of the
app. Keeping it clean and well-tested makes the Isar repositories easier
to reason about and helps future migrations (e.g. adding a different
persistence backend) stay straightforward.
