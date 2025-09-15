import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract transaction runner to unify memory/Isar write boundaries.
///
/// - Memory: simply executes the action.
/// - Isar: implementation will wrap with `isar.writeTxn`.
abstract class DbTxnRunner {
  Future<T> write<T>(Future<T> Function() action);
}

class NoopDbTxnRunner implements DbTxnRunner {
  const NoopDbTxnRunner();

  @override
  Future<T> write<T>(Future<T> Function() action) async {
    return await action();
  }
}

/// DI provider. Memory uses no-op; Isar can override at runtime.
///
/// Note: This will be updated to use IsarDbTxnRunner in task 4 when
/// repository implementations are replaced with Isar versions.
final dbTxnRunnerProvider = Provider<DbTxnRunner>((ref) {
  return const NoopDbTxnRunner();
});
