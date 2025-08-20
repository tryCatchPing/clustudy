import 'package:isar/isar.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/features/pdf_cache/models/pdf_cache_meta_model.dart';

/// 앱에서 사용하는 모든 Isar 컬렉션 스키마 목록입니다.
///
/// 데이터베이스를 열 때 이 목록을 전달하세요:
/// `await Isar.open(allSchemas, directory: path)`.
///
/// 포함된 컬렉션 타입:
/// - `Vault`
/// - `Folder`
/// - `NoteModel` (features/notes/models) - replaces vault_models Note
/// - `Page`
/// - `NotePageModel` (features/notes/models)
/// - `CanvasData`
/// - `PageSnapshot`
/// - `LinkEntity`
/// - `GraphEdge`
/// - `PdfCacheMetaModel` (features/pdf_cache/models) - replaces vault_models PdfCacheMeta
/// - `RecentTabs`
/// - `SettingsEntity`
const List<CollectionSchema<dynamic>> allSchemas = [
  VaultSchema,
  FolderSchema,
  NoteModelSchema, // 새로운 NoteModel 사용
  PageSchema,
  NotePageModelSchema,
  CanvasDataSchema,
  PageSnapshotSchema,
  LinkEntitySchema,
  GraphEdgeSchema,
  PdfCacheMetaModelSchema, // 새로운 PdfCacheMetaModel 사용
  RecentTabsSchema,
  SettingsEntitySchema,
];


