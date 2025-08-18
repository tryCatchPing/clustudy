import 'package:isar/isar.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// 앱에서 사용하는 모든 Isar 컬렉션 스키마 목록입니다.
///
/// 데이터베이스를 열 때 이 목록을 전달하세요:
/// `await Isar.open(allSchemas, directory: path)`.
///
/// 포함된 컬렉션 타입:
/// - `Vault`
/// - `Folder`
/// - `Note`
/// - `Page`
/// - `CanvasData`
/// - `PageSnapshot`
/// - `LinkEntity`
/// - `GraphEdge`
/// - `PdfCacheMeta`
/// - `RecentTabs`
/// - `SettingsEntity`
const List<CollectionSchema<dynamic>> allSchemas = [
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


