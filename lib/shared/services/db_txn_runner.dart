import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'isar_database_service.dart';
import 'isar_db_txn_runner.dart';

/// Abstract transaction runner to unify memory/Isar write boundaries.
///
/// - Memory: simply executes the action.
/// - Isar: implementation will wrap with `isar.writeTxn`.
/// Shared write-session context propagated across repository calls while a
/// transaction is active.
abstract class DbWriteSession {
  /// Base const constructor for subclasses.
  const DbWriteSession();
}

/// Transaction runner abstraction that optionally exposes the underlying
/// session object to the caller.
abstract class DbTxnRunner {
  /// Executes [action] within a transactional boundary.
  Future<T> write<T>(Future<T> Function() action) {
    return writeWithSession((_) => action());
  }

  /// Executes [action] within a transactional boundary and supplies the
  /// contextual [DbWriteSession] so downstream repositories can participate in
  /// the same transaction without starting their own.
  Future<T> writeWithSession<T>(
    Future<T> Function(DbWriteSession session) action,
  );
}

/// In-memory transaction runner that simply executes the supplied action.
class NoopDbTxnRunner implements DbTxnRunner {
  /// Creates a no-op transaction runner.
  const NoopDbTxnRunner();

  @override
  Future<T> write<T>(Future<T> Function() action) async {
    return await action();
  }

  @override
  Future<T> writeWithSession<T>(
    Future<T> Function(DbWriteSession session) action,
  ) async {
    return await action(const _NoopDbWriteSession());
  }
}

/// Write session used when no underlying database is present.
class _NoopDbWriteSession extends DbWriteSession {
  const _NoopDbWriteSession();
}

/// Exception thrown when a database transaction fails.
class DbTransactionException implements Exception {
  /// Human readable summary.
  final String message;

  /// Underlying error thrown by the persistence layer.
  final Object error;

  /// Stack trace from the original failure.
  final StackTrace stackTrace;

  /// Creates a new transaction exception.
  const DbTransactionException(
    this.message, {
    required this.error,
    required this.stackTrace,
  });

  @override
  String toString() => 'DbTransactionException: $message';
}

/// DI provider for the transaction runner.
///
/// Defaults to [IsarDbTxnRunner] wired to the shared database. Tests can
/// override with [NoopDbTxnRunner] when Isar access is not required.
final dbTxnRunnerProvider = Provider<DbTxnRunner>((ref) {
  return IsarDbTxnRunner.lazy(IsarDatabaseService.getInstance);
});
