// ignore_for_file: avoid_slow_async_io
import 'dart:convert';
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
import 'package:it_contest/shared/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_all_the_time/flutter_secure_storage',
  );
  Directory? tempRoot;
  late Isar isar; // Declare isar here

  setUp(() async {
    // Ensure fresh temp directory per test and mock path_provider
    tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
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
          return null; // No existing keys
        }
        if (call.method == 'write') {
          return null; // Success
        }
        if (call.method == 'readAll') {
          return <String, String>{}; // Empty storage
        }
        return null;
      },
    );

    // Make sure DB is closed before each test
    await IsarDb.instance.close();
    isar = await IsarDb.instance.open(); // Initialize isar here
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
  });

  group('BackupService Tests', () {
    test(
      'performBackup creates database backup file',
      () async {
        await IsarDb.instance.open();

        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Perform backup
        await BackupService.instance.performBackup(retentionDays: 7);

        // Check backup file exists
        final backupDir = Directory('${tempRoot!.path}/backups');
        expect(await backupDir.exists(), isTrue);

        final backupFiles = await backupDir
            .list()
            .where((e) => e is File && e.path.endsWith('.isar'))
            .cast<File>()
            .toList();
        expect(backupFiles.length, 1);

        final backupFile = backupFiles.first;
        expect(await backupFile.exists(), isTrue);
        expect(await backupFile.length(), greaterThan(0));
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'performIntegratedBackup creates comprehensive backup',
      () async {
        await IsarDb.instance.open();

        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        final folder = await NoteDbService.instance.createFolder(
          vaultId: vault.id,
          name: 'TestFolder',
        );
        final note = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          folderId: folder.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create fake PDF files
        final notesDir = Directory('${tempRoot!.path}/notes/${note.id}');
        await notesDir.create(recursive: true);
        final pdfFile = File('${notesDir.path}/test.pdf');
        await pdfFile.writeAsBytes([1, 2, 3, 4]); // Fake PDF content

        // Perform integrated backup
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: false,
        );

        // Check backup file exists
        expect(await File(backupPath).exists(), isTrue);
        expect(backupPath.endsWith('.zip'), isTrue);

        // Verify backup contains expected files by checking size
        final backupFile = File(backupPath);
        expect(await backupFile.length(), greaterThan(100)); // Should contain DB + metadata + PDF
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'performIntegratedBackup with encryption creates encrypted backup',
      () async {
        await IsarDb.instance.open();

        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Perform encrypted backup
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: true,
          customPassword: 'testpassword123',
        );

        // Check encrypted backup file exists
        expect(await File(backupPath).exists(), isTrue);
        expect(backupPath.endsWith('.zip.encrypted'), isTrue);

        // Verify file contains encrypted JSON structure
        final backupFile = File(backupPath);
        final content = await backupFile.readAsString();
        final encryptedData = jsonDecode(content);
        expect(encryptedData['iv'], isNotNull);
        expect(encryptedData['data'], isNotNull);
        expect(encryptedData['version'], '1.0');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'restoreIntegratedBackup successfully restores from backup',
      () async {
        // Create initial data
        final vault = await NoteDbService.instance.createVault(name: 'OriginalVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'OriginalNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create backup
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: false,
        );

        // Modify data (to verify restoration overwrites)
        await NoteDbService.instance.renameVault(vaultId: vault.id, newName: 'ModifiedVault');

        // Restore from backup
        final result = await BackupService.instance.restoreIntegratedBackup(
          backupPath: backupPath,
          overwriteExisting: true,
        );

        expect(result.success, isTrue);
        expect(result.databaseRestored, isTrue);
        expect(result.message, contains('성공적으로 복원'));

        // Verify data was restored
        final restoredVaults = await isar.collection<Vault>().where().anyId().findAll();
        expect(restoredVaults.length, 1);
        expect(restoredVaults.first.name, 'OriginalVault'); // Should be restored to original

        final restoredNotes = await isar.collection<Note>().where().anyId().findAll();
        expect(restoredNotes.length, 1);
        expect(restoredNotes.first.name, 'OriginalNote');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'restoreIntegratedBackup handles encrypted backup with password',
      () async {
        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create encrypted backup
        const password = 'testpassword123';
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: true,
          customPassword: password,
        );

        // Clear data
        await isar.writeTxn(() async {
          await isar.clear();
        });

        // Restore with correct password
        final result = await BackupService.instance.restoreIntegratedBackup(
          backupPath: backupPath,
          password: password,
          overwriteExisting: true,
        );

        expect(result.success, isTrue);
        expect(result.databaseRestored, isTrue);

        // Verify data was restored
        final restoredVaults = await isar.collection<Vault>().where().anyId().findAll();
        expect(restoredVaults.length, 1);
        expect(restoredVaults.first.name, 'TestVault');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'restoreIntegratedBackup fails with wrong password',
      () async {
        // Create test data and encrypted backup
        await NoteDbService.instance.createVault(name: 'TestVault');
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: true,
          customPassword: 'correctpassword',
        );

        // Try to restore with wrong password
        final result = await BackupService.instance.restoreIntegratedBackup(
          backupPath: backupPath,
          password: 'wrongpassword',
          overwriteExisting: true,
        );

        expect(result.success, isFalse);
        expect(result.message, contains('실패'));
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'getAvailableBackups lists backup files correctly',
      () async {
        await IsarDb.instance.open();

        // Create test data
        await NoteDbService.instance.createVault(name: 'TestVault');

        // Create different types of backups
        await BackupService.instance.performBackup(retentionDays: 7);
        await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: false,
        );
        await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: true,
          customPassword: 'test123',
        );

        // Get available backups
        final backups = await BackupService.instance.getAvailableBackups();

        expect(backups.length, 3);

        // Check backup types
        final dbBackups = backups.where((b) => b.type == BackupType.database).toList();
        final integratedBackups = backups.where((b) => b.type == BackupType.integrated).toList();
        final encryptedBackups = backups.where((b) => b.isEncrypted).toList();

        expect(dbBackups.length, 1);
        expect(integratedBackups.length, 2);
        expect(encryptedBackups.length, 1);

        // Verify all backups have valid metadata
        for (final backup in backups) {
          expect(backup.fileName, isNotEmpty);
          expect(backup.sizeBytes, greaterThan(0));
          expect(backup.createdAt, isNotNull);
          expect(backup.formattedSize, isNotEmpty);
        }
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'getBackupStatus returns current backup state',
      () async {
        await IsarDb.instance.open();

        // Create some backups
        await BackupService.instance.performBackup(retentionDays: 7);
        await BackupService.instance.performIntegratedBackup(retentionDays: 7);

        // Get backup status
        final status = await BackupService.instance.getBackupStatus();

        expect(status.isRunning, isFalse);
        expect(status.availableBackupsCount, 2);
        expect(status.totalBackupSize, greaterThan(0));
        expect(status.formattedTotalSize, isNotEmpty);
        expect(status.lastBackupAt, isNull); // No scheduled backup in test

        // Check next backup calculation (should be null without settings)
        expect(status.nextBackupDue, isNull);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'testBackupRestore validates backup/restore functionality',
      () async {
        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Run backup test
        final testResult = await BackupService.instance.testBackupRestore();

        expect(testResult.success, isTrue);
        expect(testResult.backupCreated, isTrue);
        expect(testResult.backupFileExists, isTrue);
        expect(testResult.metadataValid, isTrue);
        expect(testResult.databaseExtractable, isTrue);
        expect(testResult.message, contains('성공적으로 완료'));
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'deleteBackup removes backup file',
      () async {
        // Create backup
        await BackupService.instance.performBackup(retentionDays: 7);

        // Get backup list
        final backups = await BackupService.instance.getAvailableBackups();
        expect(backups.length, 1);

        final backupPath = backups.first.filePath;
        expect(await File(backupPath).exists(), isTrue);

        // Delete backup
        final deleted = await BackupService.instance.deleteBackup(backupPath);
        expect(deleted, isTrue);
        expect(await File(backupPath).exists(), isFalse);

        // Verify backup list is empty
        final updatedBackups = await BackupService.instance.getAvailableBackups();
        expect(updatedBackups.length, 0);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });
}
