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
import 'package:it_contest/services/link/link_service.dart';
import 'package:it_contest/services/graph/graph_service.dart';
import 'package:it_contest/services/softdelete/soft_delete_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  Directory? tempRoot;

  setUp(() async {
    // Ensure fresh temp directory per test and mock path_provider
    tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempRoot!.path;
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
    if (tempRoot != null && await tempRoot!.exists()) {
      await tempRoot!.delete(recursive: true);
    }
  });

  group('Link Synchronization Tests', () {
    test('createLinkedNoteFromRegion creates note, link, and graph edge', () async {
      final isar = await IsarDb.instance.open();

      // Setup vault and source note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      // Create link region
      final region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);

      // Create linked note
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region,
        label: 'TestLink',
      );

      // Verify note was created
      expect(linkedNote.name, 'TestLink');
      expect(linkedNote.vaultId, vault.id);

      // Verify link was created
      final links = await isar.linkEntitys.where().findAll();
      expect(links.length, 1);
      
      final link = links.first;
      expect(link.vaultId, vault.id);
      expect(link.sourceNoteId, sourceNote.id);
      expect(link.sourcePageId, sourcePage.id);
      expect(link.targetNoteId, linkedNote.id);
      expect(link.label, 'TestLink');
      expect(link.dangling, isFalse);
      expect(link.x0, 0.1);
      expect(link.y0, 0.1);
      expect(link.x1, 0.3);
      expect(link.y1, 0.3);

      // Verify graph edge was created
      final edges = await isar.graphEdges.where().findAll();
      expect(edges.length, 1);
      
      final edge = edges.first;
      expect(edge.vaultId, vault.id);
      expect(edge.fromNoteId, sourceNote.id);
      expect(edge.toNoteId, linkedNote.id);

      // Verify page was created for linked note
      final pages = await isar.pages
          .filter()
          .noteIdEqualTo(linkedNote.id)
          .findAll();
      expect(pages.length, 1);
      expect(pages.first.index, 0);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('createLinkedNoteFromRegion ensures unique labels within source', () async {
      final isar = await IsarDb.instance.open();

      // Setup vault and source note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      final region1 = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
      final region2 = RectNorm(x0: 0.4, y0: 0.4, x1: 0.6, y1: 0.6);

      // Create first link with label "TestLink"
      final linkedNote1 = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region1,
        label: 'TestLink',
      );

      // Create second link with same label - should get unique suffix
      final linkedNote2 = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region2,
        label: 'TestLink',
      );

      // Verify unique labels
      expect(linkedNote1.name, 'TestLink');
      expect(linkedNote2.name, 'TestLink (2)');

      // Verify both links exist
      final links = await isar.linkEntitys.where().findAll();
      expect(links.length, 2);
      expect(links.map((l) => l.label).toSet(), {'TestLink', 'TestLink (2)'});
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('createLinkedNoteFromRegion normalizes and validates rect region', () async {
      final isar = await IsarDb.instance.open();

      // Setup vault and source note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      // Create region with coordinates in wrong order (should be normalized)
      final region = RectNorm(x0: 0.6, y0: 0.6, x1: 0.2, y1: 0.2);

      // Create linked note
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region,
        label: 'TestLink',
      );

      // Verify link was created with normalized coordinates
      final links = await isar.linkEntitys.where().findAll();
      expect(links.length, 1);
      
      final link = links.first;
      // Should be normalized: x0 < x1, y0 < y1
      expect(link.x0, 0.2);
      expect(link.y0, 0.2);
      expect(link.x1, 0.6);
      expect(link.y1, 0.6);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('createLinkedNoteFromRegion rejects invalid rect regions', () async {
      final isar = await IsarDb.instance.open();

      // Setup vault and source note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      // Test invalid regions
      final invalidRegions = [
        RectNorm(x0: -0.1, y0: 0.1, x1: 0.3, y1: 0.3), // x0 < 0
        RectNorm(x0: 0.1, y0: 0.1, x1: 1.1, y1: 0.3),  // x1 > 1
        RectNorm(x0: 0.1, y0: 0.1, x1: 0.1, y1: 0.3),  // x0 == x1
        RectNorm(x0: 0.1, y0: 0.3, x1: 0.3, y1: 0.3),  // y0 == y1
      ];

      for (final region in invalidRegions) {
        await expectLater(
          () => LinkService.instance.createLinkedNoteFromRegion(
            vaultId: vault.id,
            sourceNoteId: sourceNote.id,
            sourcePageId: sourcePage.id,
            region: region,
            label: 'TestLink',
          ),
          throwsA(isA<AssertionError>()),
        );
      }

      // Verify no links were created
      final links = await isar.linkEntitys.where().findAll();
      expect(links.length, 0);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('deleteLink removes link and corresponding graph edge', () async {
      final isar = await IsarDb.instance.open();

      // Setup and create linked note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      final region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region,
        label: 'TestLink',
      );

      // Verify link and edge exist
      final linksBefore = await isar.linkEntitys.where().findAll();
      final edgesBefore = await isar.graphEdges.where().findAll();
      expect(linksBefore.length, 1);
      expect(edgesBefore.length, 1);

      // Delete link
      await LinkService.instance.deleteLink(linksBefore.first.id);

      // Verify both link and edge are deleted
      final linksAfter = await isar.linkEntitys.where().findAll();
      final edgesAfter = await isar.graphEdges.where().findAll();
      expect(linksAfter.length, 0);
      expect(edgesAfter.length, 0);

      // Verify target note still exists (only link is deleted)
      final targetNote = await isar.notes.get(linkedNote.id);
      expect(targetNote, isNotNull);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('soft deleting target note marks links as dangling', () async {
      final isar = await IsarDb.instance.open();

      // Setup and create linked note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      final region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region,
        label: 'TestLink',
      );

      // Verify link is not dangling initially
      final linkBefore = await isar.linkEntitys.where().findFirst();
      expect(linkBefore!.dangling, isFalse);

      // Soft delete target note
      await SoftDeleteService.instance.softDeleteNote(linkedNote.id);

      // Verify link is now marked as dangling
      final linkAfter = await isar.linkEntitys.where().findFirst();
      expect(linkAfter!.dangling, isTrue);

      // Verify graph edge still exists (not deleted on soft delete)
      final edges = await isar.graphEdges.where().findAll();
      expect(edges.length, 1);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('restoring target note clears dangling flag', () async {
      final isar = await IsarDb.instance.open();

      // Setup and create linked note
      final vault = await NoteDbService.instance.createVault(name: 'TestVault');
      final sourceNote = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'SourceNote',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );
      final sourcePage = await NoteDbService.instance.createPage(
        noteId: sourceNote.id,
        index: 0,
      );

      final region = RectNorm(x0: 0.1, y0: 0.1, x1: 0.3, y1: 0.3);
      final linkedNote = await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: vault.id,
        sourceNoteId: sourceNote.id,
        sourcePageId: sourcePage.id,
        region: region,
        label: 'TestLink',
      );

      // Soft delete and verify dangling
      await SoftDeleteService.instance.softDeleteNote(linkedNote.id);
      final linkAfterDelete = await isar.linkEntitys.where().findFirst();
      expect(linkAfterDelete!.dangling, isTrue);

      // Restore note
      await SoftDeleteService.instance.restoreNote(linkedNote.id);

      // Verify link is no longer dangling
      final linkAfterRestore = await isar.linkEntitys.where().findFirst();
      expect(linkAfterRestore!.dangling, isFalse);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('graph edge unique constraint prevents duplicate edges', () async {
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

      // Create first edge manually
      final edge1 = GraphEdge()
        ..vaultId = vault.id
        ..fromNoteId = note1.id
        ..toNoteId = note2.id
        ..createdAt = DateTime.now();
      edge1.setUniqueKey();

      await isar.writeTxn(() async {
        await isar.graphEdges.put(edge1);
      });

      // Try to create duplicate edge
      await expectLater(
        () => isar.writeTxn(() async {
          final edge2 = GraphEdge()
            ..vaultId = vault.id
            ..fromNoteId = note1.id
            ..toNoteId = note2.id
            ..createdAt = DateTime.now();
          edge2.setUniqueKey();
          await isar.graphEdges.put(edge2);
        }),
        throwsA(isA<IsarError>()),
      );

      // Verify only one edge exists
      final edges = await isar.graphEdges.where().findAll();
      expect(edges.length, 1);
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');

    test('deleteEdgesBetween removes specific edges', () async {
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
      final note3 = await NoteDbService.instance.createNote(
        vaultId: vault.id,
        name: 'Note3',
        pageSize: 'A4',
        pageOrientation: 'portrait',
      );

      // Create multiple edges
      await isar.writeTxn(() async {
        final edge1to2 = GraphEdge()
          ..vaultId = vault.id
          ..fromNoteId = note1.id
          ..toNoteId = note2.id
          ..createdAt = DateTime.now();
        edge1to2.setUniqueKey();

        final edge1to3 = GraphEdge()
          ..vaultId = vault.id
          ..fromNoteId = note1.id
          ..toNoteId = note3.id
          ..createdAt = DateTime.now();
        edge1to3.setUniqueKey();

        final edge2to3 = GraphEdge()
          ..vaultId = vault.id
          ..fromNoteId = note2.id
          ..toNoteId = note3.id
          ..createdAt = DateTime.now();
        edge2to3.setUniqueKey();

        await isar.graphEdges.putAll([edge1to2, edge1to3, edge2to3]);
      });

      // Verify all edges exist
      final edgesBefore = await isar.graphEdges.where().findAll();
      expect(edgesBefore.length, 3);

      // Delete specific edge
      await GraphService.instance.deleteEdgesBetween(
        vaultId: vault.id,
        fromNoteId: note1.id,
        toNoteId: note2.id,
      );

      // Verify only the specific edge was deleted
      final edgesAfter = await isar.graphEdges.where().findAll();
      expect(edgesAfter.length, 2);

      final remainingEdges = edgesAfter.map((e) => '${e.fromNoteId}->${e.toNoteId}').toSet();
      expect(remainingEdges, {'${note1.id}->${note3.id}', '${note2.id}->${note3.id}'});
    }, skip: 'Requires native Isar runtime; run as integration test on device/desktop.');
  });
}
