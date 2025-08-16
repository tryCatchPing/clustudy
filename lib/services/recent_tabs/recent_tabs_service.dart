import 'dart:convert';

import 'package:isar/isar.dart';

import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';

/// Service responsible for maintaining RecentTabs integrity.
///
/// - Keeps LRU of 10
/// - Removes broken ids (non-existent or deleted notes)
class RecentTabsService {
  RecentTabsService._internal();

  static final RecentTabsService _instance = RecentTabsService._internal();
  static RecentTabsService get instance => _instance;

  /// Fix broken note ids in RecentTabs and enforce LRU 10.
  Future<void> recentTabsFixBrokenIds() async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final existing = await isar.recentTabs.where().findFirst();
      if (existing == null) return;

      List<int> ids;
      try {
        ids = (jsonDecode(existing.noteIdsJson) as List).map((e) => e as int).toList();
      } catch (_) {
        ids = <int>[];
      }

      // Deduplicate while preserving order
      final seen = <int>{};
      final deduped = <int>[];
      for (final id in ids) {
        if (seen.add(id)) {
          deduped.add(id);
        }
      }

      final fixed = <int>[];
      for (final id in deduped) {
        final note = await isar.notes.get(id);
        if (note != null && note.deletedAt == null) {
          fixed.add(id);
          if (fixed.length >= 10) break;
        }
      }

      existing
        ..noteIdsJson = jsonEncode(fixed)
        ..updatedAt = DateTime.now();
      await isar.recentTabs.put(existing);
    });
  }
}


