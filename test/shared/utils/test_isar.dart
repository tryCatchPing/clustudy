import 'dart:io';

import 'package:clustudy/shared/entities/link_entity.dart';
import 'package:clustudy/shared/entities/note_entities.dart';
import 'package:clustudy/shared/entities/note_placement_entity.dart';
import 'package:clustudy/shared/entities/thumbnail_metadata_entity.dart';
import 'package:clustudy/shared/entities/vault_entity.dart';
import 'package:clustudy/shared/services/isar_database_service.dart';
import 'package:isar/isar.dart';

class TestIsarContext {
  TestIsarContext(this.isar, this._directory);

  final Isar isar;
  final Directory _directory;

  Future<void> dispose() async {
    if (isar.isOpen) {
      await isar.close();
    }
    if (await _directory.exists()) {
      await _directory.delete(recursive: true);
    }
  }
}

Future<TestIsarContext> openTestIsar({String? name}) async {
  final directory = await Directory.systemTemp.createTemp('isar_test');
  final isar = await Isar.open(
    [
      VaultEntitySchema,
      FolderEntitySchema,
      NoteEntitySchema,
      NotePageEntitySchema,
      LinkEntitySchema,
      NotePlacementEntitySchema,
      ThumbnailMetadataEntitySchema,
      DatabaseMetadataEntitySchema,
    ],
    directory: directory.path,
    name: name ?? 'test_${DateTime.now().microsecondsSinceEpoch}',
  );

  return TestIsarContext(isar, directory);
}
