import 'package:isar/isar.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

// Barrel exposing all collection schemas for Isar.open([...])
const List<CollectionSchema> allSchemas = [
  VaultSchema,
  FolderSchema,
  NoteSchema,
  PageSchema,
  CanvasDataSchema,
  PageSnapshotSchema,
  LinkEntitySchema,
  GraphEdgeSchema,
  PdfCacheMetaSchema,
  RecentTabsSchema,
  SettingsEntitySchema,
];


