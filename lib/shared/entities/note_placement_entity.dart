import 'package:isar/isar.dart';

import 'note_entities.dart';
import 'vault_entity.dart';

part 'note_placement_entity.g.dart';

/// Isar collection for note placement within a vault tree.
@collection
class NotePlacementEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID) – equals domain NotePlacement.noteId
  @Index(unique: true, replace: false)
  late String noteId;

  /// Vault scope – composite with parentFolderId for hierarchical queries
  @Index(composite: [CompositeIndex('parentFolderId')])
  late String vaultId;

  /// Parent folder id; null for root
  String? parentFolderId;

  /// Display name – indexed for search
  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  /// Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  final vault = IsarLink<VaultEntity>();
  final parentFolder = IsarLink<FolderEntity>();
  final note = IsarLink<NoteEntity>();
}

