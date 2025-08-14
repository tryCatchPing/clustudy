import 'package:isar/isar.dart';

part 'vault_models.g.dart';

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
  @Index(composite: [CompositeIndex('vaultId'), CompositeIndex('folderId')], unique: true, caseSensitive: false)
  late String nameLowerForParentUnique;
}

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

@collection
class LinkEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int vaultId;

  late int sourceNoteId;
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
}

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
}

@collection
class RecentTabs {
  Id id = Isar.autoIncrement;

  late String userId; // 'local'

  // Store as CSV or JSON array string for simplicity
  late String noteIdsJson;

  @Index()
  late DateTime updatedAt;
}

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


