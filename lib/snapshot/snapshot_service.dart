import 'dart:async';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:isar/isar.dart';

/// Snapshot service responsible for debounced PageSnapshot writes and retention.
class SnapshotService {
  SnapshotService._();

  static const Duration _debounceWindow = Duration(seconds: 2);
  static const Duration _retentionAge = Duration(days: 7);
  static const int _retentionCount = 50;

  static final Map<int, Timer> _pageIdToTimer = <int, Timer>{};
  static final Map<int, _SnapshotPayload> _latestPayloadByPage = <int, _SnapshotPayload>{};

  /// Schedule a debounced snapshot for the given page. The latest payload within
  /// the debounce window wins.
  static void scheduleDebouncedSnapshot({
    required int noteId,
    required int pageId,
    required String json,
    required String schemaVersion,
  }) {
    _latestPayloadByPage[pageId] = _SnapshotPayload(
      noteId: noteId,
      pageId: pageId,
      json: json,
      schemaVersion: schemaVersion,
    );

    _pageIdToTimer[pageId]?.cancel();
    _pageIdToTimer[pageId] = Timer(_debounceWindow, () async {
      final payload = _latestPayloadByPage[pageId];
      if (payload != null) {
        await _createSnapshot(payload);
        await _enforceRetention(pageId: pageId);
      }
      _pageIdToTimer.remove(pageId);
      _latestPayloadByPage.remove(pageId);
    });
  }

  /// Force-create a snapshot immediately with the latest known payload, if any.
  static Future<void> flushPending({required int pageId}) async {
    _pageIdToTimer[pageId]?.cancel();
    final payload = _latestPayloadByPage[pageId];
    if (payload != null) {
      await _createSnapshot(payload);
      await _enforceRetention(pageId: pageId);
    }
    _pageIdToTimer.remove(pageId);
    _latestPayloadByPage.remove(pageId);
  }

  static Future<void> _createSnapshot(_SnapshotPayload payload) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    final snapshot = PageSnapshot()
      ..pageId = payload.pageId
      ..schemaVersion = payload.schemaVersion
      ..json = payload.json
      ..createdAt = now;
    await isar.writeTxn(() async {
      await isar.pageSnapshots.put(snapshot);
    });
  }

  /// Keep snapshots within retention: not older than 7 days and at most 50 recent per page.
  static Future<void> _enforceRetention({required int pageId}) async {
    final isar = await IsarDb.instance.open();
    final cutoff = DateTime.now().subtract(_retentionAge);

    await isar.writeTxn(() async {
      // 1) Delete by age.
      final oldByAge = await isar.pageSnapshots
          .filter()
          .pageIdEqualTo(pageId)
          .createdAtLessThan(cutoff)
          .findAll();
      if (oldByAge.isNotEmpty) {
        await isar.pageSnapshots.deleteAll(oldByAge.map((e) => e.id).toList());
      }

      // 2) Enforce count limit.
      final allRecent = await isar.pageSnapshots.filter().pageIdEqualTo(pageId).findAll();
      if (allRecent.length > _retentionCount) {
        // Sort ascending by createdAt; delete oldest beyond the keep window.
        allRecent.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final toDelete = allRecent.take(allRecent.length - _retentionCount).toList();
        if (toDelete.isNotEmpty) {
          await isar.pageSnapshots.deleteAll(toDelete.map((e) => e.id).toList());
        }
      }
    });
  }
}

class _SnapshotPayload {
  _SnapshotPayload({
    required this.noteId,
    required this.pageId,
    required this.json,
    required this.schemaVersion,
  });

  final int noteId;
  final int pageId;
  final String json;
  final String schemaVersion;
}
