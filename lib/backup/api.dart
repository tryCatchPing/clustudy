import 'package:it_contest/backup/full_backup_service.dart';

// Frozen interface: Do not change signatures without contract update.
/// Run a full backup.
///
/// - When [includeFiles] is true, includes note files (excluding pdf_cache).
/// - When [encrypt] is true, encrypts the archive with the current AES key.
Future<void> runFullBackup({required bool includeFiles, required bool encrypt}) {
  return FullBackupService.instance.runFullBackup(includeFiles: includeFiles, encrypt: encrypt);
}
