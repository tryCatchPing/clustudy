# Isar Migration Foundations (Tasks 1 & 2)

This document captures the intent behind the groundwork committed right
before we start Task 3 (mapper implementations). Treat it as a companion
reference when you revisit the code or rebuild the logic from scratch.

## Why these changes were necessary

- **Replace the dummy Isar schema:** Task 1 originally relied on a
  placeholder `DummyEntity` just to open an Isar instance. Now that we
  have real collections from Task 2, the dummy schema is gone. Instead
  we persist a `DatabaseMetadataEntity` that tracks schema version and
  migration timestamps.
- **Surface schema/migration state:** Having a managed metadata row lets
  us confirm the on-disk version and gives us a place to hook real
  migrations later. The service updates seed the metadata if it is
  missing and bump the stored version when `_currentSchemaVersion`
  increases.
- **Collect filesystem diagnostics:** `getDatabaseInfo()` now resolves
  a deterministic path (e.g. `<app-docs>/databases/it_contest_db`) and
  walks the directory to estimate size. This is valuable for debugging
  and test assertions while we iterate on migrations.
- **Quiet logging:** The service previously used `print`. We swapped it
  with `debugPrint` so the analyzer stays happy (`avoid_print`) and so
  logs respect Flutter’s debug filtering.

## Relationship wiring added in Task 2

- `VaultEntity.notePlacements` and `FolderEntity.notePlacements` are
  `@Backlink` relationships so we can fetch all placements under a
  vault/folder without manual filtering.
- `NoteEntity.placement` is now a backlink to its single
  `NotePlacementEntity`. This makes mapper work symmetric (domain model
  already assumes a 1:1 relationship).
- `LinkEntity` gained a composite index from `sourceNoteId` to
  `targetNoteId`, aligning with the plan’s requirement for fast backlink
  lookups.

## Service details worth remembering

- `_initializeDatabase` records the database directory and registers all
  schema objects, including `DatabaseMetadataEntity`. Whenever you add
  a new entity, it must be part of this list before running
  `build_runner`.
- `_performMigrationIfNeeded` is the central hook for real migrations.
  When `_currentSchemaVersion` increments, insert the logic here, then
  update the metadata just like we do now.
- `clearDatabase()` now re-seeds metadata after wiping collections. The
  service ensures tests still start with a valid version record.
- `_calculateDatabaseSize()` intentionally ignores non-Isar files. It’s
  a lightweight heuristic so we do not rely on Isar internals that might
  change.

## Tests and tooling

- `test/shared/services/isar_database_service_test.dart` asserts the new
  metadata-driven behaviour: the path includes the database name and the
  collections list contains all schemas (including the metadata store).
- After any entity or service change, run:
  ```bash
  fvm dart run build_runner build --delete-conflicting-outputs
  fvm flutter test test/shared/services/isar_database_service_test.dart
  ```
  The first command regenerates Isar adapters; the second validates the
  service contract.

## Guidance for Task 3 and beyond

- The new backlinks mean mapper implementations can traverse entity
  relationships without performing manual joins. For example, a
  `VaultEntity` brings along its `notePlacements` backlinks which you
  can convert to domain models.
- Use `DatabaseMetadataEntity` when you introduce migration scripts in
  Task 11. Schema version checks should branch off the stored value and
  update `lastMigrationAt` once complete.
- Keep `debugPrint` usage consistent elsewhere to avoid `avoid_print`
  lint noise.
- If you add more diagnostics, prefer extending `DatabaseInfo` rather
  than sprinkling prints (e.g. track collection counts or last compact
  timestamp).

With this foundation the project is ready for Task 3’s mapper work and
later the repository swaps. Feel free to adapt the patterns here, but
keep the metadata entry and backlinks intact—they anchor our migration
path.
