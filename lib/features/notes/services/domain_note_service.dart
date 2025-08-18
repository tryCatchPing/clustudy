import 'dart:convert';

import 'package:isar/isar.dart';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';

/// 도메인 서비스: 링크 생성/이동/삭제/복원/RecentTabs/Settings 등 B 트랙 책임 구현
class DomainNoteService {
  DomainNoteService._();
  static final DomainNoteService instance = DomainNoteService._();

  /// 영역 → 새 노트 생성 + Link + GraphEdge 동기화 (트랜잭션)
  ///
  /// 좌표는 이미 정규화되었다고 가정(0..1, x0<x1, y0<y1). B는 변환하지 않음.
  Future<Note> createLinkedNoteFromRegion({
    required int vaultId,
    required int sourceNoteId,
    required int sourcePageId,
    required RectNorm region,
    String? label,
    String pageSize = 'A4',
    String pageOrientation = 'portrait',
    int initialPageIndex = 0,
  }) async {
    // A의 유틸을 사용하여 원자적 파이프라인을 수행
    final link = await NoteDbService.instance.createLinkAndTargetNote(
      vaultId: vaultId,
      sourceNoteId: sourceNoteId,
      sourcePageId: sourcePageId,
      x0: region.x0,
      y0: region.y0,
      x1: region.x1,
      y1: region.y1,
      label: label ?? '새 링크 노트',
      pageSize: pageSize,
      pageOrientation: pageOrientation,
      initialPageIndex: initialPageIndex,
    );
    final isar = await IsarDb.instance.open();
    final note = await isar.collection<Note>().get(link.targetNoteId!);
    if (note == null) {
      throw IsarError('Linked note not found after creation');
    }
    return note;
  }

  /// 노트를 동일 볼트 내 폴더로 이동. vault 간 이동 금지.
  /// [beforeNoteId]가 있으면 그 앞에 오도록 정렬 재배치.
  Future<void> moveNote({
    required int noteId,
    required int targetFolderId,
    int? beforeNoteId,
  }) async {
    final isar = await IsarDb.instance.open();
    int? fromFolderId;
    int? vaultId;
    await isar.writeTxn(() async {
      final note = await isar.collection<Note>().get(noteId);
      if (note == null) return;
      final targetFolder = await isar.collection<Folder>().get(targetFolderId);
      if (targetFolder == null) {
        throw IsarError('Target folder not found');
      }
      if (targetFolder.vaultId != note.vaultId) {
        throw IsarError('Cross-vault move is not allowed');
      }

      // 이동
      fromFolderId = note.folderId;
      vaultId = note.vaultId;
      note.folderId = targetFolderId;

      // 정렬 재배치
      final notesInTarget = await isar.collection<Note>()
          .filter()
          .vaultIdEqualTo(note.vaultId)
          .and()
          .folderIdEqualTo(targetFolderId)
          .and()
          .deletedAtIsNull()
          .sortBySortIndex()
          .findAll();

      int newIndex;
      if (beforeNoteId == null) {
        newIndex = (notesInTarget.isEmpty ? 1000 : (notesInTarget.last.sortIndex + 1000));
      } else {
        final idx = notesInTarget.indexWhere((n) => n.id == beforeNoteId);
        if (idx < 0) {
          newIndex = (notesInTarget.isEmpty ? 1000 : (notesInTarget.last.sortIndex + 1000));
        } else {
          final int beforeIndex = notesInTarget[idx].sortIndex;
          final int prevIndex = idx > 0 ? notesInTarget[idx - 1].sortIndex : (beforeIndex - 1000);
          if (beforeIndex - prevIndex > 1) {
            newIndex = (prevIndex + beforeIndex) ~/ 2;
          } else {
            newIndex = beforeIndex - 1;
          }
        }
      }

      note.sortIndex = newIndex;
      note.updatedAt = DateTime.now();
      await isar.collection<Note>().put(note);
    });

    // 컴팩션은 A 유틸 호출로 트랜잭션 외부에서 수행
    if (vaultId != null) {
      await NoteDbService.instance.compactSortIndexWithinFolder(
        vaultId: vaultId!,
        folderId: targetFolderId,
      );
      if (fromFolderId != targetFolderId) {
        await NoteDbService.instance.compactSortIndexWithinFolder(
          vaultId: vaultId!,
          folderId: fromFolderId,
        );
      }
    }
  }

