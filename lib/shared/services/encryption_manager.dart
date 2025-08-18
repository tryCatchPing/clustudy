import 'dart:async';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';

/// 암호화 관리 서비스
/// 키 회전, 재암호화, 복구 등의 고급 암호화 기능을 제공합니다.
class EncryptionManager {
  EncryptionManager._();
  /// 싱글턴 인스턴스
  static final EncryptionManager instance = EncryptionManager._();

  final CryptoKeyService _cryptoService = CryptoKeyService.instance;
  final IsarDb _isarDb = IsarDb.instance;

  /// 안전한 키 회전을 수행합니다
  ///
  /// 전체 과정:
  /// 1. 현재 데이터 백업
  /// 2. 새 키 생성
  /// 3. 데이터베이스 재암호화
  /// 4. 백업 정리
  Future<KeyRotationResult> rotateEncryptionKey() async {
    final startTime = DateTime.now();

    try {
      // 1. 현재 상태 확인
      final currentKey = await _cryptoService.loadKey();
      if (currentKey == null) {
        throw const EncryptionException('No encryption key found');
      }

      // 2. 데이터 무결성 사전 검증
      await _validateDatabaseIntegrity();

      // 3. 전체 백업 생성 (안전장치)
      final backupPath = await _createEmergencyBackup();

      // 4. 새 키 생성 및 회전
      final newKey = await _cryptoService.rotateKey();

      // 5. 데이터베이스 재암호화
      await _cryptoService.reencryptDatabase(currentKey, newKey);

      // 6. 재암호화 후 무결성 검증
      await _validateDatabaseIntegrity();

      // 7. 성공적 완료 후 정리
      await _cleanupAfterSuccessfulRotation();

      final duration = DateTime.now().difference(startTime);

      return KeyRotationResult(
        success: true,
        newKeyCreated: true,
        duration: duration,
        backupPath: backupPath,
      );
    } catch (e) {
      // 실패 시 복구 시도
      await _attemptRecovery();

      return KeyRotationResult(
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// 암호화 상태를 안전하게 토글합니다
  Future<EncryptionToggleResult> toggleEncryption({required bool enable}) async {
    final startTime = DateTime.now();

    try {
      // 현재 상태 확인
      final currentSettings = await _getCurrentSettings();
      final isCurrentlyEncrypted = currentSettings?.encryptionEnabled ?? false;

      if (isCurrentlyEncrypted == enable) {
        return EncryptionToggleResult(
          success: true,
          alreadyInDesiredState: true,
          duration: DateTime.now().difference(startTime),
        );
      }

      // 사전 검증
      await _validateDatabaseIntegrity();

      // 백업 생성
      final backupPath = await _createEmergencyBackup();

      // 암호화 토글 실행
      await _isarDb.toggleEncryption(enable: enable);

      // 후 검증
      await _validateDatabaseIntegrity();

      return EncryptionToggleResult(
        success: true,
        encryptionEnabled: enable,
        duration: DateTime.now().difference(startTime),
        backupPath: backupPath,
      );
    } catch (e) {
      await _attemptRecovery();

      return EncryptionToggleResult(
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// 데이터베이스 무결성을 검증합니다
  Future<void> _validateDatabaseIntegrity() async {
    final isar = await _isarDb.open();

    // 기본적인 읽기 테스트
    try {
      await isar.collection<Vault>().count();
      await isar.collection<Note>().count();
      await isar.collection<SettingsEntity>().count();
    } catch (e) {
      throw EncryptionException('Database integrity check failed: $e');
    }
  }

  /// 응급 백업을 생성합니다
  Future<String> _createEmergencyBackup() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupAlias = 'emergency_backup_$timestamp';

    // 현재 키를 응급 백업으로 저장
    final currentKey = await _cryptoService.loadKey();
    if (currentKey != null) {
      await _cryptoService.backupKey(currentKey, backupAlias);
    }

    return backupAlias;
  }

  /// 성공적인 키 회전 후 정리 작업
  Future<void> _cleanupAfterSuccessfulRotation() async {
    // 오래된 백업 키들 정리 (최근 5개만 보관)
    await _cryptoService.cleanupOldBackups(retainCount: 5);
  }

  /// 실패 시 복구를 시도합니다
  Future<void> _attemptRecovery() async {
    try {
      // 최근 백업 키들 조회
      final backupAliases = await _cryptoService.getBackupKeyAliases();

      if (backupAliases.isNotEmpty) {
        // 가장 최근 백업 키로 복구 시도
        backupAliases.sort((a, b) {
          final timestampA = int.tryParse(a) ?? 0;
          final timestampB = int.tryParse(b) ?? 0;
          return timestampB.compareTo(timestampA);
        });

        final latestBackupAlias = backupAliases.first;
        final backupKey = await _cryptoService.loadBackupKey(latestBackupAlias);

        if (backupKey != null) {
          // 백업 키로 DB 열기 시도
          await _isarDb.close();
          await _isarDb.open(encryptionKey: backupKey);

          // 복구 성공 시 백업 키를 메인 키로 복원
          await _cryptoService.backupKey(backupKey, 'main');
        }
      }
    } catch (e) {
      // 복구 실패 - 로그 기록 또는 사용자에게 알림
      rethrow;
    }
  }

  /// 현재 설정을 조회합니다
  Future<SettingsEntity?> _getCurrentSettings() async {
    final isar = await _isarDb.open();
    // Isar v3 표준 쿼리 패턴 사용
    return await isar.settingsEntitys.where().anyId().findFirst();
  }

  /// 키 검증을 수행합니다
  Future<bool> validateCurrentKey() async {
    final key = await _cryptoService.loadKey();
    if (key == null) {
      return false;
    }

    return await _cryptoService.validateKey(key);
  }

  /// 모든 백업 키들의 상태를 조회합니다
  Future<List<BackupKeyInfo>> getBackupKeysInfo() async {
    final aliases = await _cryptoService.getBackupKeyAliases();
    final result = <BackupKeyInfo>[];

    for (final alias in aliases) {
      final key = await _cryptoService.loadBackupKey(alias);
      if (key != null) {
        final isValid = await _cryptoService.validateKey(key);
        final timestamp = int.tryParse(alias);

        result.add(
          BackupKeyInfo(
            alias: alias,
            timestamp: timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null,
            isValid: isValid,
            keyLength: key.length,
          ),
        );
      }
    }

    // 타임스탬프 기준으로 정렬 (최신 순)
    result.sort((a, b) {
      if (a.timestamp == null || b.timestamp == null) {
        return 0;
      }
      return b.timestamp!.compareTo(a.timestamp!);
    });

    return result;
  }

  /// 특정 백업 키로 복구를 시도합니다
  Future<RecoveryResult> recoverFromBackup(String backupAlias) async {
    final startTime = DateTime.now();

    try {
      final backupKey = await _cryptoService.loadBackupKey(backupAlias);
      if (backupKey == null) {
        throw EncryptionException('Backup key not found: $backupAlias');
      }

      // 백업 키 유효성 검증
      final isValid = await _cryptoService.validateKey(backupKey);
      if (!isValid) {
        throw const EncryptionException('Backup key is invalid or corrupted');
      }

      // 현재 DB 닫기
      await _isarDb.close();

      // 백업 키로 DB 열기
      await _isarDb.open(encryptionKey: backupKey);

      // 무결성 검증
      await _validateDatabaseIntegrity();

      return RecoveryResult(
        success: true,
        recoveredFromAlias: backupAlias,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return RecoveryResult(
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }
}

/// 키 회전 결과
class KeyRotationResult {
  /// 성공 여부
  final bool success;
  /// 새 키 생성 여부
  final bool newKeyCreated;
  /// 작업 소요 시간
  final Duration duration;
  /// 응급 백업 식별자 경로(선택)
  final String? backupPath;
  /// 오류 메시지(실패 시)
  final String? error;

  /// 키 회전 결과 인스턴스를 생성합니다
  const KeyRotationResult({
    required this.success,
    this.newKeyCreated = false,
    required this.duration,
    this.backupPath,
    this.error,
  });
}

/// 암호화 토글 결과
class EncryptionToggleResult {
  /// 성공 여부
  final bool success;
  /// 현재 암호화 활성화 여부(선택)
  final bool? encryptionEnabled;
  /// 이미 원하는 상태였는지 여부
  final bool alreadyInDesiredState;
  /// 작업 소요 시간
  final Duration duration;
  /// 응급 백업 식별자 경로(선택)
  final String? backupPath;
  /// 오류 메시지(실패 시)
  final String? error;

  /// 암호화 토글 결과 인스턴스를 생성합니다
  const EncryptionToggleResult({
    required this.success,
    this.encryptionEnabled,
    this.alreadyInDesiredState = false,
    required this.duration,
    this.backupPath,
    this.error,
  });
}

/// 백업 키 정보
class BackupKeyInfo {
  /// 백업 키 별칭
  final String alias;
  /// 백업 생성 시각(별칭이 타임스탬프일 때)
  final DateTime? timestamp;
  /// 키 유효성 여부
  final bool isValid;
  /// 키 길이(바이트)
  final int keyLength;

  /// 백업 키 정보 인스턴스를 생성합니다
  const BackupKeyInfo({
    required this.alias,
    this.timestamp,
    required this.isValid,
    required this.keyLength,
  });
}

/// 복구 결과
class RecoveryResult {
  /// 성공 여부
  final bool success;
  /// 복구에 사용된 백업 별칭(선택)
  final String? recoveredFromAlias;
  /// 작업 소요 시간
  final Duration duration;
  /// 오류 메시지(실패 시)
  final String? error;

  /// 복구 결과 인스턴스를 생성합니다
  const RecoveryResult({
    required this.success,
    this.recoveredFromAlias,
    required this.duration,
    this.error,
  });
}

/// 암호화 예외
class EncryptionException implements Exception {
  /// 오류 메시지
  final String message;

  /// 암호화 관련 예외를 생성합니다
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
