import 'dart:async';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/entities/note_entities.dart';
import '../../../shared/entities/note_placement_entity.dart';
import '../../../shared/entities/vault_entity.dart';
import '../../../shared/mappers/isar_vault_mappers.dart';
import '../../../shared/repositories/vault_tree_repository.dart';
import '../../../shared/services/isar_database_service.dart';
import '../../../shared/services/name_normalizer.dart';
import '../models/folder_model.dart';
import '../models/note_placement.dart';
import '../models/vault_item.dart';
import '../models/vault_model.dart';

/// Isar-backed implementation of [VaultTreeRepository].
class IsarVaultTreeRepository implements VaultTreeRepository {
  IsarVaultTreeRepository({Isar? isar}) : _providedIsar = isar;

  final Isar? _providedIsar;
  Isar? _isar;
  static const _uuid = Uuid();

  Future<Isar> _ensureIsar() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    final resolved = _providedIsar ?? await IsarDatabaseService.getInstance();
    await _ensureDefaultVault(resolved);
    _isar = resolved;
    return resolved;
  }

  @override
  Stream<List<VaultModel>> watchVaults() {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();
      final subscription = isar.vaultEntitys
          .where()
          .anyName()
          .watch(fireImmediately: true)
          .listen(
            (entities) {
              final models =
                  entities.map((e) => e.toDomainModel()).toList(growable: false)
                    ..sort(
                      (a, b) => NameNormalizer.compareKey(
                        a.name,
                      ).compareTo(NameNormalizer.compareKey(b.name)),
                    );
              controller.add(models);
            },
            onError: controller.addError,
          );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<VaultModel?> getVault(String vaultId) async {
    final isar = await _ensureIsar();
    final entity = await isar.vaultEntitys.getByVaultId(vaultId);
    return entity?.toDomainModel();
  }

  @override
  Future<FolderModel?> getFolder(String folderId) async {
    final isar = await _ensureIsar();
    final entity = await isar.folderEntitys.getByFolderId(folderId);
    return entity?.toDomainModel();
  }

  @override
  Future<VaultModel> createVault(String name) async {
    final normalized = NameNormalizer.normalize(name);
    final now = DateTime.now();
    final isar = await _ensureIsar();
    late VaultModel created;
    await isar.writeTxn(() async {
      await _ensureUniqueVaultName(isar, normalized);
      final entity = VaultEntity()
        ..vaultId = _uuid.v4()
        ..name = normalized
        ..createdAt = now
        ..updatedAt = now;
      final id = await isar.vaultEntitys.put(entity);
      entity.id = id;
      created = entity.toDomainModel();
    });
    return created;
  }

  @override
  Future<void> renameVault(String vaultId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final entity = await _requireVault(isar, vaultId);
      await _ensureUniqueVaultName(isar, normalized, excludeVaultId: vaultId);
      entity
        ..name = normalized
        ..updatedAt = DateTime.now();
      await isar.vaultEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteVault(String vaultId) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final entity = await isar.vaultEntitys.getByVaultId(vaultId);
      if (entity == null) {
        return;
      }
      await isar.folderEntitys.filter().vaultIdEqualTo(vaultId).deleteAll();
      await isar.notePlacementEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .deleteAll();
      await isar.vaultEntitys.deleteByVaultId(vaultId);
    });
  }

  @override
  Stream<List<VaultItem>> watchFolderChildren(
    String vaultId, {
    String? parentFolderId,
  }) {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();

      late final StreamSubscription<List<FolderEntity>> folderSub;
      late final StreamSubscription<List<NotePlacementEntity>> placementSub;

      var latestFolders = <FolderEntity>[];
      var latestPlacements = <NotePlacementEntity>[];
      var foldersReady = false;
      var placementsReady = false;

      void emitIfReady() {
        if (!foldersReady || !placementsReady) {
          return;
        }

        final combined = _mergeChildren(
          vaultId,
          latestFolders,
          latestPlacements,
        );
        controller.add(combined);
      }

      folderSub = _folderQuery(isar, vaultId, parentFolderId)
          .watch(fireImmediately: true)
          .listen(
            (event) {
              foldersReady = true;
              latestFolders = event;
              emitIfReady();
            },
            onError: controller.addError,
          );

      placementSub = _placementQuery(isar, vaultId, parentFolderId)
          .watch(fireImmediately: true)
          .listen(
            (event) {
              placementsReady = true;
              latestPlacements = event;
              emitIfReady();
            },
            onError: controller.addError,
          );

      controller.onCancel = () async {
        await folderSub.cancel();
        await placementSub.cancel();
      };
    });
  }

  @override
  Future<FolderModel> createFolder(
    String vaultId, {
    String? parentFolderId,
    required String name,
  }) async {
    final normalized = NameNormalizer.normalize(name);
    final now = DateTime.now();
    final isar = await _ensureIsar();
    late FolderModel created;
    await isar.writeTxn(() async {
      final vault = await _requireVault(isar, vaultId);
      FolderEntity? parent;
      if (parentFolderId != null) {
        parent = await _requireFolder(isar, parentFolderId);
        if (parent.vaultId != vaultId) {
          throw Exception('Folder belongs to a different vault');
        }
      }

      await _ensureUniqueFolderName(
        isar,
        vaultId,
        parentFolderId,
        normalized,
      );

      final entity = FolderEntity()
        ..folderId = _uuid.v4()
        ..vaultId = vaultId
        ..name = normalized
        ..parentFolderId = parentFolderId
        ..createdAt = now
        ..updatedAt = now;

      final id = await isar.folderEntitys.put(entity);
      entity.id = id;
      await entity.vault.load();
      entity.vault.value = vault;
      await entity.vault.save();
      if (parent != null) {
        await entity.parentFolder.load();
        entity.parentFolder.value = parent;
        await entity.parentFolder.save();
      }
      created = entity.toDomainModel();
    });
    return created;
  }

  @override
  Future<void> renameFolder(String folderId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final entity = await _requireFolder(isar, folderId);
      await _ensureUniqueFolderName(
        isar,
        entity.vaultId,
        entity.parentFolderId,
        normalized,
        excludeFolderId: folderId,
      );
      entity
        ..name = normalized
        ..updatedAt = DateTime.now();
      await isar.folderEntitys.put(entity);
    });
  }

  @override
  Future<void> moveFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final folder = await _requireFolder(isar, folderId);
      final currentParent = folder.parentFolderId;
      if (currentParent == newParentFolderId) {
        return;
      }
      if (newParentFolderId != null) {
        if (newParentFolderId == folderId) {
          throw Exception('Folder cannot be its own parent');
        }
        FolderEntity? current = await _requireFolder(isar, newParentFolderId);
        if (current.vaultId != folder.vaultId) {
          throw Exception('Target folder belongs to a different vault');
        }
        // Prevent moving into its own descendant
        while (current != null) {
          if (current.folderId == folderId) {
            throw Exception('Cannot move folder into its descendant');
          }
          final parentId = current.parentFolderId;
          current = parentId != null
              ? await isar.folderEntitys.getByFolderId(parentId)
              : null;
        }
      }

      await _ensureUniqueFolderName(
        isar,
        folder.vaultId,
        newParentFolderId,
        folder.name,
        excludeFolderId: folder.folderId,
      );

      folder
        ..parentFolderId = newParentFolderId
        ..updatedAt = DateTime.now();
      await isar.folderEntitys.put(folder);
      await _updateFolderParentLink(isar, folder, newParentFolderId);
    });
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final folder = await isar.folderEntitys.getByFolderId(folderId);
      if (folder == null) {
        return;
      }
      final vaultId = folder.vaultId;
      final allFolders = await isar.folderEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .findAll();
      final toDelete = <String>{folder.folderId};
      final queue = <String>[folder.folderId];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        for (final child in allFolders) {
          if (child.parentFolderId == current) {
            if (toDelete.add(child.folderId)) {
              queue.add(child.folderId);
            }
          }
        }
      }

      final placements = await isar.notePlacementEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .findAll();
      final placementIds = placements
          .where((p) => toDelete.contains(p.parentFolderId))
          .map((p) => p.noteId)
          .toList();

      await isar.folderEntitys.deleteAllByFolderId(toDelete.toList());
      if (placementIds.isNotEmpty) {
        await isar.notePlacementEntitys.deleteAllByNoteId(placementIds);
      }
    });
  }

  @override
  Future<List<FolderModel>> getFolderAncestors(String folderId) async {
    final isar = await _ensureIsar();
    final ancestors = <FolderModel>[];
    var current = await isar.folderEntitys.getByFolderId(folderId);
    while (current != null) {
      ancestors.add(current.toDomainModel());
      final parentId = current.parentFolderId;
      current = parentId != null
          ? await isar.folderEntitys.getByFolderId(parentId)
          : null;
    }
    return ancestors.reversed.toList(growable: false);
  }

  @override
  Future<List<FolderModel>> getFolderDescendants(String folderId) async {
    final isar = await _ensureIsar();
    final descendants = <FolderModel>[];
    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final children = await isar.folderEntitys
          .filter()
          .parentFolderIdEqualTo(currentId)
          .findAll();
      for (final child in children) {
        descendants.add(child.toDomainModel());
        queue.add(child.folderId);
      }
    }
    return List<FolderModel>.unmodifiable(descendants);
  }

  @override
  Future<String> createNote(
    String vaultId, {
    String? parentFolderId,
    required String name,
  }) async {
    final normalized = NameNormalizer.normalize(name);
    final isar = await _ensureIsar();
    final noteId = _uuid.v4();
    await isar.writeTxn(() async {
      await _ensurePlacementPreconditions(
        isar,
        vaultId,
        parentFolderId,
        normalized,
      );
      final placement = NotePlacementEntity()
        ..noteId = noteId
        ..vaultId = vaultId
        ..parentFolderId = parentFolderId
        ..name = normalized
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      final id = await isar.notePlacementEntitys.put(placement);
      placement.id = id;
      await _linkPlacement(isar, placement, vaultId, parentFolderId);
    });
    return noteId;
  }

  @override
  Future<void> renameNote(String noteId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final placement = await _requirePlacement(isar, noteId);
      await _ensureUniqueNoteName(
        isar,
        placement.vaultId,
        placement.parentFolderId,
        normalized,
        excludeNoteId: noteId,
      );
      placement
        ..name = normalized
        ..updatedAt = DateTime.now();
      await isar.notePlacementEntitys.put(placement);
    });
  }

  @override
  Future<void> moveNote({
    required String noteId,
    String? newParentFolderId,
  }) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final placement = await _requirePlacement(isar, noteId);
      if (placement.parentFolderId == newParentFolderId) {
        return;
      }
      if (newParentFolderId != null) {
        final parent = await _requireFolder(isar, newParentFolderId);
        if (parent.vaultId != placement.vaultId) {
          throw Exception('Target folder belongs to a different vault');
        }
      }
      await _ensureUniqueNoteName(
        isar,
        placement.vaultId,
        newParentFolderId,
        placement.name,
        excludeNoteId: noteId,
      );
      placement
        ..parentFolderId = newParentFolderId
        ..updatedAt = DateTime.now();
      await isar.notePlacementEntitys.put(placement);
      await _linkPlacement(
        isar,
        placement,
        placement.vaultId,
        newParentFolderId,
      );
    });
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      await isar.notePlacementEntitys.deleteByNoteId(noteId);
    });
  }

  @override
  Future<NotePlacement?> getNotePlacement(String noteId) async {
    final isar = await _ensureIsar();
    final entity = await isar.notePlacementEntitys.getByNoteId(noteId);
    return entity?.toDomainModel();
  }

  @override
  Future<void> registerExistingNote({
    required String noteId,
    required String vaultId,
    String? parentFolderId,
    required String name,
  }) async {
    final normalized = NameNormalizer.normalize(name);
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      if (await isar.notePlacementEntitys.getByNoteId(noteId) != null) {
        throw Exception('Note already exists: $noteId');
      }
      await _ensurePlacementPreconditions(
        isar,
        vaultId,
        parentFolderId,
        normalized,
      );
      final placement = NotePlacementEntity()
        ..noteId = noteId
        ..vaultId = vaultId
        ..parentFolderId = parentFolderId
        ..name = normalized
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      final id = await isar.notePlacementEntitys.put(placement);
      placement.id = id;
      await _linkPlacement(isar, placement, vaultId, parentFolderId);
    });
  }

  @override
  Future<List<NotePlacement>> searchNotes(
    String vaultId,
    String query, {
    bool exact = false,
    int limit = 50,
    Set<String>? excludeNoteIds,
  }) async {
    final isar = await _ensureIsar();
    final trimmed = query.trim();
    final normalizedQuery = NameNormalizer.compareKey(trimmed);
    final excludes = excludeNoteIds ?? const <String>{};

    List<NotePlacementEntity> entities;
    if (normalizedQuery.isEmpty) {
      entities = await isar.notePlacementEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .findAll();
    } else if (exact) {
      entities = await isar.notePlacementEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .nameEqualTo(trimmed, caseSensitive: false)
          .findAll();
    } else {
      entities = await isar.notePlacementEntitys
          .filter()
          .vaultIdEqualTo(vaultId)
          .nameContains(trimmed, caseSensitive: false)
          .findAll();
    }

    final scored = <_ScoredPlacement>[];
    for (final entity in entities) {
      if (excludes.contains(entity.noteId)) {
        continue;
      }
      final placement = entity.toDomainModel();
      final key = NameNormalizer.compareKey(placement.name);
      int score;
      if (normalizedQuery.isEmpty) {
        score = 0;
      } else if (exact) {
        score = key == normalizedQuery ? 3 : 0;
        if (score == 0) {
          continue;
        }
      } else {
        if (key == normalizedQuery) {
          score = 3;
        } else if (key.startsWith(normalizedQuery)) {
          score = 2;
        } else if (key.contains(normalizedQuery)) {
          score = 1;
        } else {
          continue;
        }
      }
      scored.add(_ScoredPlacement(score: score, placement: placement));
    }

    if (normalizedQuery.isEmpty) {
      scored.sort(
        (a, b) => NameNormalizer.compareKey(
          a.placement.name,
        ).compareTo(NameNormalizer.compareKey(b.placement.name)),
      );
    } else {
      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return NameNormalizer.compareKey(
          a.placement.name,
        ).compareTo(NameNormalizer.compareKey(b.placement.name));
      });
    }

    final iterable = limit > 0 ? scored.take(limit) : scored;
    return iterable.map((e) => e.placement).toList(growable: false);
  }

  @override
  void dispose() {}

  Future<void> _ensureDefaultVault(Isar isar) async {
    final existing = await isar.vaultEntitys.getByVaultId('default');
    if (existing != null) {
      return;
    }

    await isar.writeTxn(() async {
      final insideTxnExisting = await isar.vaultEntitys.getByVaultId('default');
      if (insideTxnExisting != null) {
        return;
      }

      final now = DateTime.now();
      final entity = VaultEntity()
        ..vaultId = 'default'
        ..name = 'Default Vault'
        ..createdAt = now
        ..updatedAt = now;
      final id = await isar.vaultEntitys.put(entity);
      entity.id = id;
    });
  }

  QueryBuilder<FolderEntity, FolderEntity, QAfterFilterCondition> _folderQuery(
    Isar isar,
    String vaultId,
    String? parentFolderId,
  ) {
    final base = isar.folderEntitys.filter().vaultIdEqualTo(vaultId);
    return parentFolderId == null
        ? base.parentFolderIdIsNull()
        : base.parentFolderIdEqualTo(parentFolderId);
  }

  QueryBuilder<NotePlacementEntity, NotePlacementEntity, QAfterFilterCondition>
  _placementQuery(
    Isar isar,
    String vaultId,
    String? parentFolderId,
  ) {
    final base = isar.notePlacementEntitys.filter().vaultIdEqualTo(vaultId);
    return parentFolderId == null
        ? base.parentFolderIdIsNull()
        : base.parentFolderIdEqualTo(parentFolderId);
  }

  List<VaultItem> _mergeChildren(
    String vaultId,
    List<FolderEntity> folders,
    List<NotePlacementEntity> placements,
  ) {
    final items = <VaultItem>[];

    for (final folder in folders) {
      items.add(
        VaultItem(
          type: VaultItemType.folder,
          vaultId: vaultId,
          id: folder.folderId,
          name: folder.name,
          createdAt: folder.createdAt,
          updatedAt: folder.updatedAt,
        ),
      );
    }

    for (final placement in placements) {
      items.add(
        VaultItem(
          type: VaultItemType.note,
          vaultId: vaultId,
          id: placement.noteId,
          name: placement.name,
          createdAt: placement.createdAt,
          updatedAt: placement.updatedAt,
        ),
      );
    }

    items.sort((a, b) {
      final typeA = a.type == VaultItemType.folder ? 0 : 1;
      final typeB = b.type == VaultItemType.folder ? 0 : 1;
      if (typeA != typeB) {
        return typeA - typeB;
      }
      return NameNormalizer.compareKey(
        a.name,
      ).compareTo(NameNormalizer.compareKey(b.name));
    });

    return List<VaultItem>.unmodifiable(items);
  }

  Future<VaultEntity> _requireVault(Isar isar, String vaultId) async {
    final entity = await isar.vaultEntitys.getByVaultId(vaultId);
    if (entity == null) {
      throw Exception('Vault not found: $vaultId');
    }
    return entity;
  }

  Future<FolderEntity> _requireFolder(Isar isar, String folderId) async {
    final entity = await isar.folderEntitys.getByFolderId(folderId);
    if (entity == null) {
      throw Exception('Folder not found: $folderId');
    }
    return entity;
  }

  Future<NotePlacementEntity> _requirePlacement(
    Isar isar,
    String noteId,
  ) async {
    final entity = await isar.notePlacementEntitys.getByNoteId(noteId);
    if (entity == null) {
      throw Exception('Note not found: $noteId');
    }
    return entity;
  }

  Future<void> _ensureUniqueVaultName(
    Isar isar,
    String normalized, {
    String? excludeVaultId,
  }) async {
    final existing = await isar.vaultEntitys
        .filter()
        .nameEqualTo(normalized, caseSensitive: false)
        .findFirst();
    if (existing != null && existing.vaultId != excludeVaultId) {
      throw Exception('Vault name already exists');
    }
  }

  Future<void> _ensureUniqueFolderName(
    Isar isar,
    String vaultId,
    String? parentFolderId,
    String normalized, {
    String? excludeFolderId,
  }) async {
    final query = isar.folderEntitys.filter().vaultIdEqualTo(vaultId);
    final existing = parentFolderId == null
        ? await query
              .parentFolderIdIsNull()
              .nameEqualTo(
                normalized,
                caseSensitive: false,
              )
              .findFirst()
        : await query
              .parentFolderIdEqualTo(parentFolderId)
              .nameEqualTo(
                normalized,
                caseSensitive: false,
              )
              .findFirst();
    if (existing != null && existing.folderId != excludeFolderId) {
      throw Exception('Folder name already exists in this location');
    }
  }

  Future<void> _ensureUniqueNoteName(
    Isar isar,
    String vaultId,
    String? parentFolderId,
    String normalized, {
    String? excludeNoteId,
  }) async {
    final query = isar.notePlacementEntitys.filter().vaultIdEqualTo(vaultId);
    final existing = parentFolderId == null
        ? await query
              .parentFolderIdIsNull()
              .nameEqualTo(
                normalized,
                caseSensitive: false,
              )
              .findFirst()
        : await query
              .parentFolderIdEqualTo(parentFolderId)
              .nameEqualTo(
                normalized,
                caseSensitive: false,
              )
              .findFirst();
    if (existing != null && existing.noteId != excludeNoteId) {
      throw Exception('Note name already exists in this location');
    }
  }

  Future<void> _ensurePlacementPreconditions(
    Isar isar,
    String vaultId,
    String? parentFolderId,
    String normalizedName,
  ) async {
    await _ensureUniqueNoteName(isar, vaultId, parentFolderId, normalizedName);
    await _requireVault(isar, vaultId);
    if (parentFolderId != null) {
      final folder = await _requireFolder(isar, parentFolderId);
      if (folder.vaultId != vaultId) {
        throw Exception('Folder belongs to a different vault');
      }
    }
  }

  Future<void> _linkPlacement(
    Isar isar,
    NotePlacementEntity placement,
    String vaultId,
    String? parentFolderId,
  ) async {
    final vault = await isar.vaultEntitys.getByVaultId(vaultId);
    if (vault != null) {
      await placement.vault.load();
      placement.vault.value = vault;
      await placement.vault.save();
    }
    await placement.parentFolder.load();
    if (parentFolderId != null) {
      final folder = await isar.folderEntitys.getByFolderId(parentFolderId);
      if (folder == null) {
        throw Exception('Parent folder not found: $parentFolderId');
      }
      placement.parentFolder.value = folder;
    } else {
      placement.parentFolder.value = null;
    }
    await placement.parentFolder.save();
    final noteEntity = await isar.noteEntitys.getByNoteId(placement.noteId);
    if (noteEntity != null) {
      await placement.note.load();
      placement.note.value = noteEntity;
      await placement.note.save();
    }
  }

  Future<void> _updateFolderParentLink(
    Isar isar,
    FolderEntity folder,
    String? newParentFolderId,
  ) async {
    await folder.parentFolder.load();
    if (newParentFolderId == null) {
      folder.parentFolder.value = null;
      await folder.parentFolder.save();
      return;
    }
    final parent = await isar.folderEntitys.getByFolderId(newParentFolderId);
    if (parent == null) {
      throw Exception('Parent folder not found: $newParentFolderId');
    }
    folder.parentFolder.value = parent;
    await folder.parentFolder.save();
  }
}

class _ScoredPlacement {
  final int score;
  final NotePlacement placement;

  const _ScoredPlacement({required this.score, required this.placement});
}
