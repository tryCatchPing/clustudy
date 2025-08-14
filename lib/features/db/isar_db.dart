import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/vault_models.dart';

class IsarDb {
  IsarDb._internal();

  static final IsarDb _instance = IsarDb._internal();
  static IsarDb get instance => _instance;

  Isar? _isar;

  Future<Isar> open() async {
    if (_isar != null) {
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
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
      ],
      directory: dir.path,
    );
    return _isar!;
  }

  Future<void> close() async {
    final isar = _isar;
    if (isar != null && !isar.isClosed) {
      await isar.close();
      _isar = null;
    }
  }
}


