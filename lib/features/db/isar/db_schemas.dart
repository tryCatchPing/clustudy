import 'package:isar/isar.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// All Isar collection schemas used by the app.
///
/// Use this list when opening the database:
/// `await Isar.open(allSchemas, directory: path)`.
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


