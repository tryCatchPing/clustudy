// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
// Ensure native libs are bundled for Flutter tests
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_all_the_time/flutter_secure_storage',
  );
  final Map<String, String> mockStorage = {};
  Directory? tempRoot;

  setUp(() async {
    // Ensure fresh temp directory per test and mock path_provider
    tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
    mockStorage.clear();
    IsarDb.setTestDirectoryOverride(tempRoot!.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempRoot!.path;
        }
        return null;
      },
    );

    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall call) async {
        if (call.method == 'read') {
          final key = call.arguments['key'] as String;
          return mockStorage[key];
        }
        if (call.method == 'write') {
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String;
          mockStorage[key] = value;
          return null;
        }
        if (call.method == 'delete') {
          final key = call.arguments['key'] as String;
          mockStorage.remove(key);
          return null;
        }
        if (call.method == 'readAll') {
          return Map<String, String>.from(mockStorage);
        }
        return null;
      },
    );

    // Make sure DB is closed before each test
    await IsarDb.instance.close();
  });

  tearDown(() async {
    // Close DB and clean temp dir
    await IsarDb.instance.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      null,
    );
    if (tempRoot != null && await tempRoot!.exists()) {
      await tempRoot!.delete(recursive: true);
    }
    IsarDb.setTestDirectoryOverride(null);
  });

  group('CryptoKeyService Tests', () {
    test('getOrCreateKey creates new key when none exists', () async {
      // Verify no key exists initially
      final initialKey = await CryptoKeyService.instance.loadKey();
      expect(initialKey, isNull);

      // Create new key
      final key = await CryptoKeyService.instance.getOrCreateKey();

      expect(key, isNotNull);
      expect(key.length, 32); // 256-bit key
      expect(mockStorage.containsKey('isar_encryption_key_v1'), isTrue);

      // Verify same key is returned on subsequent calls
      final sameKey = await CryptoKeyService.instance.getOrCreateKey();
      expect(sameKey, equals(key));
    });

    test('loadKey returns existing key when available', () async {
      // Create a key first
      final originalKey = await CryptoKeyService.instance.getOrCreateKey();

      // Load the key
      final loadedKey = await CryptoKeyService.instance.loadKey();

      expect(loadedKey, isNotNull);
      expect(loadedKey, equals(originalKey));
    });

    test('rotateKey creates new key and backs up old one', () async {
      // Create initial key
      final oldKey = await CryptoKeyService.instance.getOrCreateKey();

      // Rotate key
      final newKey = await CryptoKeyService.instance.rotateKey();

      expect(newKey, isNotNull);
      expect(newKey.length, 32);
      expect(newKey, isNot(equals(oldKey)));

      // Verify new key is now the active key
      final currentKey = await CryptoKeyService.instance.loadKey();
      expect(currentKey, equals(newKey));

      // Verify old key was backed up
      final backupAliases = await CryptoKeyService.instance.getBackupKeyAliases();
      expect(backupAliases.length, 1);

      final backedUpKey = await CryptoKeyService.instance.loadBackupKey(backupAliases.first);
      expect(backedUpKey, equals(oldKey));
    });

    test('validateKey correctly validates key format and usability', () async {
      // Test valid key
      final validKey = await CryptoKeyService.instance.getOrCreateKey();
      final isValid = await CryptoKeyService.instance.validateKey(validKey);
      expect(isValid, isTrue);

      // Test invalid key lengths
      final shortKey = List<int>.filled(16, 1);
      final longKey = List<int>.filled(64, 1);

      expect(await CryptoKeyService.instance.validateKey(shortKey), isFalse);
      expect(await CryptoKeyService.instance.validateKey(longKey), isFalse);
    });

    test('backupKey stores key with custom alias', () async {
      final key = await CryptoKeyService.instance.getOrCreateKey();
      const customAlias = 'my_backup_key';

      // Backup key with custom alias
      await CryptoKeyService.instance.backupKey(key, customAlias);

      // Verify backup exists
      final aliases = await CryptoKeyService.instance.getBackupKeyAliases();
      expect(aliases, contains(customAlias));

      // Verify key can be loaded
      final loadedKey = await CryptoKeyService.instance.loadBackupKey(customAlias);
      expect(loadedKey, equals(key));
    });

    test('deleteOldKey removes specific backup key', () async {
      final key = await CryptoKeyService.instance.getOrCreateKey();
      const alias = 'test_backup';

      // Create backup
      await CryptoKeyService.instance.backupKey(key, alias);
      expect(await CryptoKeyService.instance.getBackupKeyAliases(), contains(alias));

      // Delete backup
      await CryptoKeyService.instance.deleteOldKey('isar_backup_key_$alias');

      // Verify backup is gone
      expect(await CryptoKeyService.instance.getBackupKeyAliases(), isNot(contains(alias)));

      final deletedKey = await CryptoKeyService.instance.loadBackupKey(alias);
      expect(deletedKey, isNull);
    });

    test('cleanupOldBackups keeps only specified number of recent backups', () async {
      final key = await CryptoKeyService.instance.getOrCreateKey();

      // Create multiple backups with timestamp-like aliases
      final timestamps = ['1000000000000', '2000000000000', '3000000000000', '4000000000000'];
      for (final timestamp in timestamps) {
        await CryptoKeyService.instance.backupKey(key, timestamp);
      }

      // Verify all backups exist
      final allAliases = await CryptoKeyService.instance.getBackupKeyAliases();
      expect(allAliases.length, 4);

      // Cleanup keeping only 2 most recent
      await CryptoKeyService.instance.cleanupOldBackups(retainCount: 2);

      // Verify only 2 most recent remain
      final remainingAliases = await CryptoKeyService.instance.getBackupKeyAliases();
      expect(remainingAliases.length, 2);
      expect(remainingAliases, containsAll(['3000000000000', '4000000000000']));
    });

    test(
      'reencryptDatabase preserves data with new encryption key',
      () async {
        final isar = await IsarDb.instance.open();

        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Get current key and create new key for reencryption
        final oldKey = await CryptoKeyService.instance.loadKey();
        final newKey = await CryptoKeyService.instance.rotateKey();

        // Reencrypt database
        await CryptoKeyService.instance.reencryptDatabase(oldKey!, newKey);

        // Verify data is still accessible
        final vaults = await isar.collection<Vault>().where().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'TestVault');

        final notes = await isar.collection<Note>().where().findAll();
        expect(notes.length, 1);
        expect(notes.first.name, 'TestNote');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });

  group('IsarDb Encryption Integration Tests', () {
    Isar? isar;

    setUp(() async {
      isar = await IsarDb.instance.open();
    });

    tearDown(() async {
      await IsarDb.instance.close();
      isar = null;
    });

    test(
      'toggleEncryption enables encryption for new database',
      () async {
        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Enable encryption
        await IsarDb.instance.toggleEncryption(enable: true);

        // Verify data is still accessible
        final vaults = await isar!.collection<Vault>().where().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'TestVault');

        // Verify encryption setting
        final settings = await isar!.collection<SettingsEntity>().where().findFirst();
        expect(settings?.encryptionEnabled, isTrue);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'toggleEncryption disables encryption',
      () async {
        // Create test data and enable encryption first
        await NoteDbService.instance.createVault(name: 'TestVault');
        await IsarDb.instance.toggleEncryption(enable: true);

        // Disable encryption
        await IsarDb.instance.toggleEncryption(enable: false);

        // Verify data is still accessible
        final vaults = await isar!.collection<Vault>().where().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'TestVault');

        // Verify encryption setting
        final settings = await isar!.collection<SettingsEntity>().where().findFirst();
        expect(settings?.encryptionEnabled, isFalse);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'open with enableEncryption=true uses encryption key',
      () async {
        // Create encryption key first
        await CryptoKeyService.instance.getOrCreateKey();

        // Open with encryption enabled
        // Removed: final isar = await IsarDb.instance.open(enableEncryption: true);

        // Create settings to enable encryption
        await isar!.writeTxn(() async {
          final settings = SettingsEntity()
            ..encryptionEnabled = true
            ..backupDailyAt = '02:00'
            ..backupRetentionDays = 7
            ..recycleRetentionDays = 30;
          await isar!.collection<SettingsEntity>().put(settings);
        });

        // Create test data
        await NoteDbService.instance.createVault(name: 'EncryptedVault');

        // Close and reopen - should work with same key
        await IsarDb.instance.close();
        final reopenedIsar = await IsarDb.instance.open(enableEncryption: true);

        // Verify data is accessible
        final vaults = await reopenedIsar.collection<Vault>().where().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'EncryptedVault');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'open with explicit encryptionKey parameter uses provided key',
      () async {
        // Create custom key
        final customKey = List<int>.generate(32, (i) => i % 256);

        // Open with explicit key
        // Removed: final isar = await IsarDb.instance.open(encryptionKey: customKey);

        // Create test data
        await NoteDbService.instance.createVault(name: 'CustomKeyVault');

        // Close and reopen with same key
        await IsarDb.instance.close();
        final reopenedIsar = await IsarDb.instance.open(encryptionKey: customKey);

        // Verify data is accessible
        final vaults = await reopenedIsar.collection<Vault>().where().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'CustomKeyVault');

        // Try opening with wrong key should fail
        await IsarDb.instance.close();
        final wrongKey = List<int>.generate(32, (i) => (i + 1) % 256);

        await expectLater(
          () => IsarDb.instance.open(encryptionKey: wrongKey),
          throwsA(isA<IsarError>()),
        );
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });
}

