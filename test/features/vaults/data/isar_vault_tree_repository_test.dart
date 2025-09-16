import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_contest/features/vaults/data/isar_vault_tree_repository.dart';
import 'package:it_contest/features/vaults/models/vault_item.dart';
import 'package:it_contest/features/vaults/models/vault_model.dart';
import '../../../shared/utils/test_isar.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late TestIsarContext isarContext;
  late IsarVaultTreeRepository repository;

  setUp(() async {
    isarContext = await openTestIsar();
    repository = IsarVaultTreeRepository(isar: isarContext.isar);
  });

  tearDown(() async {
    repository.dispose();
    await isarContext.dispose();
  });

  group('IsarVaultTreeRepository', () {
    test('watchVaults emits sorted updates when vaults change', () async {
      final queue = StreamQueue<List<VaultModel>>(repository.watchVaults());

      final initial = await queue.next.timeout(const Duration(seconds: 5));
      expect(initial, isEmpty);

      final beta = await repository.createVault(' beta ');
      final afterFirst = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterFirst.map((v) => v.name), ['beta']);

      final alpha = await repository.createVault('Alpha');
      final afterSecond = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterSecond.map((v) => v.name), ['Alpha', 'beta']);

      await repository.renameVault(beta.vaultId, 'zeta');
      final afterRename = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterRename.map((v) => v.name), ['Alpha', 'zeta']);

      await repository.deleteVault(alpha.vaultId);
      final afterDelete = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterDelete.map((v) => v.name), ['zeta']);

      await queue.cancel();
    });

    test(
      'watchFolderChildren merges folder and note updates with sorting',
      () async {
        final vault = await repository.createVault('Workspace');

        final queue = StreamQueue<List<VaultItem>>(
          repository.watchFolderChildren(vault.vaultId),
        );

        final initial = await queue.next.timeout(const Duration(seconds: 5));
        expect(initial, isEmpty);

        await repository.createFolder(
          vault.vaultId,
          name: 'Zeta',
        );
        final afterFolder = await queue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(afterFolder, hasLength(1));
        expect(afterFolder.single.type, VaultItemType.folder);
        expect(afterFolder.single.name, 'Zeta');

        final noteId = await repository.createNote(
          vault.vaultId,
          name: 'Alpha note',
        );
        final afterNote = await queue.next.timeout(const Duration(seconds: 5));
        expect(afterNote.map((item) => item.type), [
          VaultItemType.folder,
          VaultItemType.note,
        ]);
        expect(afterNote.map((item) => item.name), ['Zeta', 'Alpha note']);

        final alphaFolder = await repository.createFolder(
          vault.vaultId,
          name: 'alpha folder',
        );
        final afterSecondFolder = await queue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(
          afterSecondFolder.map((item) => item.name),
          ['alpha folder', 'Zeta', 'Alpha note'],
        );

        await repository.moveNote(
          noteId: noteId,
          newParentFolderId: alphaFolder.folderId,
        );
        final afterMove = await queue.next.timeout(const Duration(seconds: 5));
        expect(
          afterMove.map((item) => item.type),
          [VaultItemType.folder, VaultItemType.folder],
        );

        final folderQueue = StreamQueue<List<VaultItem>>(
          repository.watchFolderChildren(
            vault.vaultId,
            parentFolderId: alphaFolder.folderId,
          ),
        );
        final nestedInitial = await folderQueue.next.timeout(
          const Duration(seconds: 5),
        );
        expect(nestedInitial, hasLength(1));
        expect(nestedInitial.single.id, equals(noteId));
        expect(nestedInitial.single.type, VaultItemType.note);

        await folderQueue.cancel();
        await queue.cancel();
      },
    );

    test(
      'getFolderAncestors and getFolderDescendants traverse hierarchy',
      () async {
        final vault = await repository.createVault('Hierarchy');

        final root = await repository.createFolder(vault.vaultId, name: 'Root');
        final child = await repository.createFolder(
          vault.vaultId,
          parentFolderId: root.folderId,
          name: 'Child',
        );
        final grandchild = await repository.createFolder(
          vault.vaultId,
          parentFolderId: child.folderId,
          name: 'Grandchild',
        );

        final ancestors = await repository.getFolderAncestors(
          grandchild.folderId,
        );
        expect(
          ancestors.map((folder) => folder.folderId),
          [root.folderId, child.folderId, grandchild.folderId],
        );

        final descendants = await repository.getFolderDescendants(
          root.folderId,
        );
        expect(
          descendants.map((folder) => folder.folderId),
          [child.folderId, grandchild.folderId],
        );
      },
    );

    test('searchNotes ranks results and applies exclusions', () async {
      final vault = await repository.createVault('Search');

      final exactId = await repository.createNote(vault.vaultId, name: 'Alpha');
      final prefixId = await repository.createNote(
        vault.vaultId,
        name: 'Alpha plan',
      );
      final containsId = await repository.createNote(
        vault.vaultId,
        name: 'Project Alpha',
      );
      final excludeId = await repository.createNote(
        vault.vaultId,
        name: 'Alpha exclude',
      );
      await repository.createNote(vault.vaultId, name: 'Beta');

      final results = await repository.searchNotes(
        vault.vaultId,
        'alpha',
        excludeNoteIds: {excludeId},
      );

      expect(results.map((note) => note.noteId), [
        exactId,
        prefixId,
        containsId,
      ]);

      final exactResults = await repository.searchNotes(
        vault.vaultId,
        'project alpha',
        exact: true,
      );
      expect(exactResults.map((note) => note.noteId), [containsId]);

      final limited = await repository.searchNotes(
        vault.vaultId,
        'alpha',
        limit: 1,
      );
      expect(limited.map((note) => note.noteId), [exactId]);
    });
  });
}
