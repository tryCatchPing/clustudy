import 'dart:async';

import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.g.dart';
import 'package:it_contest/snapshot/snapshot_service.dart';

/// Canvas save pipeline with debounced snapshot creation.
class CanvasPipeline {
  CanvasPipeline._();

  /// Public API: Save CanvasData and schedule debounced snapshot.
  static Future<void> saveCanvasWithDebouncedSnapshot(
    int noteId,
    int pageId,
    String json,
    String version,
  ) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      // Upsert CanvasData by pageId unique index (use indexed where-stage)
      final existing = await isar.canvasDatas.where().pageIdEqualTo(pageId).findFirst();
      if (existing == null) {
        final cd = CanvasData()
          ..noteId = noteId
          ..pageId = pageId
          ..schemaVersion = version
          ..json = json
          ..createdAt = now
          ..updatedAt = now;
        await isar.canvasDatas.put(cd);
      } else {
        existing
          ..noteId = noteId
          ..schemaVersion = version
          ..json = json
          ..updatedAt = now;
        await isar.canvasDatas.put(existing);
      }
    });

    // Debounced snapshot creation and retention
    SnapshotService.scheduleDebouncedSnapshot(
      noteId: noteId,
      pageId: pageId,
      json: json,
      schemaVersion: version,
    );
  }

  /// Hook to flush any pending snapshot when user navigates away or closes page.
  static Future<void> flushSnapshotForPage(int pageId) async {
    await SnapshotService.flushPending(pageId: pageId);
  }
}
