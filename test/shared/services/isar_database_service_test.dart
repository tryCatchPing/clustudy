import 'dart:io';

import 'package:clustudy/shared/services/isar_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTemp('test_db').then((dir) => dir.path);
  }
}

void main() {
  group('IsarDatabaseService', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Set up mock path provider for testing
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    tearDown(() async {
      // Clean up database instance after each test
      await IsarDatabaseService.close();
    });

    test('should initialize database instance', () async {
      final isar = await IsarDatabaseService.getInstance();

      expect(isar, isNotNull);
      expect(isar.isOpen, isTrue);
    });

    test('should return same instance on multiple calls', () async {
      final isar1 = await IsarDatabaseService.getInstance();
      final isar2 = await IsarDatabaseService.getInstance();

      expect(identical(isar1, isar2), isTrue);
    });

    test('should provide database info', () async {
      await IsarDatabaseService.getInstance();
      final info = await IsarDatabaseService.getDatabaseInfo();

      expect(info.name, equals('clustudy_db'));
      expect(info.path, contains('clustudy_db'));
      expect(info.size, isA<int>());
      expect(info.schemaVersion, equals(1));
      expect(
        info.collections,
        containsAll(
          [
            'VaultEntity',
            'FolderEntity',
            'NoteEntity',
            'NotePageEntity',
            'LinkEntity',
            'NotePlacementEntity',
            'DatabaseMetadataEntity',
          ],
        ),
      );
    });

    test('should handle database closure', () async {
      final isar = await IsarDatabaseService.getInstance();
      expect(isar.isOpen, isTrue);

      await IsarDatabaseService.close();
      expect(isar.isOpen, isFalse);
    });

    test('should clear database', () async {
      await IsarDatabaseService.getInstance();

      // Should not throw exception
      await IsarDatabaseService.clearDatabase();
    });

    test('should perform maintenance', () async {
      await IsarDatabaseService.getInstance();

      // Should not throw exception
      await IsarDatabaseService.performMaintenance();
    });

    test('should handle database initialization exception', () async {
      // This test verifies the exception type exists and can be thrown
      const exception = DatabaseInitializationException('Test error');

      expect(exception.message, equals('Test error'));
      expect(
        exception.toString(),
        equals('DatabaseInitializationException: Test error'),
      );
    });
  });
}
