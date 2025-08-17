import 'dart:async';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/services/recent_tabs/recent_tabs_service.dart';

class MaintenanceJobs {
  MaintenanceJobs._();
  static final MaintenanceJobs instance = MaintenanceJobs._();

  Timer? _maintenanceTimer;

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
      // also trim dangling links older than threshold
      final links = await isar.linkEntitys
          .filter()
          .danglingEqualTo(true)
          .and()
          .updatedAtLessThan(threshold)
          .findAll();
      if (links.isNotEmpty) {
        await isar.linkEntitys.deleteAll(links.map((e) => e.id).toList());
        deleted += links.length;
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

  /// RecentTabs 정리: 깨진 noteId 제거, LRU 10 유지, 중복 제거
  Future<int> cleanupRecentTabs() async {
    final isar = await IsarDb.instance.open();
    int cleaned = 0;

    await isar.writeTxn(() async {
      // 기존 RecentTabsService의 정리 로직 활용
      await RecentTabsService.instance.recentTabsFixBrokenIds();
      cleaned = 1; // 정리 작업 수행됨을 표시
    });

    return cleaned;
  }

  /// 주기적 유지보수 작업 스케줄링
  Future<void> schedulePeriodicMaintenance({
    Duration interval = const Duration(hours: 6), // 6시간마다
  }) async {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(interval, (_) async {
      try {
        await cleanupRecentTabs();
        print('MaintenanceJobs: Periodic RecentTabs cleanup completed');
      } catch (e) {
        print('MaintenanceJobs: Error during periodic cleanup: $e');
      }
    });
  }

  /// 일일 유지보수: 휴지통 + 스냅샷 + RecentTabs 통합 정리
  Future<Map<String, int>> runDailyMaintenance() async {
    final results = <String, int>{};

    try {
      // 1. RecentTabs 정리
      results['recentTabs'] = await cleanupRecentTabs();

      // 2. 휴지통 정리 (30일 경과)
      results['recycleBin'] = await purgeRecycleBin(olderThanDays: 30);

      // 3. 스냅샷 정리 (50개 또는 7일 초과)
      results['snapshots'] = await trimSnapshots(maxCount: 50, maxDays: 7);

      print('MaintenanceJobs: Daily maintenance completed - $results');
    } catch (e) {
      print('MaintenanceJobs: Error during daily maintenance: $e');
      rethrow;
    }

    return results;
  }

  /// 스케줄러 중지
  void stopPeriodicMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
  }
}