  /// 소프트 삭제
  Future<void> softDeleteNote(int noteId) async {
    await NoteDbService.instance.softDeleteNote(noteId);
  }

  /// 복원 (원위치 존재하지 않으면 루트로 복원)
  Future<void> restoreNote(int noteId) async {
    await NoteDbService.instance.restoreNote(noteId);
  }

  /// RecentTabs: 링크로 생성된 새 노트 push (LRU 10 유지)
  Future<void> pushRecentTabForNewLinkedNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      await _pushRecentLinkedNote(isar: isar, noteId: noteId);
    });
  }

  /// RecentTabs 상위 10개 노트를 반환 (존재하지 않는 항목은 건너뜀)
  Future<List<Note>> getRecentTabs() async {
    final isar = await IsarDb.instance.open();
    final existing = await isar.collection<RecentTabs>().where().anyId().findFirst();
    if (existing == null) return <Note>[];
    List<int> ids;
    try {
      ids = (jsonDecode(existing.noteIdsJson) as List).map((e) => e as int).toList();
    } catch (_) {
      ids = <int>[];
    }
    final result = <Note>[];
    for (final id in ids) {
      final n = await isar.collection<Note>().get(id);
      if (n != null && n.deletedAt == null) {
        result.add(n);
      }
    }
    return result;
  }

  /// Settings 조회 (A 유틸 위임)
  Future<SettingsEntity> getSettings() async {
    return NoteDbService.instance.getSettings();
  }

  /// Settings 업데이트 (부분 업데이트)
  Future<void> updateSettings({
    bool? encryptionEnabled,
    String? backupDailyAt,
    int? backupRetentionDays,
    int? recycleRetentionDays,
    String? keychainAlias,
  }) async {
    await NoteDbService.instance.updateSettings(
      encryptionEnabled: encryptionEnabled,
      backupDailyAt: backupDailyAt,
      backupRetentionDays: backupRetentionDays,
      recycleRetentionDays: recycleRetentionDays,
      keychainAlias: keychainAlias,
    );
  }

  /// 이름 검색: A가 제공한 인덱스 기반 검색 위임
  Future<List<Note>> searchNotesByName({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 50,
  }) async {
    return NoteDbService.instance.searchNotesByName(
      vaultId: vaultId,
      folderId: folderId,
      query: query,
      limit: limit,
    );
  }

  // ---------- 내부 유틸 ----------

  // A 유틸 사용으로 내부 컴팩션은 제거

  Future<void> _pushRecentLinkedNote({required Isar isar, required int noteId}) async {
    const String userId = 'local';
    final now = DateTime.now();
    final existing = await isar.collection<RecentTabs>().where().anyId().findFirst();
    List<int> list;
    late RecentTabs tabs;
    if (existing == null) {
      list = <int>[noteId];
      tabs = RecentTabs()
        ..userId = userId
        ..noteIdsJson = jsonEncode(list)
        ..updatedAt = now;
    } else {
      tabs = existing;
      try {
        final decoded = jsonDecode(tabs.noteIdsJson);
        list = (decoded as List).map((e) => e as int).toList();
      } catch (_) {
        list = <int>[];
      }
      list.remove(noteId);
      list.insert(0, noteId);
      if (list.length > 10) {
        list = list.sublist(0, 10);
      }
      tabs
        ..noteIdsJson = jsonEncode(list)
        ..updatedAt = now;
    }
    await isar.collection<RecentTabs>().put(tabs);
  }
}
