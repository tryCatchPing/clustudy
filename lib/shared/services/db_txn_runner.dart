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
final dbTxnRunnerProvider = Provider<DbTxnRunner>((ref) {
  return const NoopDbTxnRunner();
});
