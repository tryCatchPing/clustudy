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
import 'package:it_contest/features/db/isar/db_schemas.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  Directory? tempRoot;

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
    if (tempRoot != null && await tempRoot!.exists()) {
      await tempRoot!.delete(recursive: true);
    }
  });

  group('Unique Constraints Tests', () {
    test(
      'Vault nameLowerUnique constraint prevents duplicates',
      () async {
        final isar = await IsarDb.instance.open();

        // Create first vault
        final vault1 = await NoteDbService.instance.createVault(name: 'TestVault');
        expect(vault1.nameLowerUnique, 'testvault');

        // Try to create duplicate vault (case insensitive)
        await expectLater(
          () => NoteDbService.instance.createVault(name: 'TESTVAULT'),
          throwsA(isA<IsarError>()),
        );

        // Verify only one vault exists
        final vaults = await isar.collection<Vault>().filter().findAll();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'TestVault');
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'Folder nameLowerForVaultUnique constraint works within vault scope',
      () async {
        final isar = await IsarDb.instance.open();

        // Create vaults
        final vault1 = await NoteDbService.instance.createVault(name: 'Vault1');
        final vault2 = await NoteDbService.instance.createVault(name: 'Vault2');

        // Create folder in vault1
        final folder1 = await NoteDbService.instance.createFolder(
          vaultId: vault1.id,
          name: 'TestFolder',
        );
        expect(folder1.nameLowerForVaultUnique, 'testfolder');

        // Should allow same name in different vault
        final folder2 = await NoteDbService.instance.createFolder(
          vaultId: vault2.id,
          name: 'TestFolder',
        );
        expect(folder2.nameLowerForVaultUnique, 'testfolder');

        // Should prevent duplicate in same vault
        await expectLater(
          () => NoteDbService.instance.createFolder(
            vaultId: vault1.id,
            name: 'testfolder', // case insensitive
          ),
          throwsA(isA<IsarError>()),
        );

        // Verify folder counts
        final vault1Folders = await isar.collection<Folder>().filter().vaultIdEqualTo(vault1.id).findAll();
        expect(vault1Folders.length, 1);

        final vault2Folders = await isar.collection<Folder>().filter().vaultIdEqualTo(vault2.id).findAll();
        expect(vault2Folders.length, 1);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'Note nameLowerForParentUnique constraint works within folder scope',
      () async {
        final isar = await IsarDb.instance.open();

        // Setup vault and folders
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        final folder1 = await NoteDbService.instance.createFolder(
          vaultId: vault.id,
          name: 'Folder1',
        );
        final folder2 = await NoteDbService.instance.createFolder(
          vaultId: vault.id,
          name: 'Folder2',
        );

        // Create note in folder1
        final note1 = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          folderId: folder1.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );
        expect(note1.nameLowerForParentUnique, 'testnote');

        // Should allow same name in different folder
        final note2 = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          folderId: folder2.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );
        expect(note2.nameLowerForParentUnique, 'testnote');

        // Should allow same name in root (null folder)
        final note3 = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          folderId: null,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );
        expect(note3.nameLowerForParentUnique, 'testnote');

        // Should prevent duplicate in same folder
        await expectLater(
          () => NoteDbService.instance.createNote(
            vaultId: vault.id,
            folderId: folder1.id,
            name: 'TESTNOTE', // case insensitive
            pageSize: 'A4',
            pageOrientation: 'portrait',
          ),
          throwsA(isA<IsarError>()),
        );

        // Verify note counts
        final folder1Notes = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(vault.id)
            .and()
            .folderIdEqualTo(folder1.id)
            .findAll();
        expect(folder1Notes.length, 1);

        final folder2Notes = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(vault.id)
            .and()
            .folderIdEqualTo(folder2.id)
            .findAll();
        expect(folder2Notes.length, 1);

        final rootNotes = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(vault.id)
            .and()
            .folderIdIsNull()
            .findAll();
        expect(rootNotes.length, 1);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'GraphEdge unique constraint prevents duplicate edges',
      () async {
        final isar = await IsarDb.instance.open();

        // Setup vault and notes
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        final note1 = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'Note1',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );
        final note2 = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'Note2',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create first edge
        final edge1 = GraphEdge()
          ..vaultId = vault.id
          ..fromNoteId = note1.id
          ..toNoteId = note2.id
          ..createdAt = DateTime.now();
        edge1.setUniqueKey();

        await isar.writeTxn(() async {
          await isar.collection<GraphEdge>().put(edge1);
        });

        // Try to create duplicate edge
        final edge2 = GraphEdge()
          ..vaultId = vault.id
          ..fromNoteId = note1.id
          ..toNoteId = note2.id
          ..createdAt = DateTime.now();
        edge2.setUniqueKey();

        await expectLater(
          () => isar.writeTxn(() async {
            await isar.collection<GraphEdge>().put(edge2);
          }),
          throwsA(isA<IsarError>()),
        );

        // Verify only one edge exists
        final edges = await isar.collection<GraphEdge>().filter().findAll();
        expect(edges.length, 1);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'PdfCacheMeta unique constraint prevents duplicate cache entries',
      () async {
        final isar = await IsarDb.instance.open();

        // Setup vault and note
        final vault = await NoteDbService.instance.createVault(name: 'TestVault');
        final note = await NoteDbService.instance.createNote(
          vaultId: vault.id,
          name: 'TestNote',
          pageSize: 'A4',
          pageOrientation: 'portrait',
        );

        // Create first cache entry
        final cache1 = PdfCacheMeta()
          ..noteId = note.id
          ..pageIndex = 0
          ..cachePath = '/test/path1.png'
          ..dpi = 144
          ..renderedAt = DateTime.now();
        cache1.setUniqueKey();

        await isar.writeTxn(() async {
          await isar.collection<PdfCacheMeta>().put(cache1);
        });

        // Try to create duplicate cache entry
        final cache2 = PdfCacheMeta()
          ..noteId = note.id
          ..pageIndex =
              0 // Same noteId and pageIndex
          ..cachePath = '/test/path2.png'
          ..dpi = 144
          ..renderedAt = DateTime.now();
        cache2.setUniqueKey();

        await expectLater(
          () => isar.writeTxn(() async {
            await isar.collection<PdfCacheMeta>().put(cache2);
          }),
          throwsA(isA<IsarError>()),
        );

        // Should allow different pageIndex
        final cache3 = PdfCacheMeta()
          ..noteId = note.id
          ..pageIndex =
              1 // Different pageIndex
          ..cachePath = '/test/path3.png'
          ..dpi = 144
          ..renderedAt = DateTime.now();
        cache3.setUniqueKey();

        await isar.writeTxn(() async {
          await isar.collection<PdfCacheMeta>().put(cache3);
        });

        // Verify correct number of cache entries
        final caches = await isar.collection<PdfCacheMeta>().filter().findAll();
        expect(caches.length, 2);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'RecentTabs userId unique constraint ensures single record',
      () async {
        final isar = await IsarDb.instance.open();

        // Create first RecentTabs record
        final tabs1 = RecentTabs()
          ..userId = 'local'
          ..noteIdsJson = '[1, 2, 3]'
          ..updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.collection<RecentTabs>().put(tabs1);
        });

        // Try to create duplicate userId
        final tabs2 = RecentTabs()
          ..userId =
              'local' // Same userId
          ..noteIdsJson = '[4, 5, 6]'
          ..updatedAt = DateTime.now();

        await expectLater(
          () => isar.writeTxn(() async {
            await isar.collection<RecentTabs>().put(tabs2);
          }),
          throwsA(isA<IsarError>()),
        );

        // Should allow different userId
        final tabs3 = RecentTabs()
          ..userId =
              'user2' // Different userId
          ..noteIdsJson = '[7, 8, 9]'
          ..updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.collection<RecentTabs>().put(tabs3);
        });

        // Verify correct records exist
        final allTabs = await isar.collection<RecentTabs>().filter().findAll();
        expect(allTabs.length, 2);
        expect(allTabs.map((t) => t.userId).toSet(), {'local', 'user2'});
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });
}
