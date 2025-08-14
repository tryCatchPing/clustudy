import 'dart:async';

import 'package:isar/isar.dart';

import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';

class MaintenanceJobs {
  MaintenanceJobs._();
  static final MaintenanceJobs instance = MaintenanceJobs._();

  // 휴지통 청소: 30일 경과 일괄 삭제
  Future<int> purgeRecycleBin({int olderThanDays = 30}) async {
    final isar = await IsarDb.instance.open();
    final threshold = DateTime.now().subtract(Duration(days: olderThanDays));
    int deleted = 0;
    await isar.writeTxn(() async {
      final notes = await isar.notes.filter().deletedAtLessThan(threshold).findAll();
      if (notes.isNotEmpty) {
        await isar.notes.deleteAll(notes.map((e) => e.id).toList());
        deleted += notes.length;
      }
      final folders = await isar.folders.filter().deletedAtLessThan(threshold).findAll();
      if (folders.isNotEmpty) {
        await isar.folders.deleteAll(folders.map((e) => e.id).toList());
        deleted += folders.length;
      }
      final pages = await isar.pages.filter().deletedAtLessThan(threshold).findAll();
      if (pages.isNotEmpty) {
        await isar.pages.deleteAll(pages.map((e) => e.id).toList());
        deleted += pages.length;
      }
    });
    return deleted;
  }

  // 스냅샷 보존: 50개 또는 7일 초과 제거(선도달 기준)
  Future<int> trimSnapshots({int maxCount = 50, int maxDays = 7}) async {
    final isar = await IsarDb.instance.open();
    final threshold = DateTime.now().subtract(Duration(days: maxDays));
    int deleted = 0;
    await isar.writeTxn(() async {
      // by page group
      final groups = await isar.pageSnapshots.where().findAll();
      // naive: filter by time first
      final old = groups.where((s) => s.createdAt.isBefore(threshold)).toList();
      if (old.isNotEmpty) {
        await isar.pageSnapshots.deleteAll(old.map((e) => e.id).toList());
        deleted += old.length;
      }
      // enforce count: keep recent maxCount per pageId
      final byPage = <int, List<PageSnapshot>>{};
      for (final s in groups) {
        byPage.putIfAbsent(s.pageId, () => []).add(s);
      }
      for (final entry in byPage.entries) {
        final list = entry.value..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (list.length > maxCount) {
          final drop = list.sublist(maxCount);
          await isar.pageSnapshots.deleteAll(drop.map((e) => e.id).toList());
          deleted += drop.length;
        }
      }
    });
    return deleted;
  }
}


