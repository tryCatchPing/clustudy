import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:isar/isar.dart';
import 'package:it_contest/crypto/keys.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Full backup service.
///
/// Creates an Isar snapshot and optional files archive, optionally encrypts the
/// artifact, and enforces retention based on settings.
class FullBackupService {
  FullBackupService._internal();

  static final FullBackupService _instance = FullBackupService._internal();
  /// Singleton instance.
  static FullBackupService get instance => _instance;

  Future<String> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> _notesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'notes');
  }

  Future<File> _createIsarSnapshot() async {
    final isar = await IsarDb.instance.open();
    final dir = await _backupDir();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final snapshotPath = p.join(dir, 'snapshot_$now.isar');
    await isar.copyToFile(snapshotPath);
    return File(snapshotPath);
  }

  Future<File> _zipContents({required bool includeFiles}) async {
    final dir = await _backupDir();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final zipPath = p.join(dir, 'backup_$now.zip');

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // 1) include isar snapshot
    final isarSnapshot = await _createIsarSnapshot();
    try {
      encoder.addFile(isarSnapshot);
    } finally {
      // snapshot file can be removed after adding
      try {
        await isarSnapshot.delete();
      } catch (_) {}
    }

    // 2) include notes directory excluding pdf_cache
    if (includeFiles) {
      final notes = Directory(await _notesDir());
      if (notes.existsSync()) {
        await for (final entity in notes.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final relative = p.relative(entity.path, from: notes.path);
            // exclude pdf_cache
            if (relative.split(Platform.pathSeparator).contains('pdf_cache')) {
              continue;
            }
            encoder.addFile(entity, p.join('notes', relative));
          }
        }
      }
    }

    encoder.close();
    return File(zipPath);
  }

  Future<File> _encryptFile(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final keyBytes = await CryptoKeys.instance.getOrCreateAesKey();
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = cipher.encryptBytes(bytes, iv: iv);
    final encPath = '${zipFile.path}.enc';
    final out = File(encPath);
    // File format: magic(6) + iv(16) + ciphertext
    final magic = utf8.encode('ITCBK1');
    await out.writeAsBytes(<int>[...magic, ...ivBytes, ...encrypted.bytes]);
    await zipFile.delete();
    return out;
  }

  Future<void> _enforceRetention(int retentionDays) async {
    final dir = await _backupDir();
    final d = Directory(dir);
    final threshold = DateTime.now().subtract(Duration(days: retentionDays));
    if (!d.existsSync()) {
      return;
    }
    final entries = await d.list().toList();
    for (final e in entries) {
      if (e is! File) {
        continue;
      }
      if (!(e.path.endsWith('.zip') || e.path.endsWith('.zip.enc') || e.path.endsWith('.isar')))
        {
          continue;
        }
      final stat = e.statSync();
      if (stat.modified.isBefore(threshold)) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }

  /// Run full backup.
  ///
  /// - When [encrypt] is true, the resulting zip is encrypted with AES-CBC.
  /// - Enforces retention using the configured `backupRetentionDays`.
  Future<void> runFullBackup({required bool includeFiles, required bool encrypt}) async {
    // Guards based on settings
    final isar = await IsarDb.instance.open();
    final settings = await isar.collection<SettingsEntity>().where().anyId().findFirst();
    final retentionDays = settings?.backupRetentionDays ?? 7;
    // Placeholder for wifi/charging guards (plugins can be integrated later)
    // if (settings?.backupRequireWifi == true) { ... }
    // if (settings?.backupOnlyWhenCharging == true) { ... }

    // Build zip
    File artifact = await _zipContents(includeFiles: includeFiles);
    // Optionally encrypt
    if (encrypt) {
      artifact = await _encryptFile(artifact);
    }

    // Retention cleanup
    await _enforceRetention(retentionDays);
  }
}
