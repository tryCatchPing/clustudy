import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
// Ensure native libs are bundled for Flutter tests
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/shared/services/backup_service.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';
import 'package:it_contest/services/link/link_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_all_the_time/flutter_secure_storage');
  Directory? tempRoot;
  Map<String, String> mockStorage = {};

  setUp(() async {
    // Ensure fresh temp directory per test and mock path_provider
    tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
    mockStorage.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempRoot!.path;
      }
      return null;
    });

    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
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
    });

    // Make sure DB is closed before each test
    await IsarDb.instance.close();
  });

  tearDown(() async {
    // Close DB and clean temp dir
    await IsarDb.instance.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    if (tempRoot != null && await tempRoot!.exists()) {
      await tempRoot!.delete(recursive: true);
    }
  });

  group('Full Backup and Restore Integration Tests', () {
    test('complete backup and restore workflow preserves all data and relationships', () async {
      final isar = await IsarDb.instance.open();

      // Create comprehensive test data structure
      
      // 1. Create vaults
      final vault1 = await NoteDbService.instance.createVault(name: 'PersonalVault');
      final vault2 = await NoteDbService.instance.createVault(name: 'WorkVault');

      // 2. Create folders
      final personalFolder = await NoteDbService.instance.createFolder(
        vaultId: vault1.id,
        name: 'Personal Projects',
        sortIndex: 1000,
      );
      final workFolder = await NoteDbService.instance.createFolder(
        vaultId: vault2.id,
        name: 'Work Documents',
        sortIndex: 1000,
      );

      // 3. Create notes with various configurations
      final personalNote1 = await NoteDbService.instance.createNote(
        vaultId: vault1.id,
        folderId: personalFolder.id,
        name: 'Personal Note 1',
        pageSize: 'A4',
        pageOrientation: 'portrait',
        sortIndex: 1000,
      );
      
      final personalNote2 = await NoteDbService.instance.createNote(
        vaultId: vault1.id,
        folderId: personalFolder.id,
        name: 'Personal Note 2',
        pageSize: 'Letter',
        pageOrientation: 'landscape',
        sortIndex: 2000,
      );

      final rootNote = await NoteDbService.instance.createNote(
        vaultId: vault1.id,
        folderId: null, // Root note
        name: 'Root Note',
        pageSize: 'A4',
        pageOrientation: 'portrait',
        sortIndex: 1000,
      );

      final workNote = await NoteDbService.instance.createNote(
        vaultId: vault2.id,
        folderId: workFolder.id,
        name: 'Work Note',
        pageSize: 'A4',
        pageOrientation: 'portrait',
        sortIndex: 1000,
      );

      // 4. Create pages
      final page1 = await NoteDbService.instance.createPage(
        noteId: personalNote1.id,
        index: 0,
        widthPx: 2480,
        heightPx: 3508,
      );
      
      final page2 = await NoteDbService.instance.createPage(
        noteId: personalNote1.id,
        index: 1,
        widthPx: 2480,
        heightPx: 3508,
      );

      final workPage = await NoteDbService.instance.createPage(
        noteId: workNote.id,
        index: 0,
      );

      // 5. Create canvas data
      await isar.writeTxn(() async {
        final canvasData1 = CanvasData()
          ..noteId = personalNote1.id
          ..pageId = page1.id
          ..schemaVersion = '1.0'
          ..json = '{"elements": [{"type": "stroke", "points": [[100, 100], [200, 200]]}]}'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        
        final canvasData2 = CanvasData()
          ..noteId = personalNote1.id
          ..pageId = page2.id
          ..schemaVersion = '1.0'
          ..json = '{"elements": [{"type": "stroke", "points": [[50, 50], [150, 150]]}]}'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        await isar.canvasDatas.putAll([canvasData1, canvasData2]);
      });

      // 6. Create page snapshots
      await isar.writeTxn(() async {
        final snapshot1 = PageSnapshot()
          ..pageId = page1.id
          ..schemaVersion = '1.0'
          ..json = '{"snapshot": "data1"}'
          ..createdAt = DateTime.now();
        
        final snapshot2 = PageSnapshot()
          ..pageId = page2.id
          ..schemaVersion = '1.0'
          ..json = '{"snapshot": "data2"}'
          ..createdAt = DateTime.now();

        await isar.pageSnapshots.putAll([snapshot1, snapshot2]);
      });

      // 7. Create links and graph edges using LinkService
      final region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault1.id,
        sourceNoteId: personalNote1.id,
        sourcePageId: page1.id,
        region: region,
        label: 'Linked Note',
      );

      // 8. Create PDF cache metadata
      await isar.writeTxn(() async {
        final cache1 = PdfCacheMeta()
          ..noteId = personalNote1.id
          ..pageIndex = 0
          ..cachePath = '/cache/path1.png'
          ..dpi = 144
          ..renderedAt = DateTime.now()
          ..sizeBytes = 1024
          ..lastAccessAt = DateTime.now();
        cache1.setUniqueKey();

        final cache2 = PdfCacheMeta()
          ..noteId = workNote.id
          ..pageIndex = 0
          ..cachePath = '/cache/path2.png'
          ..dpi = 144
          ..renderedAt = DateTime.now()
          ..sizeBytes = 2048
          ..lastAccessAt = DateTime.now();
        cache2.setUniqueKey();

        await isar.pdfCacheMetas.putAll([cache1, cache2]);
      });

      // 9. Create RecentTabs
      await isar.writeTxn(() async {
        final recentTabs = RecentTabs()
          ..userId = 'local'
          ..noteIdsJson = '[${personalNote1.id}, ${workNote.id}, ${linkedNote.id}]'
          ..updatedAt = DateTime.now();
        
        await isar.recentTabss.put(recentTabs);
      });

      // 10. Create settings
      await isar.writeTxn(() async {
        final settings = SettingsEntity()
          ..encryptionEnabled = false
          ..backupDailyAt = '03:00'
          ..backupRetentionDays = 14
          ..recycleRetentionDays = 30
          ..dataVersion = 1
          ..pdfCacheMaxMB = 256;
        
        await isar.settingsEntitys.put(settings);
      });

      // 11. Create fake PDF files for integrated backup
      final notesDir = Directory('${tempRoot!.path}/notes');
      await notesDir.create(recursive: true);
      
      final pdfFile1 = File('${notesDir.path}/${personalNote1.id}/document.pdf');
      await pdfFile1.parent.create(recursive: true);
      await pdfFile1.writeAsBytes(List.generate(1000, (i) => i % 256)); // Fake PDF content

      final pdfFile2 = File('${notesDir.path}/${workNote.id}/presentation.pdf');
      await pdfFile2.parent.create(recursive: true);
      await pdfFile2.writeAsBytes(List.generate(2000, (i) => (i * 2) % 256)); // Different fake content

      // Store counts for verification
      final originalCounts = {
        'vaults': await isar.vaults.count(),
        'folders': await isar.folders.count(),
        'notes': await isar.notes.count(),
        'pages': await isar.pages.count(),
        'canvasData': await isar.canvasDatas.count(),
        'pageSnapshots': await isar.pageSnapshots.count(),
        'links': await isar.linkEntitys.count(),
        'graphEdges': await isar.graphEdges.count(),
        'pdfCacheMetas': await isar.pdfCacheMetas.count(),
        'recentTabs': await isar.recentTabss.count(),
        'settings': await isar.settingsEntitys.count(),
      };

      // 12. Perform integrated backup
      final backupPath = await BackupService.instance.performIntegratedBackup(
        retentionDays: 7,
        includeEncryption: false,
      );

      expect(await File(backupPath).exists(), isTrue);

      // 13. Clear all data to simulate data loss
      await isar.writeTxn(() async {
        await isar.clear();
      });

      // Delete PDF files
      if (await notesDir.exists()) {
        await notesDir.delete(recursive: true);
      }

      // Verify data is gone
      expect(await isar.vaults.count(), 0);
      expect(await isar.notes.count(), 0);

      // 14. Restore from backup
      final restoreResult = await BackupService.instance.restoreIntegratedBackup(
        backupPath: backupPath,
        overwriteExisting: true,
      );

      expect(restoreResult.success, isTrue);
      expect(restoreResult.databaseRestored, isTrue);
      expect(restoreResult.pdfFilesRestored, greaterThan(0));

      // 15. Verify all data was restored correctly
      
      // Verify counts match
      final restoredCounts = {
        'vaults': await isar.vaults.count(),
        'folders': await isar.folders.count(),
        'notes': await isar.notes.count(),
        'pages': await isar.pages.count(),
        'canvasData': await isar.canvasDatas.count(),
        'pageSnapshots': await isar.pageSnapshots.count(),
        'links': await isar.linkEntitys.count(),
        'graphEdges': await isar.graphEdges.count(),
        'pdfCacheMetas': await isar.pdfCacheMetas.count(),
        'recentTabs': await isar.recentTabss.count(),
        'settings': await isar.settingsEntitys.count(),
      };

      expect(restoredCounts, equals(originalCounts));

      // Verify specific data integrity
      final restoredVaults = await isar.vaults.where().sortByName().findAll();
      expect(restoredVaults.length, 2);
      expect(restoredVaults[0].name, 'PersonalVault');
      expect(restoredVaults[1].name, 'WorkVault');

      final restoredPersonalNotes = await isar.notes
          .filter()
          .vaultIdEqualTo(restoredVaults[0].id)
          .sortByName()
          .findAll();
      expect(restoredPersonalNotes.length, 3); // 2 folder notes + 1 root note + 1 linked note
      expect(restoredPersonalNotes.map((n) => n.name).toList(), 
        containsAll(['Personal Note 1', 'Personal Note 2', 'Root Note', 'Linked Note']));

      // Verify relationships are preserved
      final restoredLinks = await isar.linkEntitys.where().findAll();
      expect(restoredLinks.length, 1);
      expect(restoredLinks.first.label, 'Linked Note');
      expect(restoredLinks.first.dangling, isFalse);

      final restoredEdges = await isar.graphEdges.where().findAll();
      expect(restoredEdges.length, 1);
      expect(restoredEdges.first.fromNoteId, restoredLinks.first.sourceNoteId);
      expect(restoredEdges.first.toNoteId, restoredLinks.first.targetNoteId);

      // Verify canvas data
      final restoredCanvasData = await isar.canvasDatas.where().findAll();
      expect(restoredCanvasData.length, 2);
      expect(restoredCanvasData.every((c) => c.json.isNotEmpty), isTrue);

      // Verify PDF files were restored
      final restoredNotesDir = Directory('${tempRoot!.path}/notes');
      expect(await restoredNotesDir.exists(), isTrue);
      
      final restoredPdfFiles = await restoredNotesDir
          .list(recursive: true)
          .where((e) => e is File && e.path.endsWith('.pdf'))
          .cast<File>()
          .toList();
      expect(restoredPdfFiles.length, 2);

      // Verify settings
      final restoredSettings = await isar.settingsEntitys.where().findFirst();
      expect(restoredSettings, isNotNull);
      expect(restoredSettings!.backupDailyAt, '03:00');
      expect(restoredSettings.backupRetentionDays, 14);
      expect(restoredSettings.pdfCacheMaxMB, 256);

      // Verify RecentTabs
      final restoredTabs = await isar.recentTabss.where().findFirst();
      expect(restoredTabs, isNotNull);
      expect(restoredTabs!.userId, 'local');
      expect(restoredTabs.noteIdsJson, isNotEmpty);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('encrypted backup and restore workflow maintains data integrity', () async {
      final isar = await IsarDb.instance.open();

      // Create test data
      final vault = await NoteDbService.instance.createVault(name: 'SecureVault');
      final note = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'Secret Note',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );

      // Create settings with encryption enabled
      await isar.writeTxn(() async {
        final settings = SettingsEntity()
          ..encryptionEnabled = true
          ..backupDailyAt = '02:00'
          ..backupRetentionDays = 7
          ..recycleRetentionDays = 30;
        await isar.settingsEntitys.put(settings);
      });

      // Store original data for comparison
      final originalVaultName = vault.name;
      const password = 'supersecret123';

      // Perform encrypted backup
      final backupPath = await BackupService.instance.performIntegratedBackup(
        retentionDays: 7,
        includeEncryption: true,
        customPassword: password,
      );

      expect(backupPath.endsWith('.zip.encrypted'), isTrue);

      // Clear data
      await isar.writeTxn(() async {
        await isar.clear();
      });

      // Restore with correct password
      final restoreResult = await BackupService.instance.restoreIntegratedBackup(
        backupPath: backupPath,
        password: password,
        overwriteExisting: true,
      );

      expect(restoreResult.success, isTrue);

      // Verify data was restored correctly
      final restoredVaults = await isar.vaults.where().findAll();
      expect(restoredVaults.length, 1);
      expect(restoredVaults.first.name, originalVaultName);

      final restoredNotes = await isar.notes.where().findAll();
      expect(restoredNotes.length, 1);
      expect(restoredNotes.first.name, 'Secret Note');

      // Test wrong password fails
      await isar.writeTxn(() async {
        await isar.clear();
      });

      final failedResult = await BackupService.instance.restoreIntegratedBackup(
        backupPath: backupPath,
        password: 'wrongpassword',
        overwriteExisting: true,
      );

      expect(failedResult.success, isFalse);
      expect(failedResult.message, contains('실패'));
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('backup test validates complete backup/restore cycle', () async {
      final isar = await IsarDb.instance.open();

      // Create substantial test data
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final folder = await NoteDbService.instance.createFolder(
        vaultId: vault.id,
        name: 'TestFolder',
      );
      
      for (int i = 0; i < 5; i++) {
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          folderId: folder.id,
          name: 'Note $i',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );
      }

      // Run comprehensive backup test
      final testResult = await BackupService.instance.testBackupRestore();

      expect(testResult.success, isTrue);
      expect(testResult.backupCreated, isTrue);
      expect(testResult.backupFileExists, isTrue);
      expect(testResult.metadataValid, isTrue);
      expect(testResult.databaseExtractable, isTrue);
      expect(testResult.message, contains('성공적으로 완료'));
      expect(testResult.error, isNull);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');
  });
}
