// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/search/search_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';

class NoteDbService {
  NoteDbService._();
  static final NoteDbService instance = NoteDbService._();

  Future<NoteModel> createNote({
    required int vaultId,
    required int folderId,
    required String name,
    required String pageSize,
    required String pageOrientation,
    int sortIndex = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    final note = NoteModel.create(
      noteId: DateTime.now().millisecondsSinceEpoch.toString(),
      title: name,
      vaultId: vaultId,
      folderId: folderId,
      sortIndex: sortIndex,
      sourceType: NoteSourceType.blank,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await isar.writeTxn(() async {
      await isar.collection<NoteModel>().put(note);
    });
    return note;
  }

  Future<Page> createPage({
    required int noteId,
    required int index,
    int widthPx = 2480,
    int heightPx = 3508,
    int rotationDeg = 0,
  }) async {
    final isar = await IsarDb.instance.open();
    final page = Page()
      ..noteId = noteId
      ..index = index
      ..widthPx = widthPx
      ..heightPx = heightPx
      ..rotationDeg = rotationDeg
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.pages.put(page);
    });
    return page;
  }

  Future<LinkEntity> createLinkAndTargetNote({
    required int vaultId,
    required int folderId,
    required int sourceNoteId,
    required int sourcePageId,
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required String label,
    required String pageSize,
    required String pageOrientation,
    int initialPageIndex = 0,
  }) async {
    final rect = RectNorm(x0: x0, y0: y0, x1: x1, y1: y1).normalized();
    rect.assertValid();
    final isar = await IsarDb.instance.open();
    late final NoteModel newNote;
    late final LinkEntity link;
    await isar.writeTxn(() async {
      // Create note directly in transaction to set all fields
      newNote = NoteModel.create(
        noteId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: label,
        vaultId: vaultId,
        folderId: folderId,
        sourceType: NoteSourceType.blank,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await isar.collection<NoteModel>().put(newNote);
      await createPage(noteId: int.tryParse(newNote.noteId) ?? 0, index: initialPageIndex);
      link = LinkEntity()
        ..vaultId = vaultId
        ..sourceNoteId = sourceNoteId
        ..sourcePageId = sourcePageId
        ..x0 = rect.x0
        ..y0 = rect.y0
        ..x1 = rect.x1
        ..y1 = rect.y1
        ..targetNoteId = newNote.id
        ..label = label
        ..dangling = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.linkEntitys.put(link);
      final edge = GraphEdge()
        ..vaultId = vaultId
        ..fromNoteId = sourceNoteId
        ..toNoteId = newNote.id
        ..createdAt = DateTime.now();
      edge.setUniqueKey(); // Set unique constraint key
      await isar.graphEdges.put(edge);
      await _pushRecentLinkedNote(isar: isar, noteId: newNote.id);
    });
    return link;
  }

  Future<void> _pushRecentLinkedNote({required Isar isar, required int noteId}) async {
    const String userId = 'local';
    final now = DateTime.now();
    // Get or create record
    final existing = await isar.recentTabs.where().anyId().findFirst();
    List<int> list;
    late RecentTabs tabs;
    if (existing == null) {
      list = <int>[noteId];
      tabs = RecentTabs()
        ..userId = userId
        ..noteIdsJson = jsonEncode(list)
        ..updatedAt = now;
    } else {
      tabs = existing;
      try {
        final decoded = jsonDecode(tabs.noteIdsJson);
        list = (decoded as List).map((e) => e as int).toList();
      } catch (_) {
        list = <int>[];
      }
      list.remove(noteId);
      list.insert(0, noteId);
      if (list.length > 10) {
        list = list.sublist(0, 10);
      }
      tabs
        ..noteIdsJson = jsonEncode(list)
        ..updatedAt = now;
    }
    await isar.recentTabs.put(tabs);
  }

  Future<void> moveNoteWithinVault({
    required int noteId,
    int? toFolderId,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final note = await isar.collection<NoteModel>().get(noteId);
      if (note == null) {
        return;
      }
      // NoteModel에는 folderId와 vaultId가 없으므로 임시로 처리
      // TODO(jidam): NoteModel에 vaultId와 folderId 필드 추가 필요
      final int? fromFolderId = null; // 임시
      int? targetVaultId = 1; // 임시, 기본 vault ID
      if (toFolderId != null) {
        final targetFolder = await isar.folders.get(toFolderId);
        if (targetFolder == null) {
          throw IsarError('Target folder not found');
        }
        targetVaultId = targetFolder.vaultId;
      }
      // NoteModel 업데이트
      note.updatedAt = DateTime.now();
      await isar.collection<NoteModel>().put(note);
      // Compact both source and destination folders
      await compactSortIndexWithinFolder(vaultId: targetVaultId ?? 1, folderId: fromFolderId);
      await compactSortIndexWithinFolder(vaultId: targetVaultId ?? 1, folderId: toFolderId);
    });
  }

