// ignore_for_file: avoid_print
/// 암호화 시스템 사용 예시
///
/// 이 파일은 구현된 암호화 기능들의 사용법을 보여주는 예시입니다.
library;

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';
import 'package:it_contest/shared/services/encryption_manager.dart';

/// 암호화 데모의 공개 API를 제공하는 클래스입니다.
///
/// 앱 내 암호화/키 관리 기능의 사용 흐름을 소규모 시나리오로 시연합니다.
/// 각 메서드는 콘솔 로그를 통해 단계별 결과를 안내합니다.
class EncryptionDemo {
  /// 기본 사용 흐름 데모입니다.
  ///
  /// - DB 평문 오픈 → 암호화 활성화 → 암호화 모드 재오픈 → 키 유효성 검증 순서를 시연합니다.
  /// - 반환값: 없음 (콘솔 로그로 결과 출력)
  static Future<void> demonstrateBasicUsage() async {
    print('=== 기본 암호화 사용법 데모 ===');

    try {
      // 1. 암호화 없이 데이터베이스 열기 (기본값)
      print('1. 암호화 없이 DB 열기...');
      await IsarDb.instance.open();
      print('   ✓ 성공');

      // 2. 암호화 활성화
      print('2. 암호화 활성화...');
      await IsarDb.instance.toggleEncryption(enable: true);
      print('   ✓ 암호화 활성화됨');

      // 3. 암호화된 상태에서 DB 다시 열기
      print('3. 암호화된 DB 열기...');
      await IsarDb.instance.close();
      await IsarDb.instance.open(enableEncryption: true);
      print('   ✓ 암호화된 DB 열기 성공');

      // 4. 키 유효성 검증
      print('4. 키 유효성 검증...');
      final manager = EncryptionManager.instance;
      final isValid = await manager.validateCurrentKey();
      print('   ✓ 키 유효성: $isValid');

      print('=== 데모 완료 ===');
    } catch (e) {
      print('❌ 오류 발생: $e');
    }
  }

  /// 키 회전 절차를 시연합니다.
  ///
  /// - 현재 백업 키 상태를 확인하고 키 회전을 수행합니다.
  /// - 결과, 경과 시간, 생성된 백업 경로를 출력합니다.
  static Future<void> demonstrateKeyRotation() async {
    print('=== 키 회전 데모 ===');

    try {
      final manager = EncryptionManager.instance;

      // 1. 현재 백업 키 상태 확인
      print('1. 현재 백업 키 확인...');
      final backups = await manager.getBackupKeysInfo();
      print('   현재 백업 키 개수: ${backups.length}');

      // 2. 키 회전 수행
      print('2. 키 회전 시작...');
      final result = await manager.rotateEncryptionKey();

      if (result.success) {
        print('   ✓ 키 회전 성공');
        print('   소요 시간: ${result.duration.inSeconds}초');
        print('   백업 경로: ${result.backupPath}');
      } else {
        print('   ❌ 키 회전 실패: ${result.error}');
      }

      // 3. 회전 후 백업 키 상태 확인
      print('3. 회전 후 백업 키 확인...');
      final newBackups = await manager.getBackupKeysInfo();
      print('   회전 후 백업 키 개수: ${newBackups.length}');

      print('=== 키 회전 데모 완료 ===');
    } catch (e) {
      print('❌ 오류 발생: $e');
    }
  }

  /// 백업 기반 복구 흐름을 시연합니다.
  ///
  /// - 최신 백업 메타 정보를 확인하고 복구 시뮬레이션 절차를 안내합니다.
  /// - 실제 복구 코드는 안전을 위해 주석 처리되어 있습니다.
  static Future<void> demonstrateRecovery() async {
    print('=== 복구 기능 데모 ===');

    try {
      final manager = EncryptionManager.instance;

      // 1. 백업 키 목록 확인
      print('1. 백업 키 목록 확인...');
      final backups = await manager.getBackupKeysInfo();

      if (backups.isEmpty) {
        print('   백업 키가 없습니다. 먼저 키 회전을 수행하세요.');
        return;
      }

      // 2. 가장 최근 백업 정보 출력
      final latestBackup = backups.first;
      print('   최신 백업: ${latestBackup.alias}');
      print('   생성 시간: ${latestBackup.timestamp}');
      print('   유효성: ${latestBackup.isValid}');

      // 3. 복구 테스트 (실제로는 수행하지 않음)
      print('2. 복구 테스트 (시뮬레이션)...');
      print('   복구할 백업: ${latestBackup.alias}');
      print('   ⚠️  실제 복구는 현재 데이터를 덮어쓸 수 있으므로 주의 필요');

      // 실제 복구 코드 (주석 처리)
      /*
      final recoveryResult = await manager.recoverFromBackup(latestBackup.alias);
      if (recoveryResult.success) {
        print('   ✓ 복구 성공');
      } else {
        print('   ❌ 복구 실패: ${recoveryResult.error}');
      }
      */

      print('=== 복구 기능 데모 완료 ===');
    } catch (e) {
      print('❌ 오류 발생: $e');
    }
  }

  /// 오류 상황에서의 방어적 동작을 시연합니다.
  ///
  /// - 잘못된 키 유효성 검증, 존재하지 않는 백업 키 로드 등의 케이스를 다룹니다.
  static Future<void> demonstrateErrorHandling() async {
    print('=== 오류 처리 데모 ===');

    try {
      final cryptoService = CryptoKeyService.instance;

      // 1. 잘못된 키로 검증 테스트
      print('1. 잘못된 키 검증 테스트...');
      final invalidKey = [1, 2, 3]; // 너무 짧은 키
      final isValid = await cryptoService.validateKey(invalidKey);
      print('   잘못된 키 유효성: $isValid (false여야 함)');

      // 2. 존재하지 않는 백업 키 로드 테스트
      print('2. 존재하지 않는 백업 키 로드 테스트...');
      final nonExistentKey = await cryptoService.loadBackupKey('nonexistent');
      print('   존재하지 않는 키: ${nonExistentKey == null ? "null (정상)" : "오류"}');

      print('=== 오류 처리 데모 완료 ===');
    } catch (e) {
      print('❌ 오류 발생: $e');
    }
  }

  /// 전체 데모 실행
  static Future<void> runFullDemo() async {
    print('🔐 암호화 시스템 전체 데모 시작\n');

    await demonstrateBasicUsage();
    print('');

    await demonstrateKeyRotation();
    print('');

    await demonstrateRecovery();
    print('');

    await demonstrateErrorHandling();
    print('');

    print('🔐 전체 데모 완료');
  }
}
