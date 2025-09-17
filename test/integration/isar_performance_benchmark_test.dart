import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:it_contest/features/canvas/data/isar_link_repository.dart';
import 'package:it_contest/features/canvas/data/memory_link_repository.dart';
import 'package:it_contest/features/canvas/models/link_model.dart';
import 'package:it_contest/features/vaults/data/isar_vault_tree_repository.dart';
import 'package:it_contest/features/vaults/data/memory_vault_tree_repository.dart';

import '../shared/utils/test_isar.dart';

Future<({String isarVaultId, String memoryVaultId})>
_populateVaultRepositories({
  required IsarVaultTreeRepository isarRepo,
  required MemoryVaultTreeRepository memoryRepo,
  required String vaultName,
  required int noteCount,
}) async {
  final isarVault = await isarRepo.createVault(vaultName);
  final memoryVault = await memoryRepo.createVault(vaultName);

  final isarFolders = <int, String?>{0: null};
  final memoryFolders = <int, String?>{0: null};

  for (var i = 1; i <= 3; i++) {
    final folderName = 'Folder $i';
    final isarFolder = await isarRepo.createFolder(
      isarVault.vaultId,
      name: folderName,
    );
    final memoryFolder = await memoryRepo.createFolder(
      memoryVault.vaultId,
      name: folderName,
    );
    isarFolders[i] = isarFolder.folderId;
    memoryFolders[i] = memoryFolder.folderId;
  }

  for (var i = 0; i < noteCount; i++) {
    final rawName = 'Benchmark Note ${i.toString().padLeft(4, '0')}';
    final parentKey = i % 4;
    await isarRepo.createNote(
      isarVault.vaultId,
      parentFolderId: isarFolders[parentKey],
      name: rawName,
    );
    await memoryRepo.createNote(
      memoryVault.vaultId,
      parentFolderId: memoryFolders[parentKey],
      name: rawName,
    );
  }

  return (
    isarVaultId: isarVault.vaultId,
    memoryVaultId: memoryVault.vaultId,
  );
}

Future<List<LinkModel>> _generateLinks(int count) async {
  final now = DateTime.now();
  return List<LinkModel>.generate(count, (index) {
    final sourceNote = 'source-note-${index % 40}';
    final sourcePage = 'source-page-${index % 80}';
    final targetNote = 'target-note-${index % 50}';
    final created = now.add(Duration(milliseconds: index));
    return LinkModel(
      id: 'link-$index',
      sourceNoteId: sourceNote,
      sourcePageId: sourcePage,
      targetNoteId: targetNote,
      bboxLeft: (index % 10).toDouble(),
      bboxTop: (index % 15).toDouble(),
      bboxWidth: 100 + (index % 5),
      bboxHeight: 40 + (index % 7),
      label: 'Link $index',
      anchorText: 'Anchor $index',
      createdAt: created,
      updatedAt: created,
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Isar performance benchmarks', () {
    test(
      'searchNotes stays within acceptable latency for large dataset',
      () async {
        final isarContext = await openTestIsar(name: 'benchmark_search');
        final isarRepo = IsarVaultTreeRepository(isar: isarContext.isar);
        final memoryRepo = MemoryVaultTreeRepository();

        const noteCount = 240;
        final vaultIds = await _populateVaultRepositories(
          isarRepo: isarRepo,
          memoryRepo: memoryRepo,
          vaultName: 'Benchmark Vault',
          noteCount: noteCount,
        );

        const queries = [
          'Benchmark Note 000',
          'note 050',
          'Note 150',
          'Benchmark',
          'Note 239',
        ];

        await isarRepo.searchNotes(vaultIds.isarVaultId, queries.first);
        await memoryRepo.searchNotes(vaultIds.memoryVaultId, queries.first);

        const iterations = 40;
        final isarWatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          final query = queries[i % queries.length];
          await isarRepo.searchNotes(vaultIds.isarVaultId, query);
        }
        isarWatch.stop();

        final memoryWatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          final query = queries[i % queries.length];
          await memoryRepo.searchNotes(vaultIds.memoryVaultId, query);
        }
        memoryWatch.stop();

        expect(
          Duration(microseconds: isarWatch.elapsedMicroseconds),
          lessThan(const Duration(seconds: 2)),
        );
        expect(
          Duration(microseconds: memoryWatch.elapsedMicroseconds),
          lessThan(const Duration(seconds: 1)),
        );

        isarRepo.dispose();
        await isarContext.dispose();
        memoryRepo.dispose();
      },
    );

    test('backlink aggregation completes within bounded time', () async {
      final isarContext = await openTestIsar(name: 'benchmark_links');
      final isarRepo = IsarLinkRepository(isar: isarContext.isar);
      final memoryRepo = MemoryLinkRepository();

      final links = await _generateLinks(600);
      await isarRepo.createMultipleLinks(links);
      await memoryRepo.createMultipleLinks(links);

      final noteIds = List<String>.generate(
        50,
        (index) => 'target-note-$index',
      );

      await isarRepo.getBacklinkCountsForNotes(noteIds);
      await memoryRepo.getBacklinkCountsForNotes(noteIds);

      const iterations = 30;
      final isarWatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        await isarRepo.getBacklinkCountsForNotes(noteIds);
      }
      isarWatch.stop();

      final memoryWatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        await memoryRepo.getBacklinkCountsForNotes(noteIds);
      }
      memoryWatch.stop();

      expect(
        Duration(microseconds: isarWatch.elapsedMicroseconds),
        lessThan(const Duration(seconds: 1)),
      );
      expect(
        Duration(microseconds: memoryWatch.elapsedMicroseconds),
        lessThan(const Duration(milliseconds: 200)),
      );

      isarRepo.dispose();
      await isarContext.dispose();
      memoryRepo.dispose();
    });
  });
}
