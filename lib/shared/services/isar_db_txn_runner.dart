import 'package:isar/isar.dart';

import 'db_txn_runner.dart';
import 'isar_database_service.dart';

/// Isar implementation of DbTxnRunner that wraps operations in Isar transactions.
///
/// Provides proper transaction boundaries for write operations to ensure
/// data consistency and atomicity when using Isar database.
class IsarDbTxnRunner implements DbTxnRunner {
  final Isar _isar;

  /// Creates an IsarDbTxnRunner with the provided Isar instance.
  const IsarDbTxnRunner(this._isar);

  /// Creates an IsarDbTxnRunner using the singleton database instance.
  static Future<IsarDbTxnRunner> create() async {
    final isar = await IsarDatabaseService.getInstance();
    return IsarDbTxnRunner(isar);
  }

  @override
  Future<T> write<T>(Future<T> Function() action) async {
    return await _isar.writeTxn(() async {
      return await action();
    });
  }
}
