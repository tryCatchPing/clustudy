# Isar DB Migration — Tasks 1–2 Implementation Notes

This document explains what we built in Tasks 1 and 2, why we made
those choices, and how to run and troubleshoot the setup. It is written
to help future you (or a teammate) quickly rebuild context and refactor
with confidence.

## Goals

- Replace memory-only storage with IsarDB while keeping existing
  repository interfaces intact.
- Establish a minimal, reliable database infrastructure, tests, and
  codegen pipeline before porting business logic.
- Define core entities (vault, folder, note, page, link, placement)
  with indexes/links optimized for real usage.

## What Changed (At a Glance)

- Dependencies added in `pubspec.yaml`:
  - `isar`, `isar_flutter_libs`, `isar_generator` (all `^3.1.0+1`)
  - Build system: `build_runner`
  - Kept `source_gen` override to prevent analyzer conflicts
- Infrastructure:
  - `lib/shared/services/isar_database_service.dart` (singleton init,
    schema registration, maintenance, test helpers)
  - `lib/shared/services/isar_db_txn_runner.dart` (write transactions)
  - `test/flutter_test_config.dart` (test bootstrap)
  - macOS test fix: copy `libisar.dylib` to project root
- Entities (Task 2):
  - `lib/shared/entities/vault_entity.dart`
  - `lib/shared/entities/note_entities.dart` (Note + NotePage)
  - `lib/shared/entities/link_entity.dart`
  - `lib/shared/entities/note_placement_entity.dart`
  - Schemas are registered in `IsarDatabaseService`.

---

## Task 1 — Dependencies, DB Service, Transactions, Tests

### Why this order

- Prove we can initialize Isar in our app and test environments before
  adding complex entities.
- Lock versions early to avoid `analyzer`/plugin churn during codegen.
- Create a transaction abstraction to keep repositories agnostic.

### Dependencies and versions

These are pinned to Isar 3.x, matching Flutter 3.32.5:

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.13

dependency_overrides:
  source_gen: ^1.5.0
```

Rationale:

- `isar_flutter_libs` bundles native libs for app builds; tests need an
  extra step (see below).
- `source_gen` override reduces known analyzer incompatibilities while
  generators run.

### IsarDatabaseService (singleton)

File: `lib/shared/services/isar_database_service.dart`

- Centralizes Isar initialization, schema registration, and lifecycle.
- Uses app documents directory (creates a `databases` subdirectory).
- Registers schemas for all collections (updated as we add entities).
- Includes maintenance and clear helpers for tests/dev.

Design choices:

- Kept a `DummyEntity` during Task 1 to validate initialization before
  real entities existed. This can be removed after the full schema is
  stable.
- `compactOnLaunch` is configured defensively. Isar 3.x has limited
  runtime compaction hooks; future tuning can move to maintenance jobs.

### Transaction runner

File: `lib/shared/services/isar_db_txn_runner.dart`

- Implements `DbTxnRunner.write` with `isar.writeTxn`.
- Allows repositories to be written against a generic abstraction;
  memory and isar implementations can be swapped.

### Test bootstrapping and macOS FFI

Problem:

- Flutter tests run on the host VM and do not automatically bundle the
  native Isar library.
- Symptom: `Failed to load dynamic library 'libisar.dylib'` in tests.

Fixes we applied:

1. Test bootstrap to ensure Flutter binding and include isar libs.

File: `test/flutter_test_config.dart`

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await testMain();
}
```

2. On macOS, copy the dylib once so tests can find it:

```bash
cp ~/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib .
```

We also imported `isar_flutter_libs` in isar-specific tests to ensure
the bundle is included.

### Useful commands

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test test/shared/services/isar_database_service_test.dart \
  test/shared/services/isar_db_txn_runner_test.dart
