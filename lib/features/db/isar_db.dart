import 'dart:async';

import 'package:isar/isar.dart';
// Ensures Isar native bindings are available in Flutter (incl. tests)
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
// Ensure native Isar binaries are bundled for Flutter test/desktop
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

import 'models/vault_models.dart';

class IsarDb {
  IsarDb._internal();

  static final IsarDb _instance = IsarDb._internal();
  static IsarDb get instance => _instance;

  Isar? _isar;
  static String? _testDirectoryOverride;

  static void setTestDirectoryOverride(String? path) {
    _testDirectoryOverride = path;
  }

  Future<Isar> open({List<int>? encryptionKey}) async {
    if (_isar != null) {
      return _isar!;
    }
    final String directoryPath;
    if (_testDirectoryOverride != null) {
      directoryPath = _testDirectoryOverride!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directoryPath = dir.path;
    }
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
      directory: directoryPath,
      inspector: false,
    );
    return _isar!;
  }

  Future<void> close() async {
    final isar = _isar;
    if (isar != null) {
      await isar.close();
      _isar = null;
    }
  }
}


