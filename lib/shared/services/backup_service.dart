import 'dart:io';
import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  bool _isRunningBackup = false;
  Timer? _timer;

  Future<String> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<bool> _isDueDaily(String hhmm, DateTime? lastBackupAt) async {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    final hh = int.parse(parts[0]);
    final mm = int.parse(parts[1]);
    final scheduledToday = DateTime(now.year, now.month, now.day, hh, mm);
    if (lastBackupAt == null) return now.isAfter(scheduledToday);
    final lastDay = DateTime(lastBackupAt.year, lastBackupAt.month, lastBackupAt.day);
    final today = DateTime(now.year, now.month, now.day);
    if (today.isAfter(lastDay)) {
      return now.isAfter(scheduledToday);
    }
    return false;
  }

  Future<void> runIfDue() async {
    final isar = await IsarDb.instance.open();
    final settings = await isar.settingsEntitys.where().findFirst();
    if (settings == null) return;
    final due = await _isDueDaily(settings.backupDailyAt, settings.lastBackupAt);
    if (!due) return;
    // Guards: wifi/charging placeholder (can be extended with connectivity/battery plugins)
    // if (settings.backupRequireWifi == true) { ... }
    // if (settings.backupOnlyWhenCharging == true) { ... }
    if (_isRunningBackup) return;
    _isRunningBackup = true;
    try {
      await performBackup(retentionDays: settings.backupRetentionDays);
    } finally {
      _isRunningBackup = false;
    }
    await isar.writeTxn(() async {
      settings.lastBackupAt = DateTime.now();
      settings.dataVersion ??= 1;
      await isar.settingsEntitys.put(settings);
    });
  }

  void startScheduler({Duration interval = const Duration(minutes: 15)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      // Fire and forget; internal guard prevents overlap
      runIfDue();
    });
  }

  void stopScheduler() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> performBackup({required int retentionDays}) async {
    final isar = await IsarDb.instance.open();
    final dir = await _backupDir();
    final now = DateTime.now();
    final fileName = 'backup_${now.toIso8601String().replaceAll(':', '-')}.isar';
    final target = p.join(dir, fileName);
    await isar.copyToFile(target);
    await _enforceRetention(retentionDays);
  }

  Future<void> _enforceRetention(int retentionDays) async {
    final dir = await _backupDir();
    final d = Directory(dir);
    final files = await d
        .list()
        .where((e) => e is File && e.path.endsWith('.isar'))
        .cast<File>()
        .toList();
    final threshold = DateTime.now().subtract(Duration(days: retentionDays));
    for (final f in files) {
      final stat = await f.stat();
      if (stat.modified.isBefore(threshold)) {
        await f.delete();
      }
    }
  }
}