```

Troubleshooting:

- If `build_runner` reports '0 outputs', run a clean build:
  `fvm dart run build_runner clean && fvm dart run build_runner build`.
- If analyzer/plugin warnings appear, keep working; we pinned versions
  to avoid hard failures during codegen.

---

## Task 2 — Entity Definitions and Schema Registration

Guiding principles:

- Mirror domain models closely, but keep DB concerns (indexes/links)
  encapsulated in entities.
- Prefer case-insensitive value indexes for display names/titles.
- Use composite indexes for the queries we run most.

### VaultEntity

File: `lib/shared/entities/vault_entity.dart`

- Fields: `id`, `vaultId` (unique), `name` (indexed), `createdAt`,
  `updatedAt`.
- Links: `folders = IsarLinks<FolderEntity>()` (child folders).

Why:

- Vault is the outer scope; we need fast lookup by business ID and
  reactive folder children streams.

### FolderEntity

File: `lib/shared/entities/vault_entity.dart` (same file as Vault)

- Fields: `id`, `folderId` (unique), `vaultId`, `name` (indexed),
  `parentFolderId`, timestamps.
- Indexes:
  - Composite `(vaultId, parentFolderId)` for fast 'children in folder'
    queries.
  - Value index on `name` for case-insensitive search/sort.
- Links: `vault`, `parentFolder`, `childFolders`.

Why:

- Mirrors memory repository's scope key `(vaultId, parentFolderId)` so
  `watchFolderChildren` can be implemented efficiently and reactively.

### NoteEntity and NotePageEntity

File: `lib/shared/entities/note_entities.dart`

- `NoteEntity` fields: `noteId` (unique), `title` (indexed),
  `sourceType` (enum), optional PDF metadata, timestamps.
- `NoteEntity` links: `pages` (IsarLinks to `NotePageEntity`).
- `NotePageEntity` fields: `pageId` (unique), `noteId`, `pageNumber`,
  `jsonData`, background metadata (enum + details), `showBackgroundImage`.
- `NotePageEntity` indexes: composite `(noteId, pageNumber)` for fast
  ordered page traversal.
- `NotePageEntity` links: `note` (backlink).
- Enums: `NoteSourceTypeEntity`, `PageBackgroundTypeEntity` (plain Dart
  enums; we annotate usage with `@Enumerated(EnumType.name)`).

Why:

- Matches domain models used by the canvas and page controller. The
  composite index is critical for reordering and slicing pages.

### LinkEntity

File: `lib/shared/entities/link_entity.dart`

- Fields: `linkId` (unique), `sourceNoteId` (index), `sourcePageId`
  (index), `targetNoteId` (index), bbox fields, optional `label`/
  `anchorText`, timestamps.
- Links: `sourcePage` (link to `NotePageEntity`), `targetNote` (link to
  `NoteEntity`).

Why:

- We need fast queries for:
  - 'Outgoing links by page' → index on `sourcePageId`.
  - 'Backlinks by note' → index on `targetNoteId`.
- We intentionally avoided adding `NotePageEntity.outgoingLinks` to
  keep the type graph simpler (no circular generator work). We can
  still query efficiently via indexes.

### NotePlacementEntity

File: `lib/shared/entities/note_placement_entity.dart`

- Fields: `noteId` (unique), `vaultId`, `parentFolderId`, `name`
  (indexed), timestamps.
- Indexes:
  - Composite `(vaultId, parentFolderId)` for hierarchical queries.
  - Value index on `name` for search/sort within a scope.
- Links: `vault`, `parentFolder`, `note`.

Why:

- Mirrors `NotePlacement` domain model used by the vault tree. This
  allows implementing tree operations (move/rename/list) efficiently
  and reactively.

### Schema registration

`IsarDatabaseService` registers all schemas:

```dart
await Isar.open([
  VaultEntitySchema,
  FolderEntitySchema,
  NoteEntitySchema,
  NotePageEntitySchema,
  LinkEntitySchema,
  NotePlacementEntitySchema,
  // Temporary during early bring-up
  DummyEntitySchema,
], ...);
```

---

## Validation and Tests

- Build codegen: `fvm dart run build_runner build --delete-conflicting-outputs`.
- Analyzer runs clean enough for our scope (non-blocking infos/warnings
  kept minimal around new entities).
- Sanity tests for DB init and txn runner pass on macOS after adding
  test bootstrap and copying `libisar.dylib`.

---

## Known Limitations / Follow-ups

- Remove `DummyEntity` once all entities and repos are wired up.
- Task 3: Add model ↔ entity mappers with unit tests. Pay attention to
  enum conversions and nullable fields.
- Task 4: Switch `dbTxnRunnerProvider` to `IsarDbTxnRunner` and port
  repositories to Isar implementations.
- Consider adding full-text search or additional composite indexes after
  profiling early queries.

---

## Troubleshooting Notes

- 'Failed to load dynamic library libisar.dylib' in tests:
  - Ensure `test/flutter_test_config.dart` exists and imports
    `isar_flutter_libs`.
  - Copy the dylib to project root on macOS (one-time):
    `cp ~/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib .`
- '0 outputs' from build_runner: clean and rebuild.
- Generator crash with `@enumeration` on enums:
  - Use plain Dart enums; annotate enum fields with
    `@Enumerated(EnumType.name)` instead.

---

## File Index (added/updated in Tasks 1–2)

- Entities
  - `lib/shared/entities/vault_entity.dart`
  - `lib/shared/entities/note_entities.dart`
  - `lib/shared/entities/link_entity.dart`
  - `lib/shared/entities/note_placement_entity.dart`
- Service / Txn
  - `lib/shared/services/isar_database_service.dart`
  - `lib/shared/services/isar_db_txn_runner.dart`
- Tests / config
  - `test/flutter_test_config.dart`
  - `test/shared/services/isar_database_service_test.dart`
  - `test/shared/services/isar_db_txn_runner_test.dart`

If you are refactoring later, this document is your map. Skim the
indexes and relationships above to understand where query performance
comes from, and then adjust the entities or add mappers in Task 3.
