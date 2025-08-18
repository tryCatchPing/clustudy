import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:isar/isar.dart';

class MigrationRunner {
  MigrationRunner._();
  static final MigrationRunner instance = MigrationRunner._();

  Future<void> runMigrationsIfNeeded() async {
    final isar = await IsarDb.instance.open();
    final settings = await isar.collection<SettingsEntity>().where().anyId().findFirst();
    if (settings == null) {
      // First run: create default settings with version 1
      final s = SettingsEntity()
        ..encryptionEnabled = false
        ..backupDailyAt = '02:00'
        ..backupRetentionDays = 7
        ..recycleRetentionDays = 30
        ..keychainAlias = null
        ..dataVersion = 1;
      await isar.writeTxn(() async {
        await isar.settingsEntitys.put(s);
      });
      return;
    }
    final int current = settings.dataVersion ?? 1;
    // Example future steps:
    // if (current < 2) { await _toV2(isar); current = 2; }
    // if (current < 3) { await _toV3(isar); current = 3; }
    if (current != (settings.dataVersion ?? 1)) {
      await isar.writeTxn(() async {
        settings.dataVersion = current;
        await isar.settingsEntitys.put(settings);
      });
    }
  }
}
