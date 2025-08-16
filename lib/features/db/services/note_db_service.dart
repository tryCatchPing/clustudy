import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import '../../../shared/models/rect_norm.dart';

import '../isar_db.dart';
import '../models/vault_models.dart';

class NoteDbService {
  NoteDbService._();
  static final NoteDbService instance = NoteDbService._();

  Future<Note> createNote({
    required int vaultId,
    int? folderId,
    required String name,
    required String pageSize,
    required String pageOrientation,
    int sortIndex = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    final note = Note()
      ..vaultId = vaultId
      ..folderId = folderId
      ..name = name
      ..nameLowerForParentUnique = name.toLowerCase()
      ..pageSize = pageSize
      ..pageOrientation = pageOrientation
      ..sortIndex = sortIndex
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..vaultIdForSort = vaultId  // Set composite index field
      ..nameLowerForSearch = name.toLowerCase();  // Set search optimization field
    await isar.writeTxn(() async {
      await isar.notes.put(note);
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
    late final Note newNote;
    late final LinkEntity link;
    await isar.writeTxn(() async {
      // Create note directly in transaction to set all fields
      newNote = Note()
        ..vaultId = vaultId
        ..name = label
        ..nameLowerForParentUnique = label.toLowerCase()
        ..pageSize = pageSize
        ..pageOrientation = pageOrientation
        ..sortIndex = 1000
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..vaultIdForSort = vaultId
        ..nameLowerForSearch = label.toLowerCase();
      await isar.notes.put(newNote);
      await createPage(noteId: newNote.id, index: initialPageIndex);
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
    final existing = await isar.recentTabs.where().findFirst();
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
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      final int? fromFolderId = note.folderId;
      int? targetVaultId;
      if (toFolderId != null) {
        final targetFolder = await isar.folders.get(toFolderId);
        if (targetFolder == null) {
          throw IsarError('Target folder not found');
        }
        targetVaultId = targetFolder.vaultId;
      } else {
        targetVaultId = note.vaultId; // root of same vault
      }
      if (targetVaultId != note.vaultId) {
        throw IsarError('Cross-vault move is not allowed');
      }
      note.folderId = toFolderId;
      note.sortIndex = 1 << 30; // large number to append at end
      note.updatedAt = DateTime.now();
      await isar.notes.put(note);
      // Compact both source and destination folders
      await compactSortIndexWithinFolder(vaultId: note.vaultId, folderId: fromFolderId);
      await compactSortIndexWithinFolder(vaultId: note.vaultId, folderId: toFolderId);
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
      if (v == null) return;
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
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      note
        ..name = newName
        ..nameLowerForParentUnique = newName.toLowerCase()
        ..nameLowerForSearch = newName.toLowerCase()  // Update search field
        ..updatedAt = DateTime.now();
      await isar.notes.put(note);
    });
  }

  Future<void> renameFolder({
    required int folderId,
    required String newName,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final folder = await isar.folders.get(folderId);
      if (folder == null) return;
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
      final notes = await isar.notes
          .filter()
          .vaultIdEqualTo(vaultId)
          .and()
          .folderIdEqualTo(folderId)
          .and()
          .deletedAtIsNull()
          .sortBySortIndex()
          .findAll();
      int current = startAt;
      for (final n in notes) {
        if (n.sortIndex != current) {
          n.sortIndex = current;
          n.updatedAt = DateTime.now();
        }
        // Ensure vaultIdForSort is consistent
        if (n.vaultIdForSort != n.vaultId) {
          n.vaultIdForSort = n.vaultId;
        }
        current += step;
      }
      await isar.notes.putAll(notes);
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
      if (folder == null) return;
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
      if (folder == null) return;
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
      if (folder == null) return;
      folder.deletedAt = null;
      folder.updatedAt = now;
      await isar.folders.put(folder);
      await compactFolderSortIndex(vaultId: folder.vaultId);
    });
  }

  Future<SettingsEntity> getSettings() async {
    final isar = await IsarDb.instance.open();
    final existing = await isar.settingsEntitys.where().findFirst();
    if (existing != null) return existing;
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
      if (encryptionEnabled != null) s.encryptionEnabled = encryptionEnabled;
      if (backupDailyAt != null) s.backupDailyAt = backupDailyAt;
      if (backupRetentionDays != null) s.backupRetentionDays = backupRetentionDays;
      if (recycleRetentionDays != null) s.recycleRetentionDays = recycleRetentionDays;
      if (keychainAlias != null) s.keychainAlias = keychainAlias;
      await isar.settingsEntitys.put(s);
    });
  }

  Future<List<Note>> searchNotesByName({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 50,
  }) async {
    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase();
    var builder = isar.notes
        .filter()
        .vaultIdEqualTo(vaultId)
        .and()
        .deletedAtIsNull();
    if (folderId == null) {
      builder = builder.and().folderIdIsNull();
    } else {
      builder = builder.and().folderIdEqualTo(folderId);
    }
    final results = await builder
        .and()
        .nameLowerForParentUniqueStartsWith(q)
        .limit(limit)
        .findAll();
    return results;
  }

  Future<void> softDeleteNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      note.deletedAt = now;
      note.updatedAt = now;
      await isar.notes.put(note);
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
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      note.deletedAt = null;
      note.updatedAt = now;
      // If original folder is missing or deleted, restore to root
      if (note.folderId != null) {
        final folder = await isar.folders.get(note.folderId!);
        if (folder == null || folder.deletedAt != null) {
          note.folderId = null;
        }
      }
      await isar.notes.put(note);
      // clear dangling on related links
      final links = await isar.linkEntitys.filter().targetNoteIdEqualTo(noteId).findAll();
      for (final l in links) {
        l.dangling = false;
        l.updatedAt = now;
      }
      await isar.linkEntitys.putAll(links);
    });
  }
}


