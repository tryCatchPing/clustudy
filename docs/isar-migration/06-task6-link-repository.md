# Isar Link Repository Notes (Task 6)

This document captures how the link persistence layer moved from
memory-only to Isar-backed storage.

## Interface Extensions

- `LinkRepository` now exposes utility methods beyond the original CRUD
  and watchers:
  - `getBacklinksForNote`, `getOutgoingLinksForPage`
  - `getBacklinkCountsForNotes`
  - Batch helpers `createMultipleLinks`, `deleteLinksForMultiplePages`
- The in-memory implementation gained the same behaviour so tests and
  pre-Isar flows continue to work.

## IsarLinkRepository Highlights

- Watchers (`watchByPage`, `watchBacklinksToNote`) use `Stream.multi`
  around Isar query `watch` calls. Results are sorted by `createdAt`
  before mapping to domain models, matching the deterministic ordering
  the memory repo provided.
- Write operations (`create`, `update`, `delete*`) run inside
  `isar.writeTxn`. Indexes on `sourcePageId`, `targetNoteId`, and the
  composite `sourceNoteId+targetNoteId` keep reads and deletes efficient.
- Batch helpers simply loop within a single transaction—good enough for
  current load, and easily optimized later using `putAll/deleteAll` if
  profiling indicates a bottleneck.
- Relationship links (`note`/`notePage`) are not persisted yet because
  no consumer relies on them; add them when a feature needs relational
  navigation.

## Memory Repository Updates

- Added parity implementations for the new API surface (note count
  aggregation, batch helpers). Tests cover these additions.

## Testing

- `test/features/canvas/data/memory_link_repository_test.dart` verifies
  the new in-memory helpers (`getBacklinksForNote`, counts, batch ops).
- `test/features/canvas/data/isar_link_repository_test.dart` exercises
  reactive streams, batch creation, backlink counts, and bulk deletion
  against a temporary Isar instance (with a mocked path provider).

Tests are run via:

```bash
fvm flutter test test/features/canvas/data
```

## Remaining work

- Provider wiring still defaults to the memory repository; swap in
  `IsarLinkRepository` once the remaining Isar tasks land.
- Consider extracting reusable helpers for linking entities when the
  `NotesRepository` arrives, so both repos can share relationship code.

With these changes the link layer is ready for the downstream services
to take advantage of indexed Isar queries while preserving the existing
API surface.
