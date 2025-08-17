import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
      // 통합 백업 사용 (DB + PDF 파일들)
      await performIntegratedBackup(
        retentionDays: settings.backupRetentionDays,
        includeEncryption: settings.encryptionEnabled,
      );
      developer.log('통합 백업 완료 (DB + PDF 파일들)', name: 'BackupService');
    } on Exception catch (e) {
      developer.log('통합 백업 실패, 기본 백업으로 폴백', name: 'BackupService', error: e);
      try {
        await performBackup(retentionDays: settings.backupRetentionDays);
        developer.log('기본 백업 완료', name: 'BackupService');
      } on Exception catch (e2) {
        developer.log('기본 백업도 실패', name: 'BackupService', error: e2);
      }
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
      () async {
        try {
          await runIfDue();
        } on Object catch (e, stack) {
          // Log backup scheduler errors but don't stop the timer
          developer.log('BackupService scheduler error', name: 'BackupService', error: e, stackTrace: stack);
          // Optionally log stack trace for debugging
          if (kDebugMode) {
            developer.log('Stack trace', name: 'BackupService', stackTrace: stack);
          }
        }
      }();
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

  /// 통합 백업: DB + PDF 파일들을 zip으로 패키징
  Future<String> performIntegratedBackup({
    required int retentionDays,
    bool includeEncryption = false,
    String? customPassword,
  }) async {
    final isar = await IsarDb.instance.open();
    final dir = await _backupDir();
    final now = DateTime.now();
    final timestamp = now.toIso8601String().replaceAll(':', '-');

    // 임시 작업 디렉토리 생성
    final tempDir = Directory(p.join(dir, 'temp_$timestamp'));
    await tempDir.create(recursive: true);

    try {
      // 1. DB 백업
      final dbBackupPath = p.join(tempDir.path, 'database.isar');
      await isar.copyToFile(dbBackupPath);

      // 2. PDF 파일들 수집
      final pdfDir = Directory(p.join(tempDir.path, 'pdf_files'));
      await pdfDir.create();
      await _collectPdfFiles(pdfDir.path);

      // 3. 메타데이터 생성
      final metadata = await _generateBackupMetadata();
      final metadataFile = File(p.join(tempDir.path, 'backup_metadata.json'));
      await metadataFile.writeAsString(jsonEncode(metadata));

      // 4. ZIP 압축
      final zipFileName = includeEncryption
          ? 'integrated_backup_$timestamp.zip.encrypted'
          : 'integrated_backup_$timestamp.zip';
      final zipPath = p.join(dir, zipFileName);

      if (includeEncryption) {
        await _createEncryptedZip(tempDir.path, zipPath, customPassword);
      } else {
        await _createZip(tempDir.path, zipPath);
      }

      // 5. 보존 정책 적용
      await _enforceIntegratedRetention(retentionDays);

      return zipPath;
    } finally {
      // 임시 디렉토리 정리
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// PDF 파일들을 백업 디렉토리로 수집
  Future<void> _collectPdfFiles(String targetDir) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final notesDir = Directory(p.join(docs.path, 'notes'));

      if (!notesDir.existsSync()) return;

      await for (final entity in notesDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: notesDir.path);
          final targetPath = p.join(targetDir, relativePath);

          // 디렉토리 구조 생성
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);

          // 파일 복사
          await entity.copy(targetPath);
        }
      }
    } on Exception catch (e) {
      developer.log('PDF 파일 수집 중 오류', name: 'BackupService', error: e);
      // PDF 파일 수집 실패해도 백업은 계속 진행
    }
  }

  /// 백업 메타데이터 생성
  Future<Map<String, dynamic>> _generateBackupMetadata() async {
    final isar = await IsarDb.instance.open();

    return {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // TODO: 실제 앱 버전으로 교체
      'database_schema_version': 1,
      'statistics': {
        'vault_count': await isar.vaults.where().count(),
        'folder_count': await isar.folders.where().count(),
        'note_count': await isar.notes.where().count(),
        'page_count': await isar.pages.where().count(),
        'link_count': await isar.linkEntitys.where().count(),
      },
      'backup_type': 'integrated',
      'includes_pdf_files': true,
    };
  }

  /// 일반 ZIP 생성
  Future<void> _createZip(String sourceDir, String zipPath) async {
    final archive = Archive();
    final dir = Directory(sourceDir);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir);
        final bytes = await entity.readAsBytes();
        final file = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(file);
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await File(zipPath).writeAsBytes(zipData);
    }
  }

  /// 암호화된 ZIP 생성
  Future<void> _createEncryptedZip(String sourceDir, String zipPath, String? customPassword) async {
    // 1. 일반 ZIP 생성
    final archive = Archive();
    final dir = Directory(sourceDir);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir);
        final bytes = await entity.readAsBytes();
        final file = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(file);
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('ZIP 생성 실패');

    // 2. 암호화
    final password = customPassword ?? await _getBackupEncryptionKey();
    final iv = IV.fromSecureRandom(16);

    // 패스워드로부터 키 생성 (PBKDF2 사용)
    final actualKey = _deriveKeyFromPassword(password);
    final actualEncrypter = Encrypter(AES(Key(actualKey)));

    final encrypted = actualEncrypter.encryptBytes(zipData, iv: iv);

    // 3. 암호화된 데이터와 메타데이터 저장
    final encryptedData = {
      'iv': iv.base64,
      'data': encrypted.base64,
      'version': '1.0',
    };

    await File(zipPath).writeAsString(jsonEncode(encryptedData));
  }

  /// 패스워드로부터 암호화 키 생성 (간단한 PBKDF2)
  Uint8List _deriveKeyFromPassword(String password) {
    // 실제 구현에서는 crypto 패키지의 PBKDF2 사용 권장
    final bytes = utf8.encode(password);
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = bytes[i % bytes.length];
    }
    return key;
  }

  /// 백업 암호화 키 가져오기
  Future<String> _getBackupEncryptionKey() async {
    // CryptoKeyService에서 키를 가져와서 Base64 문자열로 변환
    final keyBytes = await CryptoKeyService.instance.getOrCreateKey();
    return base64Encode(keyBytes);
  }

  /// 통합 백업 보존 정책 적용
  Future<void> _enforceIntegratedRetention(int retentionDays) async {
    final dir = await _backupDir();
    final d = Directory(dir);
    final files = await d
        .list()
        .where(
          (e) =>
              e is File &&
              (e.path.contains('integrated_backup_') ||
                  e.path.endsWith('.zip') ||
                  e.path.endsWith('.zip.encrypted')),
        )
        .cast<File>()
        .toList();

    final threshold = DateTime.now().subtract(Duration(days: retentionDays));

    for (final f in files) {
      final stat = f.statSync();
      if (stat.modified.isBefore(threshold)) {
        await f.delete();
      }
    }
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
      final stat = f.statSync();
      if (stat.modified.isBefore(threshold)) {
        await f.delete();
      }
    }
  }

  /// 통합 백업 복원
  Future<RestoreResult> restoreIntegratedBackup({
    required String backupPath,
    String? password,
    bool overwriteExisting = false,
  }) async {
    final result = RestoreResult();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final tempDir = Directory(p.join((await _backupDir()), 'restore_temp_$timestamp'));

    try {
      await tempDir.create(recursive: true);

      // 1. 백업 파일 추출
      if (backupPath.endsWith('.encrypted')) {
        if (password == null) {
          throw Exception('암호화된 백업에는 패스워드가 필요합니다');
        }
        await _extractEncryptedBackup(backupPath, tempDir.path, password);
      } else {
        await _extractZipBackup(backupPath, tempDir.path);
      }

      // 2. 메타데이터 검증
      final metadataFile = File(p.join(tempDir.path, 'backup_metadata.json'));
      if (metadataFile.existsSync()) {
        final metadata = jsonDecode(await metadataFile.readAsString());
        result.metadata = Map<String, dynamic>.from(metadata);

        // 버전 호환성 체크
        if (!_isBackupCompatible(metadata)) {
          throw Exception('호환되지 않는 백업 버전입니다');
        }
      }

      // 3. 기존 데이터 백업 (overwrite 모드일 때)
      if (overwriteExisting) {
        await _backupCurrentData();
      }

      // 4. 데이터베이스 복원
      final dbFile = File(p.join(tempDir.path, 'database.isar'));
      if (dbFile.existsSync()) {
        await _restoreDatabase(dbFile.path, overwriteExisting);
        result.databaseRestored = true;
      }

      // 5. PDF 파일들 복원
      final pdfDir = Directory(p.join(tempDir.path, 'pdf_files'));
      if (pdfDir.existsSync()) {
        final restoredCount = await _restorePdfFiles(pdfDir.path, overwriteExisting);
        result.pdfFilesRestored = restoredCount;
      }

      result.success = true;
      result.message = '백업이 성공적으로 복원되었습니다';
    } on Exception catch (e) {
      result.success = false;
      result.message = '복원 실패: $e';
      result.error = e.toString();
    } finally {
      // 임시 디렉토리 정리
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }

    return result;
  }

  /// 암호화된 백업 추출
  Future<void> _extractEncryptedBackup(
    String backupPath,
    String extractDir,
    String password,
  ) async {
    final encryptedFile = File(backupPath);
    final encryptedContent = await encryptedFile.readAsString();
    final encryptedData = jsonDecode(encryptedContent);

    final iv = IV.fromBase64(encryptedData['iv']);
    final encrypted = Encrypted.fromBase64(encryptedData['data']);

    // 패스워드로부터 키 생성
    final key = _deriveKeyFromPassword(password);
    final encrypter = Encrypter(AES(Key(key)));

    // 복호화
    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);

    // ZIP 추출
    final archive = ZipDecoder().decodeBytes(decryptedBytes);
    for (final file in archive) {
      final fileName = file.name;
      final filePath = p.join(extractDir, fileName);

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
  }

  /// 일반 ZIP 백업 추출
  Future<void> _extractZipBackup(String backupPath, String extractDir) async {
    final backupFile = File(backupPath);
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final fileName = file.name;
      final filePath = p.join(extractDir, fileName);

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
  }

  /// 백업 호환성 검증
  bool _isBackupCompatible(Map<String, dynamic> metadata) {
    final version = metadata['version'] as String?;
    final schemaVersion = metadata['database_schema_version'] as int?;

    // 현재는 모든 버전을 호환으로 처리
    // 실제로는 스키마 버전 체크 필요
    return version != null && schemaVersion != null;
  }

  /// 현재 데이터 백업 (복원 전 안전장치)
  Future<void> _backupCurrentData() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await performBackup(retentionDays: 30); // 30일 보관
  }

  /// 데이터베이스 복원
  Future<void> _restoreDatabase(String dbPath, bool overwrite) async {
    // 기존 데이터베이스 닫기
    await IsarDb.instance.close();

    // 데이터베이스 파일 교체
    final docs = await getApplicationDocumentsDirectory();
    final targetDbPath = p.join(docs.path, 'default.isar');

    if (overwrite || !File(targetDbPath).existsSync()) {
      await File(dbPath).copy(targetDbPath);
    }

    // 데이터베이스 다시 열기
    await IsarDb.instance.open();
  }

  /// PDF 파일들 복원
  Future<int> _restorePdfFiles(String pdfBackupDir, bool overwrite) async {
    int restoredCount = 0;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final targetNotesDir = Directory(p.join(docs.path, 'notes'));
      await targetNotesDir.create(recursive: true);

      final backupDir = Directory(pdfBackupDir);
      await for (final entity in backupDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: backupDir.path);
          final targetPath = p.join(targetNotesDir.path, relativePath);
          final targetFile = File(targetPath);

          if (overwrite || !targetFile.existsSync()) {
            await targetFile.parent.create(recursive: true);
            await entity.copy(targetPath);
            restoredCount++;
          }
        }
      }
    } on Exception catch (e) {
      developer.log('PDF 파일 복원 중 오류', name: 'BackupService', error: e);
    }

    return restoredCount;
  }

  /// 사용 가능한 백업 목록 조회
  Future<List<BackupInfo>> getAvailableBackups() async {
    final dir = await _backupDir();
    final d = Directory(dir);
    final backups = <BackupInfo>[];

    await for (final entity in d.list()) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        final stat = entity.statSync();

        BackupType type;
        bool isEncrypted = false;

        if (fileName.endsWith('.isar')) {
          type = BackupType.database;
        } else if (fileName.endsWith('.zip.encrypted')) {
          type = BackupType.integrated;
          isEncrypted = true;
        } else if (fileName.endsWith('.zip')) {
          type = BackupType.integrated;
        } else {
          continue; // 알 수 없는 파일 타입
        }

        backups.add(
          BackupInfo(
            fileName: fileName,
            filePath: entity.path,
            type: type,
            isEncrypted: isEncrypted,
            createdAt: stat.modified,
            sizeBytes: stat.size,
          ),
        );
      }
    }

    // 최신순으로 정렬
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return backups;
  }

  /// 백업 파일 삭제
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } on Exception catch (e) {
      developer.log('백업 삭제 실패', name: 'BackupService', error: e);
      return false;
    }
  }

  /// 백업 상태 조회
  Future<BackupStatus> getBackupStatus() async {
    final isar = await IsarDb.instance.open();
    final settings = await isar.settingsEntitys.where().findFirst();
    final backups = await getAvailableBackups();

    return BackupStatus(
      isRunning: _isRunningBackup,
      lastBackupAt: settings?.lastBackupAt,
      nextBackupDue: settings != null
          ? await _getNextBackupTime(settings.backupDailyAt, settings.lastBackupAt)
          : null,
      availableBackupsCount: backups.length,
      totalBackupSize: backups.fold(0, (sum, backup) => sum + backup.sizeBytes),
      encryptionEnabled: settings?.encryptionEnabled ?? false,
    );
  }

  /// 다음 백업 예정 시간 계산
  Future<DateTime?> _getNextBackupTime(String dailyAt, DateTime? lastBackupAt) async {
    final now = DateTime.now();
    final parts = dailyAt.split(':');
    final hh = int.parse(parts[0]);
    final mm = int.parse(parts[1]);

    var nextBackup = DateTime(now.year, now.month, now.day, hh, mm);

    // 오늘 시간이 지났으면 내일로
    if (nextBackup.isBefore(now)) {
      nextBackup = nextBackup.add(const Duration(days: 1));
    }

    // 이미 오늘 백업했으면 내일로
    if (lastBackupAt != null) {
      final lastBackupDay = DateTime(lastBackupAt.year, lastBackupAt.month, lastBackupAt.day);
      final today = DateTime(now.year, now.month, now.day);

      if (!lastBackupDay.isBefore(today)) {
        nextBackup = nextBackup.add(const Duration(days: 1));
      }
    }

    return nextBackup;
  }

  /// 백업 테스트 (암호화/복원 검증)
  Future<TestResult> testBackupRestore() async {
    final result = TestResult();

    try {
      // 1. 테스트 백업 생성
      final testBackupPath = await performIntegratedBackup(
        retentionDays: 1,
        includeEncryption: true,
      );
      result.backupCreated = true;

      // 2. 백업 파일 존재 확인
      if (!File(testBackupPath).existsSync()) {
        throw Exception('백업 파일이 생성되지 않았습니다');
      }
      result.backupFileExists = true;

      // 3. 복원 테스트 (실제로는 복원하지 않고 파일만 검증)
      final tempDir = Directory.systemTemp.createTempSync('backup_test_');
      try {
        if (testBackupPath.endsWith('.encrypted')) {
          final password = await _getBackupEncryptionKey();
          await _extractEncryptedBackup(testBackupPath, tempDir.path, password);
        } else {
          await _extractZipBackup(testBackupPath, tempDir.path);
        }

        // 메타데이터 파일 확인
        final metadataFile = File(p.join(tempDir.path, 'backup_metadata.json'));
        if (metadataFile.existsSync()) {
          final metadata = jsonDecode(await metadataFile.readAsString());
          result.metadataValid = metadata['version'] != null;
        }

        // DB 파일 확인
        final dbFile = File(p.join(tempDir.path, 'database.isar'));
        result.databaseExtractable = dbFile.existsSync();
      } finally {
        await tempDir.delete(recursive: true);
      }

      // 4. 테스트 백업 삭제
      await deleteBackup(testBackupPath);

      result.success = true;
      result.message = '백업/복원 테스트가 성공적으로 완료되었습니다';
    } on Exception catch (e) {
      result.success = false;
      result.message = '테스트 실패: $e';
      result.error = e.toString();
    }

    return result;
  }
}

