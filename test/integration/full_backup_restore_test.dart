// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Ensure native libs are bundled for Flutter tests
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/services/link/link_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';
import 'package:it_contest/shared/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_all_the_time/flutter_secure_storage',
  );
  Directory? tempRoot;
  final Map<String, String> mockStorage = {};

  setUp(() async {
    // Ensure fresh temp directory per test and mock path_provider
    tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
    mockStorage.clear();

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
  });

  group('Full Backup and Restore Integration Tests', () {
    test(
      'complete backup and restore workflow preserves all data and relationships',
      () async {
        await IsarDb.instance.open();

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

        await NoteDbService.instance.createNote(
          vaultId: vault1.id,
          folderId: personalFolder.id,
          name: 'Personal Note 2',
          pageSize: 'Letter',
          pageOrientation: 'landscape',
          sortIndex: 2000,
        );

        await NoteDbService.instance.createNote(
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

        await NoteDbService.instance.createPage(
          noteId: workNote.id,
          index: 0,
        );

        // 5. Create canvas data
        await IsarDb.instance.isar.writeTxn(() async {
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

          await IsarDb.instance.isar.collection<CanvasData>().putAll([canvasData1, canvasData2]);
        });

        // 6. Create page snapshots
        await IsarDb.instance.isar.writeTxn(() async {
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

          await IsarDb.instance.isar.collection<PageSnapshot>().putAll([snapshot1, snapshot2]);
        });

        // 7. Create links and graph edges using LinkService
        const region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
        final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
          vaultId: vault1.id,
          sourceNoteId: personalNote1.id,
          sourcePageId: page1.id,
          region: region,
          label: 'Linked Note',
        );

        // 8. Create PDF cache metadata
        await IsarDb.instance.isar.writeTxn(() async {
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

          await IsarDb.instance.isar.pdfCacheMetas.putAll([cache1, cache2]);
        });

        // 9. Create RecentTabs
        await IsarDb.instance.isar.writeTxn(() async {
          final recentTabs = RecentTabs()
            ..userId = 'local'
            ..noteIdsJson = '[${personalNote1.id}, ${workNote.id}, ${linkedNote.id}]'
            ..updatedAt = DateTime.now();

          await IsarDb.instance.isar.recentTabs.put(recentTabs);
        });

        // 10. Create settings
        await IsarDb.instance.isar.writeTxn(() async {
          final settings = SettingsEntity()
            ..encryptionEnabled = false
            ..backupDailyAt = '03:00'
            ..backupRetentionDays = 14
            ..recycleRetentionDays = 30
            ..dataVersion = 1
            ..pdfCacheMaxMB = 256;

          await IsarDb.instance.isar.collection<SettingsEntity>().put(settings);
        });

        // 11. Create fake PDF files for integrated backup
        final notesDir = Directory('${tempRoot!.path}/notes');
        await notesDir.create(recursive: true);

        final pdfFile1 = File('${notesDir.path}/${personalNote1.id}/document.pdf');
        await pdfFile1.parent.create(recursive: true);
        await pdfFile1.writeAsBytes(List.generate(1000, (i) => i % 256)); // Fake PDF content

        final pdfFile2 = File('${notesDir.path}/${workNote.id}/presentation.pdf');
        await pdfFile2.parent.create(recursive: true);
        await pdfFile2.writeAsBytes(
          List.generate(2000, (i) => (i * 2) % 256),
        ); // Different fake content

        // Store counts for verification
        final currentIsar = IsarDb.instance.isar;
        final originalCounts = {
          'vaults': await currentIsar.collection<Vault>().count(),
          'folders': await currentIsar.collection<Folder>().count(),
          'notes': await currentIsar.collection<Note>().count(),
          'pages': await currentIsar.collection<Page>().count(),
          'canvasData': await currentIsar.collection<CanvasData>().count(),
          'pageSnapshots': await currentIsar.collection<PageSnapshot>().count(),
          'links': await currentIsar.collection<LinkEntity>().count(),
          'graphEdges': await currentIsar.collection<GraphEdge>().count(),
          'pdfCacheMetas': await currentIsar.collection<PdfCacheMeta>().count(),
          'recentTabs': await currentIsar.collection<RecentTabs>().count(),
          'settings': await currentIsar.collection<SettingsEntity>().count(),
        };

        // 12. Perform integrated backup
        final backupPath = await BackupService.instance.performIntegratedBackup(
          retentionDays: 7,
          includeEncryption: false,
        );

        expect(await File(backupPath).exists(), isTrue);

        // 13. Clear all data to simulate data loss
        await currentIsar.writeTxn(() async {
          await currentIsar.clear();
        });

        // Delete PDF files
        if (await notesDir.exists()) {
          await notesDir.delete(recursive: true);
        }

        // Verify data is gone
        expect(await currentIsar.collection<Vault>().count(), 0);
        expect(await currentIsar.collection<Note>().count(), 0);

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
          'vaults': await currentIsar.collection<Vault>().count(),
          'folders': await currentIsar.collection<Folder>().count(),
          'notes': await currentIsar.collection<Note>().count(),
          'pages': await currentIsar.collection<Page>().count(),
          'canvasData': await currentIsar.collection<CanvasData>().count(),
          'pageSnapshots': await currentIsar.collection<PageSnapshot>().count(),
          'links': await currentIsar.collection<LinkEntity>().count(),
          'graphEdges': await currentIsar.collection<GraphEdge>().count(),
          'pdfCacheMetas': await currentIsar.collection<PdfCacheMeta>().count(),
          'recentTabs': await currentIsar.collection<RecentTabs>().count(),
          'settings': await currentIsar.collection<SettingsEntity>().count(),
        };

        expect(restoredCounts, equals(originalCounts));

        // Verify specific data integrity
        final restoredVaults = await currentIsar.collection<Vault>().where().sortByName().findAll();
        expect(restoredVaults.length, 2);
        expect(restoredVaults[0].name, 'PersonalVault');
        expect(restoredVaults[1].name, 'WorkVault');

        final restoredPersonalNotes = await currentIsar
            .collection<Note>()
            .filter()
            .vaultIdEqualTo(restoredVaults[0].id)
            .sortByName()
            .findAll();
        expect(restoredPersonalNotes.length, 3); // 2 folder notes + 1 root note + 1 linked note
        expect(
          restoredPersonalNotes.map((Note n) => n.name).toList(),
          containsAll(['Personal Note 1', 'Personal Note 2', 'Root Note', 'Linked Note']),
        );

        // Verify relationships are preserved
        final restoredLinks = await currentIsar.collection<LinkEntity>().where().findAll();
        expect(restoredLinks.length, 1);
        expect(restoredLinks.first.label, 'Linked Note');
        expect(restoredLinks.first.dangling, isFalse);

        final restoredEdges = await currentIsar.collection<GraphEdge>().where().findAll();
        expect(restoredEdges.length, 1);
        expect(restoredEdges.first.fromNoteId, restoredLinks.first.sourceNoteId);
        expect(restoredEdges.first.toNoteId, restoredLinks.first.targetNoteId);

        // Verify canvas data
        final restoredCanvasData = await currentIsar.collection<CanvasData>().where().findAll();
        expect(restoredCanvasData.length, 2);
        expect(restoredCanvasData.every((CanvasData c) => c.json.isNotEmpty), isTrue);

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
        final restoredSettings = await currentIsar.collection<SettingsEntity>().where().findFirst();
        expect(restoredSettings, isNotNull);
        expect(restoredSettings!.backupDailyAt, '03:00');
        expect(restoredSettings.backupRetentionDays, 14);
        expect(restoredSettings.pdfCacheMaxMB, 256);

        // Verify RecentTabs
        final restoredTabs = await currentIsar.collection<RecentTabs>().where().findFirst();
        expect(restoredTabs, isNotNull);
        expect(restoredTabs!.userId, 'local');
        expect(restoredTabs.noteIdsJson, isNotEmpty);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'encrypted backup and restore workflow maintains data integrity',
      () async {
        await IsarDb.instance.open();

        // Create test data
        final vault = await NoteDbService.instance.createVault(name: 'SecureVault');
        await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'Secret Note',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create settings with encryption enabled
        await IsarDb.instance.isar.writeTxn(() async {
          final settings = SettingsEntity()
            ..encryptionEnabled = true
            ..backupDailyAt = '02:00'
            ..backupRetentionDays = 7
            ..recycleRetentionDays = 30;
          await IsarDb.instance.isar.collection<SettingsEntity>().put(settings);
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
        await IsarDb.instance.isar.writeTxn(() async {
          await IsarDb.instance.isar.clear();
        });

        // Restore with correct password
        final restoreResult = await BackupService.instance.restoreIntegratedBackup(
          backupPath: backupPath,
          password: password,
          overwriteExisting: true,
        );

        expect(restoreResult.success, isTrue);

        // Verify data was restored correctly
        final restoredVaults = await IsarDb.instance.isar.collection<Vault>().where().findAll();
        expect(restoredVaults.length, 1);
        expect(restoredVaults.first.name, originalVaultName);

        final restoredNotes = await IsarDb.instance.isar.collection<Note>().where().findAll();
        expect(restoredNotes.length, 1);
        expect(restoredNotes.first.name, 'Secret Note');

        // Test wrong password fails
        await IsarDb.instance.isar.writeTxn(() async {
          await IsarDb.instance.isar.clear();
        });

        final failedResult = await BackupService.instance.restoreIntegratedBackup(
          backupPath: backupPath,
          password: 'wrongpassword',
          overwriteExisting: true,
        );

        expect(failedResult.success, isFalse);
        expect(failedResult.message, contains('실패'));
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'backup test validates complete backup/restore cycle',
      () async {
        await IsarDb.instance.open();

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
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });
}
