import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'isar_database_service.dart';
import 'isar_db_txn_runner.dart';

/// Abstract transaction runner to unify memory/Isar write boundaries.
///
/// - Memory: simply executes the action.
/// - Isar: implementation will wrap with `isar.writeTxn`.
abstract class DbTxnRunner {
  /// Executes [action] within a transactional boundary.
  Future<T> write<T>(Future<T> Function() action);
}

/// In-memory transaction runner that simply executes the supplied action.
class NoopDbTxnRunner implements DbTxnRunner {
  /// Creates a no-op transaction runner.
  const NoopDbTxnRunner();

  /// Executes [action] without any database involvement.
  @override
  Future<T> write<T>(Future<T> Function() action) async {
    return await action();
  }
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