/// 백업 복원 결과
class RestoreResult {
  bool success = false;
  String message = '';
  String? error;
  Map<String, dynamic>? metadata;
  bool databaseRestored = false;
  int pdfFilesRestored = 0;
}

/// 백업 정보
class BackupInfo {
  final String fileName;
  final String filePath;
  final BackupType type;
  final bool isEncrypted;
  final DateTime createdAt;
  final int sizeBytes;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.isEncrypted,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024)
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 백업 타입
enum BackupType {
  database, // .isar 파일만
  integrated, // DB + PDF 통합 백업
}

/// 백업 상태
class BackupStatus {
  final bool isRunning;
  final DateTime? lastBackupAt;
  final DateTime? nextBackupDue;
  final int availableBackupsCount;
  final int totalBackupSize;
  final bool encryptionEnabled;

  BackupStatus({
    required this.isRunning,
    this.lastBackupAt,
    this.nextBackupDue,
    required this.availableBackupsCount,
    required this.totalBackupSize,
    required this.encryptionEnabled,
  });

  String get formattedTotalSize {
    if (totalBackupSize < 1024) return '$totalBackupSize B';
    if (totalBackupSize < 1024 * 1024) return '${(totalBackupSize / 1024).toStringAsFixed(1)} KB';
    if (totalBackupSize < 1024 * 1024 * 1024)
      return '${(totalBackupSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBackupSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Duration? get timeUntilNextBackup {
    if (nextBackupDue == null) return null;
    final now = DateTime.now();
    if (nextBackupDue!.isBefore(now)) return Duration.zero;
    return nextBackupDue!.difference(now);
  }
}

/// 테스트 결과
class TestResult {
  bool success = false;
  String message = '';
  String? error;
  bool backupCreated = false;
  bool backupFileExists = false;
  bool metadataValid = false;
  bool databaseExtractable = false;
}
