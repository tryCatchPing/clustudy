import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:it_contest/features/canvas/data/isar_link_repository.dart';
import 'package:it_contest/features/canvas/models/link_model.dart';
import 'package:it_contest/features/notes/data/isar_notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/features/vaults/data/isar_vault_tree_repository.dart';
import 'package:it_contest/features/vaults/models/vault_item.dart';
import 'package:it_contest/shared/services/isar_database_service.dart';

class _FixedPathProvider extends PathProviderPlatform {
  _FixedPathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

const _blankSketchJson = '{"lines":[]}';

NoteModel _buildBlankNote(String noteId, String title, String pageId) {
  return NoteModel(
    noteId: noteId,
    title: title,
    pages: [
      NotePageModel(
        noteId: noteId,
        pageId: pageId,
        pageNumber: 1,
        jsonData: _blankSketchJson,
        backgroundType: PageBackgroundType.blank,
      ),
    ],
    sourceType: NoteSourceType.blank,
  );
}

void main() {
  group('Isar end-to-end integration', () {
    late PathProviderPlatform originalPathProvider;
    Directory? documentsDir;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      originalPathProvider = PathProviderPlatform.instance;
    });

    tearDown(() async {
      await IsarDatabaseService.close();
      if (documentsDir != null && await documentsDir!.exists()) {
        await documentsDir!.delete(recursive: true);
      }
      documentsDir = null;
      PathProviderPlatform.instance = originalPathProvider;
    });

    test(
      'persists vault, notes, and links across database restart',
      () async {
        documentsDir = await Directory.systemTemp.createTemp('isar_e2e');
        PathProviderPlatform.instance = _FixedPathProvider(documentsDir!.path);

        final isar = await IsarDatabaseService.getInstance();
        final vaultRepo = IsarVaultTreeRepository(isar: isar);
        final notesRepo = IsarNotesRepository(isar: isar);
        final linkRepo = IsarLinkRepository(isar: isar);

        final vault = await vaultRepo.createVault('Workspace');
        final rootQueue = StreamQueue(
          vaultRepo.watchFolderChildren(vault.vaultId),
        );
        expect(await rootQueue.next, isEmpty);

        final algorithmsFolder = await vaultRepo.createFolder(
          vault.vaultId,
          name: 'Algorithms',
        );
        final afterFolder = await rootQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(afterFolder.single.type, VaultItemType.folder);
        expect(afterFolder.single.id, equals(algorithmsFolder.folderId));

        final graphNoteId = await vaultRepo.createNote(
          vault.vaultId,
          name: 'Graph Theory',
        );
        final graphPageId = 'graph-page';
        await notesRepo.upsert(
          _buildBlankNote(graphNoteId, 'Graph Theory', graphPageId),
        );
        final afterGraphNote = await rootQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(
          afterGraphNote.map((item) => item.type),
          [VaultItemType.folder, VaultItemType.note],
        );

        await vaultRepo.moveNote(
          noteId: graphNoteId,
          newParentFolderId: algorithmsFolder.folderId,
        );
        final afterMove = await rootQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(afterMove.map((item) => item.type), [VaultItemType.folder]);

        final folderQueue = StreamQueue(
          vaultRepo.watchFolderChildren(
            vault.vaultId,
            parentFolderId: algorithmsFolder.folderId,
          ),
        );
        final folderInitial = await folderQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(folderInitial.single.id, equals(graphNoteId));

        final dpNoteId = await vaultRepo.createNote(
          vault.vaultId,
          parentFolderId: algorithmsFolder.folderId,
          name: 'Dynamic Programming',
        );
        final dpPageId = 'dp-page';
        await notesRepo.upsert(
          _buildBlankNote(dpNoteId, 'Dynamic Programming', dpPageId),
        );
        final folderAfterDp = await folderQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(
          folderAfterDp.map((item) => item.id).toSet(),
          {graphNoteId, dpNoteId},
        );

        final backlinksQueue = StreamQueue(
          linkRepo.watchBacklinksToNote(dpNoteId),
        );
        expect(await backlinksQueue.next, isEmpty);

        final link = LinkModel(
          id: 'link-graph-to-dp',
          sourceNoteId: graphNoteId,
          sourcePageId: graphPageId,
          targetNoteId: dpNoteId,
          bboxLeft: 0,
          bboxTop: 0,
          bboxWidth: 120,
          bboxHeight: 80,
          label: 'See DP note',
          anchorText: 'reference',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await linkRepo.create(link);
        final afterLink = await backlinksQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(afterLink.single.id, equals(link.id));

        await rootQueue.cancel();
        await folderQueue.cancel();
        await backlinksQueue.cancel();
        await IsarDatabaseService.close();

        final reopened = await IsarDatabaseService.getInstance();
        final reopenedVaultRepo = IsarVaultTreeRepository(isar: reopened);
        final reopenedNotesRepo = IsarNotesRepository(isar: reopened);
        final reopenedLinkRepo = IsarLinkRepository(isar: reopened);

        final persistedVaults = await reopenedVaultRepo.watchVaults().first;
        expect(
          persistedVaults.map((v) => v.vaultId),
          contains(vault.vaultId),
        );

        final persistedPlacement = await reopenedVaultRepo.getNotePlacement(
          graphNoteId,
        );
        expect(
          persistedPlacement?.parentFolderId,
          equals(algorithmsFolder.folderId),
        );

        final persistedNote = await reopenedNotesRepo.getNoteById(graphNoteId);
        expect(persistedNote?.title, equals('Graph Theory'));
        expect(persistedNote?.pages, isNotEmpty);

        final persistedLinks = await reopenedLinkRepo.getBacklinksForNote(
          dpNoteId,
        );
        expect(persistedLinks.map((l) => l.id), [link.id]);

        final metadata = await reopened.databaseMetadataEntitys.get(0);
        expect(metadata?.schemaVersion, equals(1));
        expect(metadata?.lastMigrationAt, isNotNull);

        final info = await IsarDatabaseService.getDatabaseInfo();
        expect(info.name, equals('it_contest_db'));
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
      },
    );
  });
}
