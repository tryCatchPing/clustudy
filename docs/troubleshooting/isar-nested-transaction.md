# Isar Transaction Failure Postmortem

## Summary

Folder moves, note creation, note renames, and other vault operations were
failing at runtime with `DbTransactionException: Failed to execute Isar write
transaction`. The UI reported vaults/folders being created, yet subsequent
changes crashed when the app attempted to persist follow-up updates.

## Root Cause

`VaultNotesService` coordinates multi-repository write flows (vault tree,
notes, links) and wraps them in `dbTxn.write`. On Isar-backed deployments that
method maps to `IsarDbTxnRunner.write`, which starts an `isar.writeTxn`. The
repositories called inside (`IsarVaultTreeRepository`, `IsarNotesRepository`,
`IsarLinkRepository`) also called `isar.writeTxn` internally, assuming they
were invoked from a non-transactional context. This led to nested write
transactions:

```
VaultNotesService.dbTxn.write() --> isar.writeTxn(() async {
  await vaultRepo.registerExistingNote(); // internally: isar.writeTxn(...)
  await notesRepo.upsert();              // internally: isar.writeTxn(...)
});
```

Isar forbids re-entering `writeTxn` while an existing write transaction is
active, so the first nested call threw, wrapped by `DbTransactionException`,
and the UI surfaced the failure.

## Fix Strategy

1. **Expose shared transaction context** – `DbTxnRunner` now supplies a
   `DbWriteSession` to callbacks via `writeWithSession`. `IsarDbTxnRunner`
   instantiates an `IsarDbWriteSession` that exposes the active `Isar`
   instance.
2. **Session-aware repositories** – All repository interfaces accept an
   optional `DbWriteSession`. The Isar implementations reuse the provided
   session instead of starting a fresh `writeTxn`, eliminating nested
   transactions. Memory implementations ignore the session for API parity.
3. **Service updates** – `VaultNotesService` switched to
   `dbTxn.writeWithSession`, forwarding the shared session to the vault, note,
   and link repositories so an entire workflow executes inside a single Isar
   transaction.

## Outcomes

- Vault folder moves, note creation, renames, and cascading deletes execute in
  one Isar transaction without triggering nested writes.
- Multi-repository workflows remain atomic; either all mutations commit or the
  transaction rolls back as a unit.
- The transaction abstraction still works for in-memory repositories, so
  tests and non-Isar environments remain unaffected.

## Follow-up

- Add integration coverage that invokes `VaultNotesService` flows under an
  active Isar transaction to guard against future regressions.
- Consider extending the session pattern to other persistence layers if new
  storage engines are introduced.
