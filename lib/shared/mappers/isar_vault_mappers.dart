import 'package:isar/isar.dart';

import '../../features/vaults/models/folder_model.dart';
import '../../features/vaults/models/note_placement.dart';
import '../../features/vaults/models/vault_model.dart';
import '../entities/note_placement_entity.dart';
import '../entities/vault_entity.dart';

/// Mapper extensions for Isar vault-related entities and domain models.
extension VaultEntityMapper on VaultEntity {
  /// Converts this [VaultEntity] into a [VaultModel].
  VaultModel toDomainModel() {
    return VaultModel(
      vaultId: vaultId,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper utilities for converting [VaultModel] instances into Isar entities.
extension VaultModelMapper on VaultModel {
  /// Creates a [VaultEntity] from this [VaultModel].
  ///
  /// When updating an existing entity, supply [existingId] so Isar can
  /// perform an upsert instead of an insert.
  VaultEntity toEntity({Id? existingId}) {
    final entity = VaultEntity()
      ..vaultId = vaultId
      ..name = name
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}

/// Mapper helpers for folder entities.
extension FolderEntityMapper on FolderEntity {
  /// Converts this [FolderEntity] into a [FolderModel].
  FolderModel toDomainModel() {
    return FolderModel(
      folderId: folderId,
      vaultId: vaultId,
      name: name,
      parentFolderId: parentFolderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper utilities for converting [FolderModel] instances into Isar entities.
extension FolderModelMapper on FolderModel {
  /// Creates a [FolderEntity] from this [FolderModel].
  FolderEntity toEntity({Id? existingId}) {
    final entity = FolderEntity()
      ..folderId = folderId
      ..vaultId = vaultId
      ..name = name
      ..parentFolderId = parentFolderId
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}

/// Mapper helpers for note placement entities.
extension NotePlacementEntityMapper on NotePlacementEntity {
  /// Converts this [NotePlacementEntity] into a domain [NotePlacement].
  NotePlacement toDomainModel() {
    return NotePlacement(
      noteId: noteId,
      vaultId: vaultId,
      parentFolderId: parentFolderId,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper utilities for converting [NotePlacement] instances into Isar
/// entities.
extension NotePlacementModelMapper on NotePlacement {
  /// Creates a [NotePlacementEntity] from this [NotePlacement].
  NotePlacementEntity toEntity({Id? existingId}) {
    final entity = NotePlacementEntity()
      ..noteId = noteId
      ..vaultId = vaultId
      ..parentFolderId = parentFolderId
      ..name = name
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}
