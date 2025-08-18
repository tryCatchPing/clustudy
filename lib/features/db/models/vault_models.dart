import 'package:isar/isar.dart';

part 'vault_models.g.dart';

/// Logical data container. Top-level namespace that owns folders and notes.
@collection
class Vault {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String name;

  // lower-normalized unique key for A↔B contract (B queries against lower field)
  @Index(unique: true, caseSensitive: false)
  late String nameLowerUnique;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  @Index()
  DateTime? deletedAt;
}

/// Folder under a `Vault`. Organizes notes and preserves a local order.
@collection
class Folder {
  Id id = Isar.autoIncrement;

  late int vaultId;

  @Index(caseSensitive: false)
  late String name;

  @Index()
  late int sortIndex;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  @Index()
  DateTime? deletedAt;

  // Unique within vault: (vaultId, lower(name))
  @Index(composite: [CompositeIndex('vaultId')], unique: true, caseSensitive: false)
  late String nameLowerForVaultUnique;
}

/// A note composed of pages and associated canvas data.
@collection
class Note {
  Id id = Isar.autoIncrement;

  late int vaultId;
  int? folderId;

  @Index(caseSensitive: false)
  late String name;

  @Index()
  late int sortIndex;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  @Index()
  DateTime? deletedAt;

  // Page settings
  late String pageSize; // e.g., A4, Letter
  late String pageOrientation; // portrait, landscape

  // Unique within (vaultId, folderId): lower(name)
  @Index(
    composite: [CompositeIndex('vaultId'), CompositeIndex('folderId')],
    unique: true,
    caseSensitive: false,
  )
  late String nameLowerForParentUnique;

  // Performance optimization: composite index for folder listing queries (vaultId, folderId, sortIndex)
  @Index(composite: [CompositeIndex('folderId'), CompositeIndex('sortIndex')])
  late int vaultIdForSort;

  // Performance optimization: composite index for name search with deletion status
  @Index(composite: [CompositeIndex('deletedAt')], caseSensitive: false)
  late String nameLowerForSearch;
}

/// A single page belonging to a `Note` with dimensions and rotation.
@collection
class Page {
  Id id = Isar.autoIncrement;

  late int noteId;

  @Index()
  late int index; // order within note

  late int widthPx;
  late int heightPx;
  late int rotationDeg;

  String? pdfOriginalPath;
  int? pdfPageIndex;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  @Index()
  DateTime? deletedAt;
}

/// Serialized canvas content per page.
@collection
class CanvasData {
  Id id = Isar.autoIncrement;

  @Index()
  late int noteId;

  @Index(unique: true)
  late int pageId;

  late String schemaVersion; // semver
  late String json; // canvas JSON

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}

/// Historical snapshot of page canvas content for recovery/undo.
@collection
class PageSnapshot {
  Id id = Isar.autoIncrement;

  // Composite index for retention/query: (pageId, createdAt)
  @Index(composite: [CompositeIndex('createdAt')])
  late int pageId;

  late String schemaVersion;
  late String json;

  late DateTime createdAt;
}

/// Link drawn on a page that can point to another note.
@collection
class LinkEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int vaultId;

  // Link lookup optimization: index for source queries
  @Index()
  late int sourceNoteId;

  @Index()
  late int sourcePageId;

  // normalized rect [0..1]
  late double x0;
  late double y0;
  late double x1;
  late double y1;

  int? targetNoteId; // created note id

  String? label;

  @Index()
  late bool dangling;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}

/// Graph edge between notes within a vault.
@collection
class GraphEdge {
  Id id = Isar.autoIncrement;

  @Index()
  late int vaultId;

  @Index()
  late int fromNoteId;

  @Index()
  late int toNoteId;

  @Index()
  late DateTime createdAt;

  // Unique constraint to prevent duplicate edges: (vaultId, fromNoteId, toNoteId)
  @Index(
    composite: [
      CompositeIndex('vaultId'),
      CompositeIndex('fromNoteId'),
      CompositeIndex('toNoteId'),
    ],
    unique: true,
  )
  // ignore: unused_field
  late String _uniqueEdgeKey;

  // Helper to set the unique key based on vaultId, fromNoteId, toNoteId
  void setUniqueKey() {
    _uniqueEdgeKey = '${vaultId}_${fromNoteId}_$toNoteId';
  }
}

/// Metadata about cached PDF renders for faster thumbnails/previews.
@collection
class PdfCacheMeta {
  Id id = Isar.autoIncrement;

  @Index()
  late int noteId;

  @Index()
  late int pageIndex;

  late String cachePath;
  late int dpi;
  late DateTime renderedAt;
  int? sizeBytes;
  @Index()
  DateTime? lastAccessAt;

  // Unique constraint to prevent duplicate cache entries: (noteId, pageIndex)
  @Index(composite: [CompositeIndex('noteId'), CompositeIndex('pageIndex')], unique: true)
  // ignore: unused_field
  late String _uniqueCacheKey;

  // Helper to set the unique key based on noteId, pageIndex
  void setUniqueKey() {
    _uniqueCacheKey = '${noteId}_$pageIndex';
  }
}

/// Recently opened tabs state.
@collection
class RecentTabs {
  Id id = Isar.autoIncrement;

  // Unique constraint to ensure single record per user
  @Index(unique: true)
  late String userId; // 'local'

  // Store as CSV or JSON array string for simplicity
  late String noteIdsJson;

  @Index()
  late DateTime updatedAt;
}

/// Application settings and data schema versioning.
@collection
class SettingsEntity {
  Id id = Isar.autoIncrement;

  late bool encryptionEnabled;
  late String backupDailyAt; // e.g., '02:00'
  late int backupRetentionDays;
  late int recycleRetentionDays;
  String? keychainAlias;
  @Index()
  DateTime? lastBackupAt;
  // Data schema/migration versioning (nullable for backward-compat)
  int? dataVersion;
  // Policy flags
  bool? backupRequireWifi; // default false
  bool? backupOnlyWhenCharging; // default false (placeholder without battery plugin)
  int? pdfCacheMaxMB; // default 512MB
}