  Future<Folder> createFolder({
    required int vaultId,
    required String name,
    int sortIndex = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    final folder = Folder()
      ..vaultId = vaultId
      ..name = name
      ..nameLowerForVaultUnique = name.toLowerCase()
      ..sortIndex = sortIndex
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.folders.put(folder);
    });
    return folder;
  }

  Future<Vault> createVault({
    required String name,
  }) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    final vault = Vault()
      ..name = name
      ..nameLowerUnique = name.toLowerCase()
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.vaults.put(vault);
    });
    return vault;
  }

  Future<void> renameVault({
    required int vaultId,
    required String newName,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final v = await isar.vaults.get(vaultId);
      if (v == null) {
        return;
      }
      v
        ..name = newName
        ..nameLowerUnique = newName.toLowerCase()
        ..updatedAt = DateTime.now();
      await isar.vaults.put(v);
    });
  }

  Future<Vault?> findVaultByLowerName(String lowerName) async {
    final isar = await IsarDb.instance.open();
    return isar.vaults.filter().nameLowerUniqueEqualTo(lowerName).findFirst();
  }

  Future<void> renameNote({
    required int noteId,
    required String newName,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final note = await isar.collection<NoteModel>().get(noteId);
      if (note == null) {
        return;
      }
      note
        ..title = newName
        ..updatedAt = DateTime.now();
      await isar.collection<NoteModel>().put(note);
    });
  }

  Future<void> renameFolder({
    required int folderId,
    required String newName,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final folder = await isar.folders.get(folderId);
      if (folder == null) {
        return;
      }
      folder
        ..name = newName
        ..nameLowerForVaultUnique = newName.toLowerCase()
        ..updatedAt = DateTime.now();
      await isar.folders.put(folder);
    });
  }

  Future<void> compactSortIndexWithinFolder({
    required int vaultId,
    int? folderId,
    int startAt = 1000,
    int step = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      // NoteModel에는 vaultId와 folderId가 없으므로 임시로 처리
      // TODO(jidam): NoteModel에 vaultId와 folderId 필드 추가 필요
      final notes = await isar.collection<NoteModel>()
          .filter()
          .deletedAtIsNull()
          .findAll();
      int current = startAt;
      for (final n in notes) {
        // NoteModel에는 sortIndex가 없으므로 건너뜀
        n.updatedAt = DateTime.now();
        current += step;
      }
      await isar.collection<NoteModel>().putAll(notes);
    });
  }

  Future<void> compactFolderSortIndex({
    required int vaultId,
    int startAt = 1000,
    int step = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final folders = await isar.folders
          .filter()
          .vaultIdEqualTo(vaultId)
          .and()
          .deletedAtIsNull()
          .sortBySortIndex()
          .findAll();
      int current = startAt;
      for (final f in folders) {
        if (f.sortIndex != current) {
          f.sortIndex = current;
          f.updatedAt = DateTime.now();
        }
        current += step;
      }
      await isar.folders.putAll(folders);
    });
  }

  Future<void> setFolderSortIndex({
    required int vaultId,
    required int folderId,
    required int newSortIndex,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final folder = await isar.folders.get(folderId);
      if (folder == null) {
        return;
      }
      if (folder.vaultId != vaultId) {
        throw IsarError('Cross-vault operation is not allowed');
      }
      folder.sortIndex = newSortIndex;
      folder.updatedAt = DateTime.now();
      await isar.folders.put(folder);
      await compactFolderSortIndex(vaultId: vaultId);
    });
  }

  Future<void> softDeleteFolder(int folderId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final folder = await isar.folders.get(folderId);
      if (folder == null) {
        return;
      }
      folder.deletedAt = now;
      folder.updatedAt = now;
      await isar.folders.put(folder);
      await compactFolderSortIndex(vaultId: folder.vaultId);
    });
  }

  Future<void> restoreFolder(int folderId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final folder = await isar.folders.get(folderId);
      if (folder == null) {
        return;
      }
      folder.deletedAt = null;
      folder.updatedAt = now;
      await isar.folders.put(folder);
      await compactFolderSortIndex(vaultId: folder.vaultId);
    });
  }

  Future<SettingsEntity> getSettings() async {
    final isar = await IsarDb.instance.open();
    final existing = await isar.settingsEntitys.where().anyId().findFirst();
    if (existing != null) {
      return existing;
    }
    final defaults = SettingsEntity()
      ..encryptionEnabled = false
      ..backupDailyAt = '02:00'
      ..backupRetentionDays = 7
      ..recycleRetentionDays = 30
      ..keychainAlias = null;
    await isar.writeTxn(() async {
      await isar.settingsEntitys.put(defaults);
    });
    return defaults;
  }

  Future<void> updateSettings({
    bool? encryptionEnabled,
    String? backupDailyAt,
    int? backupRetentionDays,
    int? recycleRetentionDays,
    String? keychainAlias,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final s = await getSettings();
      if (encryptionEnabled != null) {
        s.encryptionEnabled = encryptionEnabled;
      }
      if (backupDailyAt != null) {
        s.backupDailyAt = backupDailyAt;
      }
      if (backupRetentionDays != null) {
        s.backupRetentionDays = backupRetentionDays;
      }
      if (recycleRetentionDays != null) {
        s.recycleRetentionDays = recycleRetentionDays;
      }
      if (keychainAlias != null) {
        s.keychainAlias = keychainAlias;
      }
      await isar.settingsEntitys.put(s);
    });
  }

  /// 노트 검색 (SearchService 위임)
  Future<List<NoteModel>> searchNotesByName({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 50,
    bool useContains = false,
  }) async {
    if (useContains) {
      return SearchService.instance.fullTextSearchNotes(
        vaultId: vaultId,
        folderId: folderId,
        query: query,
        limit: limit,
      );
    } else {
      return SearchService.instance.quickSearchNotes(
        vaultId: vaultId,
        folderId: folderId,
        query: query,
        limit: limit,
      );
    }
  }

  /// Contains 부분 검색 전용 메서드 (SearchService 위임)
  Future<List<NoteModel>> searchNotesByNameContains({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 50,
  }) async {
    return SearchService.instance.fullTextSearchNotes(
      vaultId: vaultId,
      folderId: folderId,
      query: query,
      limit: limit,
    );
  }

  /// 전역 검색 (SearchService 위임)
  Future<List<NoteModel>> searchNotesGlobally({
    required String query,
    int limit = 100,
    bool useContains = true,
  }) async {
    return SearchService.instance.globalSearchNotes(
      query: query,
      useContains: useContains,
      limit: limit,
    );
  }

  /// 고급 검색 (SearchService 위임)
  Future<List<NoteModel>> searchNotesAdvanced({
    int? vaultId,
    int? folderId,
    required String query,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    bool useContains = true,
    int limit = 50,
  }) async {
    if (vaultId == null) {
      return SearchService.instance.globalSearchNotes(
        query: query,
        useContains: useContains,
        limit: limit,
      );
    }

    return SearchService.instance.searchNotesByDateRange(
      vaultId: vaultId,
      folderId: folderId,
      query: query.isEmpty ? null : query,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      updatedAfter: updatedAfter,
      updatedBefore: updatedBefore,
      useContains: useContains,
      limit: limit,
    );
  }

  Future<void> softDeleteNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final note = await isar.collection<NoteModel>().get(noteId);
      if (note == null) {
        return;
      }
      note.deletedAt = now;
      note.updatedAt = now;
      await isar.collection<NoteModel>().put(note);
      // mark dangling links
      final links = await isar.linkEntitys.filter().targetNoteIdEqualTo(noteId).findAll();
      for (final l in links) {
        l.dangling = true;
        l.updatedAt = now;
      }
      await isar.linkEntitys.putAll(links);
    });
  }

  Future<void> restoreNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final note = await isar.collection<NoteModel>().get(noteId);
      if (note == null) {
        return;
      }
      note.deletedAt = null;
      note.updatedAt = now;
      // NoteModel에는 folderId가 없으므로 건너뜀
      await isar.collection<NoteModel>().put(note);
      // clear dangling on related links
      final links = await isar.linkEntitys.filter().targetNoteIdEqualTo(noteId).findAll();
      for (final l in links) {
        l.dangling = false;
        l.updatedAt = now;
      }
      await isar.linkEntitys.putAll(links);
    });
  }

  /// 폴더 검색 (SearchService 위임)
  Future<List<Folder>> searchFoldersByName({
    required int vaultId,
    required String query,
    bool useContains = true,
    int limit = 50,
  }) async {
    return SearchService.instance.searchFolders(
      vaultId: vaultId,
      query: query,
      useContains: useContains,
      limit: limit,
    );
  }

  /// 볼트 검색 (SearchService 위임)
  Future<List<Vault>> searchVaultsByName({
    required String query,
    bool useContains = true,
    int limit = 20,
  }) async {
    return SearchService.instance.searchVaults(
      query: query,
      useContains: useContains,
      limit: limit,
    );
  }

  /// 통합 검색 (SearchService 위임)
  Future<Map<String, List<dynamic>>> searchAllEntities({
    int? vaultId,
    required String query,
    bool useContains = true,
    int limitPerType = 20,
  }) async {
    final searchResults = await SearchService.instance.searchAll(
      vaultId: vaultId,
      query: query,
      useContains: useContains,
      limitPerType: limitPerType,
    );

    return searchResults.toMap();
  }
}
