# Task 9 – Isar Test Strategy & Lessons Learned

## Why Task 9 Matters

Task 9 converts the migration work into safety nets. With Isar now backing the
repositories, tests are the only guardrail that proves persistence behaves the
same as the old memory implementations. The suite we just added covers three
critical gaps:

1. **Mapper fidelity** – Entity↔model conversions must remain lossless when
   Isar codegen evolves. The thumbnail mapper tests provide a lightweight canary
   for that layer.
2. **Repository behaviour** – The notes, link, and vault-tree repositories now
   run against an actual Isar instance in tests, guaranteeing real transactions,
   reactive queries, and cascading deletes behave as expected.
3. **Test infrastructure** – Introducing a shared `TestIsarContext` detached our
   tests from the app singleton, so each spec runs in isolation, keeps schemas
   aligned, and makes future repos easy to exercise.

Without these guarantees the migration would be a black box; Task 9 turns it
into a repeatable contract that future refactors can trust.

## Reusable Patterns for Future Refactors

- **Inline temporary Isar**: `TestIsarContext` opens a throwaway on-disk Isar,
  wires in every collection schema, and deletes the directory afterward. When
  you add a new repository, instantiate it with `isar: context.isar` inside the
  test. This keeps tests deterministic and avoids touching the production
  singleton.
- **Eventual stream assertions**: For `watch*` APIs we rely on `StreamQueue` or
  `expectLater(emitsInOrder(...))` plus helper waiters (`_nextNoteMatching`) to
  advance until domain state matches. This handles the asynchronous nature of
  Isar’s watchers.
- **UTC-safe comparisons**: Persistent timestamps can shift timezone. Always
  compare with `toUtc()` or with tolerance to avoid false negatives after
  daylight-saving/timezone conversions. The thumbnail metadata test showcases
  that pattern.
- **Batch reshape validations**: After reorder/update batch operations, fetch
  the aggregate model and assert both ordering and derived timestamps. This is a
  reliable smoke test for transaction code paths.

Keep these patterns nearby when adding new features; they make your test harness
feel like production behaviour without heavy scaffolding.

## Debug Diary – From Failures to Passing Suites

This is the full timeline of issues and how they were resolved so you can reuse
the playbook the next time tests misbehave.

### 1. Initial Runner – Global Isar Singleton Collisions

**Symptom**: Early runs of the link/notes repository specs failed with
`DatabaseInitializationException` because the app-level `IsarDatabaseService`
was still being invoked inside tests.

**Hypothesis**: The singleton opens the database in a fixed location.
Launching multiple tests in the same process caused “collection id is invalid”
and “instance already open” errors.

**Fix**: Abstracted a `TestIsarContext` helper that opens Isar in a temporary
folder per test and injects it into repositories. Once tests stopped touching
`IsarDatabaseService`, the collisions disappeared.

### 2. Stream Tests Flaking – Event Order & Cancellation

**Symptom**: Even with isolated databases, some `StreamQueue` expectations saw
stale data or double-cancel crashes (`Bad state: Already cancelled`).

**Hypothesis**: Disposing test queues via `addTearDown(queue.cancel)` raced with
manual `queue.cancel()` calls, causing the queue to be closed twice. Additionally,
streams emit intermediate states that don’t match the final assertions.

**Fix**:

- Removed the redundant `addTearDown` for queues and cancelled explicitly only
  once at the end of each test.
- Added `_nextNoteMatching` to consume stream events until a predicate matches
  instead of assuming the very next event reflected the desired state.
- For high-level watchers, replaced manual loops with `expectLater(...,
emitsInOrder(...))` where possible.

### 3. Timezone Mismatch in Thumbnail Metadata

**Symptom**: Comparing `ThumbnailMetadata` objects failed because the stored
timestamps came back in the local timezone.

**Hypothesis**: Isar stores `DateTime` in UTC internally about but returns
converted values depending on the environment.

**Fix**: Compare using `toUtc()` on retrieved values and assert individual
fields rather than relying on full object equality.

### 4. Shared Isar Across Tests – Residual Data Bleeding

**Symptom**: Running the entire notes repository suite resulted in extra pages
or outdated note states.

**Hypothesis**: The shared Isar context kept previous test data because `setUp`
only opened a new instance without clearing tables.

**Fix**: Before each test, run a `writeTxn` that calls `isar.clear()` to reset
all collections. This keeps sequential tests independent and fast.

### 5. Widget Suite Failures – Pre-existing Timeouts

**Observation**: After all Isar repo tests passed, `fvm flutter test` still
failed in `page_thumbnail_grid_test.dart` due to known pumpAndSettle timeouts.

**Resolution**: Documented that these are pre-existing widget issues unrelated
to Task 9. They’ll need separate attention but do not block the database
migration tests.

## Next Steps When You Revisit

1. When new collections or repositories arrive, add them to
   `TestIsarContext`’s schema list and mirror the test approach here.
2. If you encounter similar `Bad state` or timeout failures, reuse the stream
   matching helpers and ensure you only cancel queues once.
3. Consider tackling the widget timeouts separately so the full suite can pass.

Keep this document close—it captures both the “why” and the “how” behind Task 9
so future refactors can plug into the same guardrails with minimal friction.
