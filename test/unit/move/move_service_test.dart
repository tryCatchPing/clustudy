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
import 'package:it_contest/services/move/move_service.dart' as move_api;

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

  group('MoveService.moveNote', () {
    test(
      'moves to another folder (append) and compacts indices',
      () async {
        final isar = await IsarDb.instance.open();

        final v = await NoteDbService.instance.createVault(name: 'V');
        final f1 = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'F1',
          sortIndex: 1000,
        );
        final f2 = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'F2',
          sortIndex: 2000,
        );

        final m = await NoteDbService.instance.createNote(
          vaultId: v.id,
          folderId: f1.id,
          name: 'M',
          pageSize: 'A4',
          pageOrientation: 'portrait',
          sortIndex: 3000,
        );

        await move_api.moveNote(noteId: m.id, targetFolderId: f2.id);

        final moved = await isar.collection<Note>().get(m.id);
        expect(moved, isNotNull);
        expect(moved!.folderId, f2.id);

        // After compaction, only one note in f2, its sortIndex should be 1000
        final inF2 = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(v.id)
            .and()
            .folderIdEqualTo(f2.id)
            .and()
            .deletedAtIsNull()
            .sortBySortIndex()
            .findAll();
        expect(inF2.length, 1);
        expect(inF2.first.sortIndex, 1000);

        // Source folder still contains n1, n2 compacted to 1000, 2000
        final inF1 = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(v.id)
            .and()
            .folderIdEqualTo(f1.id)
            .and()
            .deletedAtIsNull()
            .sortBySortIndex()
            .findAll();
        expect(inF1.map((e) => e.name).toList(), ['N1', 'N2']);
        expect(inF1[0].sortIndex, 1000);
        expect(inF1[1].sortIndex, 2000);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'moves before specific note in target folder',
      () async {
        final isar = await IsarDb.instance.open();

        final v = await NoteDbService.instance.createVault(name: 'V');
        final f1 = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'F1',
          sortIndex: 1000,
        );
        final f2 = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'F2',
          sortIndex: 2000,
        );

        final t2 = await NoteDbService.instance.createNote(
          vaultId: v.id,
          folderId: f2.id,
          name: 'T2',
          pageSize: 'A4',
          pageOrientation: 'portrait',
          sortIndex: 2000,
        );
        final m = await NoteDbService.instance.createNote(
          vaultId: v.id,
          folderId: f1.id,
          name: 'M',
          pageSize: 'A4',
          pageOrientation: 'portrait',
          sortIndex: 1000,
        );

        await move_api.moveNote(noteId: m.id, targetFolderId: f2.id, beforeNoteId: t2.id);

        final inF2 = await isar.collection<Note>()
            .filter()
            .vaultIdEqualTo(v.id)
            .and()
            .folderIdEqualTo(f2.id)
            .and()
            .deletedAtIsNull()
            .sortBySortIndex()
            .findAll();
        expect(inF2.map((e) => e.name).toList(), ['T1', 'M', 'T2']);
        expect(inF2[0].sortIndex, 1000);
        expect(inF2[1].sortIndex, 2000);
        expect(inF2[2].sortIndex, 3000);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );

    test(
      'rejects cross-vault move',
      () async {
        final v1 = await NoteDbService.instance.createVault(name: 'V1');
        final v2 = await NoteDbService.instance.createVault(name: 'V2');
        final f1 = await NoteDbService.instance.createFolder(
          vaultId: v1.id,
          name: 'F1',
          sortIndex: 1000,
        );
        final f2 = await NoteDbService.instance.createFolder(
          vaultId: v2.id,
          name: 'F2',
          sortIndex: 1000,
        );
        final m = await NoteDbService.instance.createNote(
          vaultId: v1.id,
          folderId: f1.id,
          name: 'M',
          pageSize: 'A4',
          pageOrientation: 'portrait',
          sortIndex: 1000,
        );

        await expectLater(
          () => move_api.moveNote(noteId: m.id, targetFolderId: f2.id),
          throwsA(isA<IsarError>()),
        );
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });

  group('MoveService.moveFolder', () {
    test(
      'reorders folders at vault root level',
      () async {
        final isar = await IsarDb.instance.open();

        final v = await NoteDbService.instance.createVault(name: 'V');
        final b = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'B',
          sortIndex: 2000,
        );
        final c = await NoteDbService.instance.createFolder(
          vaultId: v.id,
          name: 'C',
          sortIndex: 3000,
        );

        // Move C before B
        await move_api.moveFolder(folderId: c.id, targetParentFolderId: 0, beforeFolderId: b.id);

        final folders = await isar.collection<Folder>()
            .filter()
            .vaultIdEqualTo(v.id)
            .deletedAtIsNull()
            .sortBySortIndex()
            .findAll();
        expect(folders.map((e) => e.name).toList(), ['A', 'C', 'B']);
        expect(folders[0].sortIndex, 1000);
        expect(folders[1].sortIndex, 2000);
        expect(folders[2].sortIndex, 3000);
      },
      skip: 'Requires native Isar runtime; run as integration test on device/desktop.',
    );
  });
}
