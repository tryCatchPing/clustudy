import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:it_contest/features/db/isar/db_schemas.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/pdf_cache/models/pdf_cache_meta_model.dart';
import 'package:it_contest/shared/services/crypto_key_service.dart';

/// Centralized Isar database lifecycle manager.
///
/// Provides a singleton instance to open/close the database and utilities
/// for backup-assisted "encryption" toggling (note: Isar v3 does not support
/// on-disk encryption; we use export/import around re-open to simulate the flow).
class IsarDb {
  IsarDb._internal();

  static final IsarDb _instance = IsarDb._internal();
  /// Singleton instance.
  static IsarDb get instance => _instance;

  Isar? _isar;

  /// Public getter for the Isar instance, primarily for testing.
  Isar get isar {
    if (_isar == null) {
      throw StateError('Isar database has not been opened. Call open() first.');
    }
    return _isar!;
  }

  static String? _testDirectoryOverride;

  /// Overrides the documents directory during tests.
  static void setTestDirectoryOverride(String? path) {
    _testDirectoryOverride = path;
  }

  /// Opens the Isar instance. Parameters are kept for forward-compatibility.
  ///
  /// - [enableEncryption] and [encryptionKey] are currently no-ops on Isar v3.
  Future<Isar> open({bool enableEncryption = false, List<int>? encryptionKey}) async {
    if (_isar != null) {
      return _isar!;
    }

    final String directoryPath;
    if (_testDirectoryOverride != null) {
      directoryPath = _testDirectoryOverride!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      directoryPath = dir.path;
    }

    _isar = await Isar.open(
      allSchemas,
      directory: directoryPath,
      inspector: false,
      // Note: encryptionKey is not supported on this Isar version
    );
    return _isar!;
  }

  /// 암호화 켜기/끄기 토글
  Future<void> toggleEncryption({required bool enable}) async {
    final currentIsar = _isar;
    if (currentIsar == null) {
      throw StateError('Database is not open');
    }

    // 현재 설정 확인
    final settings = await currentIsar.settingsEntitys.where().anyId().findFirst() ?? SettingsEntity()
      ..encryptionEnabled = false
      ..backupDailyAt = '02:00'
      ..backupRetentionDays = 7
      ..recycleRetentionDays = 30;

    if (settings.encryptionEnabled == enable) {
      // 이미 원하는 상태
      return;
    }

    if (enable) {
      // 암호화 활성화
      await _enableEncryption();
    } else {
      // 암호화 비활성화
      await _disableEncryption();
    }

    // 설정 업데이트
    await currentIsar.writeTxn(() async {
      settings.encryptionEnabled = enable;
      await currentIsar.settingsEntitys.put(settings);
    });
  }

  /// 암호화를 활성화합니다
  Future<void> _enableEncryption() async {
    final currentIsar = _isar!;

    // 1. 새 암호화 키 생성 (보관)
    await CryptoKeyService.instance.getOrCreateKey();

    // 2. 현재 데이터 백업
    final backupData = await _createDataBackup(currentIsar);

    // 3. DB 닫기
    await close();

    try {
      // 4. 암호화된 DB로 다시 열기
      await open(enableEncryption: true);

      // 5. 백업 데이터 복원
      await _restoreDataBackup(backupData);
    } catch (e) {
      // 실패 시 원래 DB로 복구
      await open(enableEncryption: false);
      rethrow;
    }
  }

  /// 암호화를 비활성화합니다
  Future<void> _disableEncryption() async {
    // 1. 현재 데이터 백업
    final backupData = await _createDataBackup(_isar!);

    // 2. DB 닫기
    await close();

    try {
      // 3. 암호화 없이 DB 열기
      await open(enableEncryption: false);

      // 4. 백업 데이터 복원
      await _restoreDataBackup(backupData);
    } catch (e) {
      // 실패 시 암호화된 DB로 복구
      await open(enableEncryption: true);
      rethrow;
    }
  }

  /// 데이터 백업을 생성합니다
  Future<Map<String, List<Map<String, dynamic>>>> _createDataBackup(Isar isar) async {
    final backup = <String, List<Map<String, dynamic>>>{};

    // 각 컬렉션별로 데이터를 JSON으로 백업
    backup['vaults'] = await isar.vaults.where().exportJson();
    backup['folders'] = await isar.folders.where().exportJson();
    backup['notes'] = await isar.collection<NoteModel>().where().exportJson();
    backup['pages'] = await isar.pages.where().exportJson();
    backup['canvasData'] = await isar.canvasDatas.where().exportJson();
    backup['pageSnapshots'] = await isar.pageSnapshots.where().exportJson();
    backup['linkEntities'] = await isar.linkEntitys.where().exportJson();
    backup['graphEdges'] = await isar.graphEdges.where().exportJson();
    backup['pdfCacheMetas'] = await isar.collection<PdfCacheMetaModel>().where().exportJson();
    backup['recentTabs'] = await isar.recentTabs.where().exportJson();
    backup['settings'] = await isar.settingsEntitys.where().exportJson();

    return backup;
  }

  /// 백업 데이터를 복원합니다
  Future<void> _restoreDataBackup(Map<String, List<Map<String, dynamic>>> backupData) async {
    final isar = _isar!;

    await isar.writeTxn(() async {
      // 모든 기존 데이터 삭제
      await isar.clear();

      // 각 컬렉션별로 데이터 복원
      if (backupData['vaults'] != null) {
        await isar.vaults.importJson(backupData['vaults']!);
      }
      if (backupData['folders'] != null) {
        await isar.folders.importJson(backupData['folders']!);
      }
      if (backupData['notes'] != null) {
        await isar.collection<NoteModel>().importJson(backupData['notes']!);
      }
      if (backupData['pages'] != null) {
        await isar.pages.importJson(backupData['pages']!);
      }
      if (backupData['canvasData'] != null) {
        await isar.canvasDatas.importJson(backupData['canvasData']!);
      }
      if (backupData['pageSnapshots'] != null) {
        await isar.pageSnapshots.importJson(backupData['pageSnapshots']!);
      }
      if (backupData['linkEntities'] != null) {
        await isar.linkEntitys.importJson(backupData['linkEntities']!);
      }
      if (backupData['graphEdges'] != null) {
        await isar.graphEdges.importJson(backupData['graphEdges']!);
      }
      if (backupData['pdfCacheMetas'] != null) {
        await isar.collection<PdfCacheMetaModel>().importJson(backupData['pdfCacheMetas']!);
      }
      if (backupData['recentTabs'] != null) {
        await isar.recentTabs.importJson(backupData['recentTabs']!);
      }
      if (backupData['settings'] != null) {
        await isar.settingsEntitys.importJson(backupData['settings']!);
      }
    });
  }

  /// 데이터베이스 연결을 닫습니다.
  ///
  /// 이미 닫혀 있으면 아무 작업도 수행하지 않습니다.
  Future<void> close() async {
    final isar = _isar;
    if (isar != null) {
      await isar.close();
      _isar = null;
    }
  }
}
