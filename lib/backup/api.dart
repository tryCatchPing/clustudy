import 'package:it_contest/backup/full_backup_service.dart';

// Frozen interface: Do not change signatures without contract update.
Future<void> runFullBackup({required bool includeFiles, required bool encrypt}) {
  return FullBackupService.instance.runFullBackup(includeFiles: includeFiles, encrypt: encrypt);
}
