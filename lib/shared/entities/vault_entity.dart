import 'package:isar/isar.dart';

import 'note_placement_entity.dart';

part 'vault_entity.g.dart';

/// Isar collection for Vaults.
///
/// - Unique `vaultId` mirrors domain VaultModel.vaultId
/// - Stores basic metadata and maintains relationship to folders
@collection
class VaultEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID v4 recommended), unique across all vaults
  @Index(unique: true, replace: false)
  late String vaultId;

  /// Display name
  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  /// Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  // Child folders in this vault (populated via FolderEntity.vault link)
  final folders = IsarLinks<FolderEntity>();

  /// Backlink to all note placements that belong to this vault.
  @Backlink(to: 'vault')
  final notePlacements = IsarLinks<NotePlacementEntity>();
}

/// Isar collection for Folders with hierarchical relationships.
@collection
class FolderEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID v4 recommended), unique across all folders
  @Index(unique: true, replace: false)
  late String folderId;

  /// Vault scope this folder belongs to
  /// Composite index with parentFolderId optimizes children lookups per vault
  @Index(composite: [CompositeIndex('parentFolderId')])
  late String vaultId;

  /// Display name, used in scoped uniqueness checks at repository level
  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  /// Parent folder id (null for root)
  String? parentFolderId;

  /// Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  /// Backlink to the parent vault
  final vault = IsarLink<VaultEntity>();

  /// Self-referencing parent folder
  final parentFolder = IsarLink<FolderEntity>();

  /// Child folders
  final childFolders = IsarLinks<FolderEntity>();

  /// Backlink to placements scoped under this folder.
  @Backlink(to: 'parentFolder')
  final notePlacements = IsarLinks<NotePlacementEntity>();
}
