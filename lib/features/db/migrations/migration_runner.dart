import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.g.dart';

/// 저장된 `SettingsEntity.dataVersion` 값을 기준으로
/// 데이터 스키마 마이그레이션을 수행합니다.
class MigrationRunner {
  /// 내부 생성자.
  MigrationRunner._();
  /// Singleton instance.
  /// 싱글턴 인스턴스.
  static final MigrationRunner instance = MigrationRunner._();

  /// 디스크의 데이터 버전이 현재 앱 스키마보다 낮으면,
  /// 필요한 마이그레이션을 실행합니다.
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
