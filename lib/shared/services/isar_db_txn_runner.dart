import 'package:isar/isar.dart';

import 'db_txn_runner.dart';
import 'isar_database_service.dart';

/// Isar implementation of [DbTxnRunner] that wraps operations in Isar
/// transactions.
///
/// Instances can be created eagerly via [create] or lazily via
/// [IsarDbTxnRunner.lazy]. The lazy variant defers database opening until the
/// first transaction runs, which keeps DI synchronous-friendly.
class IsarDbTxnRunner implements DbTxnRunner {
  IsarDbTxnRunner._(this._isarProvider);

  final Future<Isar> Function() _isarProvider;
  Isar? _isar;

  /// Creates an [IsarDbTxnRunner] using the shared singleton database
  /// instance.
  static Future<IsarDbTxnRunner> create() async {
    final isar = await IsarDatabaseService.getInstance();
    return IsarDbTxnRunner._(() async => isar).._isar = isar;
  }

  /// Lazily instantiates the underlying [Isar] instance on first use.
  factory IsarDbTxnRunner.lazy(Future<Isar> Function() isarProvider) {
    return IsarDbTxnRunner._(isarProvider);
  }

  Future<Isar> _ensureInstance() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) {
      return cached;
    }

    final isar = await _isarProvider();
    _isar = isar;
    return isar;
  }

  @override
  Future<T> write<T>(Future<T> Function() action) async {
    final isar = await _ensureInstance();
    try {
      return await isar.writeTxn(action);
    } catch (error, stackTrace) {
      throw DbTransactionException(
        'Failed to execute Isar write transaction',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
