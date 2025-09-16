# Isar Transaction Runner Notes (Task 4)

This doc explains the changes introduced while replacing the in-memory
transaction runner with the Isar-backed implementation. Use it as a
guide when you need to extend or refactor the transaction layer.

## Why we changed the runner

- The app now relies on Isar for persistence, so every write must be
  wrapped in `isar.writeTxn` to guarantee atomicity.
- Riverpod providers are synchronous; creating an `IsarDbTxnRunner`
  shouldn’t require `await`. We therefore added a lazy constructor so
  the instance can be created synchronously and open Isar only when the
  first write occurs.
- Failures should carry context. Instead of leaking raw exceptions, we
  wrap them in `DbTransactionException` with the original error and
  stack trace so call sites can differentiate transaction failures from
  business logic errors.

## File-by-file overview

### `lib/shared/services/db_txn_runner.dart`

- The abstract `DbTxnRunner` now documents its contract: execute a
  callback inside a transactional boundary.
- Added `DbTransactionException` to represent persistence layer
  failures. Future repository code can catch this to trigger retries or
  fallback flows.
- `NoopDbTxnRunner` remains for unit tests and memory-only scenarios.
  We document that it simply forwards the action.
- `dbTxnRunnerProvider` now returns `IsarDbTxnRunner.lazy(...)`, so
  consumers automatically get the Isar-backed runner without touching
  DI overrides.

### `lib/shared/services/isar_db_txn_runner.dart`

- Replaced the simple constructor with a private `_isarProvider`
  closure. This allows both eager (`create()`) and lazy
  (`IsarDbTxnRunner.lazy`) pathways.
- `_ensureInstance()` caches the `Isar` reference to avoid reopening the
  database for each transaction.
- `write()` awaits `_ensureInstance()` and wraps `isar.writeTxn` in a
  `try/catch`. Any failure becomes a `DbTransactionException` with
  message, underlying error, and stack trace.

### `lib/shared/services/isar_database_service.dart`

- Removed an unused local variable in `performMaintenance()` that the
  analyzer flagged after reformatting.

### Testing support

- `pubspec.yaml` gained `path_provider_platform_interface` under
  `dev_dependencies` so the existing mock path provider in the tests is
  declared explicitly.
- `test/shared/services/isar_db_txn_runner_test.dart` now imports the
  code through the public package paths and checks:
  - Basic success path.
  - Error propagation wraps exceptions in `DbTransactionException`.
  - The lazy runner initializes Isar on first use.
  - Async work inside `write()` runs to completion.

Run the targeted test suite with:

```bash
fvm flutter test test/shared/services/isar_db_txn_runner_test.dart
```

## Extending the transaction layer

- If a repository needs read transactions (e.g. `isar.txn()`), consider
  adding a `read` method to `DbTxnRunner`. Mirror the pattern used for
  `write`, including exception wrapping.
- When introducing retry logic, catch `DbTransactionException` at the
  service level; avoid swallowing the underlying error silently.
- Integration tests that depend on memory-only behaviour should override
  `dbTxnRunnerProvider` with `const NoopDbTxnRunner()` to avoid touching
  Isar.

With these changes, the transaction boundary is centralized, testable,
and ready for swap-in repositories that rely on Isar’s ACID semantics.
