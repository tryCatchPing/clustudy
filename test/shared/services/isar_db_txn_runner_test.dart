import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:it_contest/shared/services/db_txn_runner.dart';
import 'package:it_contest/shared/services/isar_database_service.dart';
import 'package:it_contest/shared/services/isar_db_txn_runner.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTemp('test_db').then((dir) => dir.path);
  }
}

void main() {
  group('IsarDbTxnRunner', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Set up mock path provider for testing
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    tearDown(() async {
      // Clean up database instance after each test
      await IsarDatabaseService.close();
    });

    test('should create instance with Isar database', () async {
      final txnRunner = await IsarDbTxnRunner.create();

      expect(txnRunner, isNotNull);
    });

    test('should execute write operations in transaction', () async {
      final txnRunner = await IsarDbTxnRunner.create();

      // Test that write operation executes successfully
      final result = await txnRunner.write(() async {
        return 'test_result';
      });

      expect(result, equals('test_result'));
    });

    test('should handle exceptions in write operations', () async {
      final txnRunner = await IsarDbTxnRunner.create();

      // Test that exceptions are properly propagated
      expect(
        () => txnRunner.write(() async {
          throw Exception('Test exception');
        }),
        throwsA(isA<DbTransactionException>()),
      );
    });

    test('should support async operations in write transaction', () async {
      final txnRunner = await IsarDbTxnRunner.create();

      final result = await txnRunner.write(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      expect(result, equals(42));
    });

    test('lazy runner should initialize Isar on first use', () async {
      final runner = IsarDbTxnRunner.lazy(IsarDatabaseService.getInstance);

      final result = await runner.write(() async => 7);

      expect(result, equals(7));
    });
  });
}
