import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:path_provider/path_provider.dart';

/// 암호화 키를 생성/저장/회전/검증하는 서비스
class CryptoKeyService {
  CryptoKeyService._();
  /// 전역에서 접근 가능한 싱글턴 인스턴스입니다.
  ///
  /// 앱 수명 주기 전반에 걸쳐 동일한 키 관리 컨텍스트를 유지하기 위해
  /// 하나의 인스턴스만 사용합니다.
  static final CryptoKeyService instance = CryptoKeyService._();

  static const _keyAlias = 'isar_encryption_key_v1';
  static const _backupPrefix = 'isar_backup_key_';
  static const _storage = FlutterSecureStorage();

  /// 보안 저장소에서 현재 데이터베이스 암호화 키를 로드합니다.
  ///
  /// 반환:
  /// - 저장된 키가 있으면 32바이트 키 바이트 배열
  /// - 저장된 키가 없거나 읽기에 실패하면 `null`
  Future<List<int>?> loadKey() async {
    try {
      final base64 = await _storage.read(key: _keyAlias);
      if (base64 == null) {
        return null;
      }
      return _decode(base64);
    } on Exception catch (e, stack) {
      // Log storage access failures for debugging
      developer.log('Failed to load encryption key', name: 'CryptoKeyService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// 저장된 암호화 키를 반환하고, 없으면 새 32바이트 키를 생성하여 저장합니다.
  ///
  /// 항상 유효한 32바이트 키를 반환합니다.
  Future<List<int>> getOrCreateKey() async {
    final existing = await loadKey();
    if (existing != null) {
      return existing;
    }
    final bytes = _randomBytes(32);
    await _storage.write(key: _keyAlias, value: _encode(bytes));
    return bytes;
  }

  /// 새로운 키를 생성하고 기존 키를 백업합니다.
  Future<List<int>> rotateKey() async {
    // 기존 키 백업
    final oldKey = await loadKey();
    if (oldKey != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupAlias = '$_backupPrefix$timestamp';
      await _storage.write(key: backupAlias, value: _encode(oldKey));
    }

    // 새 키 생성 및 저장
    final newKey = _randomBytes(32);
    await _storage.write(key: _keyAlias, value: _encode(newKey));

    return newKey;
  }

  /// 데이터베이스를 새로운 키로 재암호화합니다.
  Future<void> reencryptDatabase(List<int> oldKey, List<int> newKey) async {
    final isarDb = IsarDb.instance;

    // 기존 DB 닫기
    await isarDb.close();

    try {
      // 기존 키로 DB 열기
      final oldIsar = await isarDb.open(encryptionKey: oldKey);

      // 모든 데이터 백업
      final backupData = await _createFullBackup(oldIsar);
      await oldIsar.close();

      // DB 파일 삭제 (암호화된 파일은 새 키로 재생성 필요)
      await _deleteDbFiles();

      // 새 키로 DB 열기
      final newIsar = await isarDb.open(encryptionKey: newKey);

      // 백업된 데이터 복원
      await _restoreFromBackup(newIsar, backupData);
    } catch (e) {
      // 실패 시 원래 키로 복구 시도
      try {
        await isarDb.open(encryptionKey: oldKey);
      } catch (rollbackError) {
        throw Exception(
          'Database reencryption failed and rollback also failed: $e, $rollbackError',
        );
      }
      rethrow;
    }
  }

  /// 이전 백업 키를 안전하게 삭제합니다.
  Future<void> deleteOldKey(String keyAlias) async {
    await _storage.delete(key: keyAlias);
  }

  /// 키의 유효성을 검증합니다.
  Future<bool> validateKey(List<int> key) async {
    if (key.length != 32) {
      return false;
    }

    try {
      // 키로 임시 DB 열기 테스트
      final isarDb = IsarDb.instance;
      await isarDb.close();
      await isarDb.open(encryptionKey: key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 키를 지정된 별칭으로 백업합니다.
  Future<void> backupKey(List<int> key, String backupAlias) async {
    final fullAlias = '$_backupPrefix$backupAlias';
    await _storage.write(key: fullAlias, value: _encode(key));
  }

  /// 백업된 키 목록을 조회합니다.
  Future<List<String>> getBackupKeyAliases() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((String key) => key.startsWith(_backupPrefix))
        .map<String>((String key) => key.substring(_backupPrefix.length))
        .toList();
  }

  /// 백업 키를 로드합니다.
  Future<List<int>?> loadBackupKey(String backupAlias) async {
    final fullAlias = '$_backupPrefix$backupAlias';
    final base64 = await _storage.read(key: fullAlias);
    if (base64 == null) {
      return null;
    }
    return _decode(base64);
  }

  /// 오래된 백업 키들을 정리합니다.
  Future<void> cleanupOldBackups({int retainCount = 5}) async {
    final aliases = await getBackupKeyAliases();

    // 타임스탬프 기준으로 정렬 (최신 순)
    aliases.sort((a, b) {
      final timestampA = int.tryParse(a) ?? 0;
      final timestampB = int.tryParse(b) ?? 0;
      return timestampB.compareTo(timestampA);
    });

    // 보관할 개수를 초과하는 백업들 삭제
    if (aliases.length > retainCount) {
      final toDelete = aliases.skip(retainCount);
      for (final alias in toDelete) {
        await deleteOldKey('$_backupPrefix$alias');
      }
    }
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _encode(List<int> bytes) => base64Encode(bytes);
  List<int> _decode(String s) => base64Decode(s);

  /// 전체 데이터베이스 백업을 생성합니다.
  Future<Map<String, dynamic>> _createFullBackup(Isar isar) async {
    final backup = <String, dynamic>{};

    // 각 컬렉션별로 데이터 백업
    backup['vaults'] = await isar.collection<Vault>().where().exportJson();
    backup['folders'] = await isar.collection<Folder>().where().exportJson();
    backup['notes'] = await isar.collection<Note>().where().exportJson();
    backup['pages'] = await isar.collection<Page>().where().exportJson();
    backup['canvasData'] = await isar.collection<CanvasData>().where().exportJson();
    backup['pageSnapshots'] = await isar.collection<PageSnapshot>().where().exportJson();
    backup['linkEntities'] = await isar.collection<LinkEntity>().where().exportJson();
    backup['graphEdges'] = await isar.collection<GraphEdge>().where().exportJson();
    backup['pdfCacheMetas'] = await isar.collection<PdfCacheMeta>().where().exportJson();
    backup['recentTabs'] = await isar.collection<RecentTabs>().where().exportJson();
    backup['settings'] = await isar.collection<SettingsEntity>().where().exportJson();

    return backup;
  }

  /// 백업에서 데이터를 복원합니다.
  Future<void> _restoreFromBackup(Isar isar, Map<String, dynamic> backupData) async {
    await isar.writeTxn(() async {
      // 모든 기존 데이터 삭제
      await isar.clear();

      // 각 컬렉션별로 데이터 복원
      if (backupData['vaults'] != null) {
        await isar.collection<Vault>().importJson(backupData['vaults']);
      }
      if (backupData['folders'] != null) {
        await isar.collection<Folder>().importJson(backupData['folders']);
      }
      if (backupData['notes'] != null) {
        await isar.collection<Note>().importJson(backupData['notes']);
      }
      if (backupData['pages'] != null) {
        await isar.collection<Page>().importJson(backupData['pages']);
      }
      if (backupData['canvasData'] != null) {
        await isar.collection<CanvasData>().importJson(backupData['canvasData']);
      }
      if (backupData['pageSnapshots'] != null) {
        await isar.collection<PageSnapshot>().importJson(backupData['pageSnapshots']);
      }
      if (backupData['linkEntities'] != null) {
        await isar.collection<LinkEntity>().importJson(backupData['linkEntities']);
      }
      if (backupData['graphEdges'] != null) {
        await isar.collection<GraphEdge>().importJson(backupData['graphEdges']);
      }
      if (backupData['pdfCacheMetas'] != null) {
        await isar.collection<PdfCacheMeta>().importJson(backupData['pdfCacheMetas']);
      }
      if (backupData['recentTabs'] != null) {
        await isar.collection<RecentTabs>().importJson(backupData['recentTabs']);
      }
      if (backupData['settings'] != null) {
        await isar.collection<SettingsEntity>().importJson(backupData['settings']);
      }
    });
  }

  /// DB 파일들을 삭제합니다.
  Future<void> _deleteDbFiles() async {
    final isarDb = IsarDb.instance;

    // DB 닫기
    await isarDb.close();

    // DB 파일 경로 찾기
    final dir = await getApplicationDocumentsDirectory();
    final directoryPath = dir.path;

    // DB 파일들 삭제 (Isar는 여러 파일로 구성됨)
    final dbFiles = ['default.isar', 'default.isar.lock'];
    for (final fileName in dbFiles) {
      final file = File('$directoryPath/$fileName');
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
