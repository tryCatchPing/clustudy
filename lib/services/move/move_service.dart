import 'package:isar/isar.dart';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';

/// 이동 제약(노트/폴더) 구현
/// - cross-vault 금지
/// - 정렬 재배치: 간격 삽입, 필요 시 컴팩션 호출
class MoveService {
  MoveService._();
  static final MoveService instance = MoveService._();

  // feature flags (default OFF)
  static const bool featureMoveTreePolicy = false; // 폴더 트리 이동 정책 (스키마 미지원)

  /// 노트를 동일 볼트 내 다른 폴더로 이동.
  /// [beforeNoteId]가 주어지면 해당 노트 앞에 오도록 정렬 인덱스 재배치.
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

      // 대상 폴더 내 정렬 재배치
      final notesInTarget = await isar.collection<Note>()
          .filter()
          .vaultIdEqualTo(note.vaultId)
          .and()
          .folderIdEqualTo(targetFolderId)
          .and()
          .deletedAtIsNull()
          .sortBySortIndex()
          .findAll();

      final int newIndex = _computeSortIndexBetween(
        itemsSorted: notesInTarget,
        beforeId: beforeNoteId,
        step: 1000,
      );

      note.sortIndex = newIndex;
      note.updatedAt = DateTime.now();
      await isar.collection<Note>().put(note);
    });

    // 트랜잭션 외부에서 컴팩션 수행 (필요 시)
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

  /// 폴더 이동/재배치. 현재 스키마에서는 폴더 트리를 지원하지 않으므로
  /// 동일 볼트 루트 레벨에서의 순서 변경만 지원.
  /// [targetParentFolderId]는 트리 정책이 활성화되기 전까지는 무시되며,
  /// cross-vault 검증만 수행.
  Future<void> moveFolder({
    required int folderId,
    required int targetParentFolderId,
    int? beforeFolderId,
  }) async {
    if (featureMoveTreePolicy) {
      // 트리 이동 정책은 스키마(parentId) 도입 이후에만 지원
      throw UnimplementedError('Folder tree move is not supported yet');
    }

    final isar = await IsarDb.instance.open();

    int vaultId;

    await isar.writeTxn(() async {
      final folder = await isar.collection<Folder>().get(folderId);
      if (folder == null) return;
      vaultId = folder.vaultId;

      // beforeFolderId가 주어지면 동일 볼트 검증
      if (beforeFolderId != null) {
        final beforeFolder = await isar.collection<Folder>().get(beforeFolderId);
        if (beforeFolder == null) {
          // 대상이 없으면 append 취급
        } else if (beforeFolder.vaultId != vaultId) {
          throw IsarError('Cross-vault move is not allowed');
        }
      }

      // 볼트 내 폴더 목록(루트 레벨)
      final foldersInVault = await isar.collection<Folder>()
          .filter()
          .vaultIdEqualTo(vaultId)
          .and()
          .deletedAtIsNull()
          .sortBySortIndex()
          .findAll();

      final int newIndex = _computeSortIndexBetween(
        itemsSorted: foldersInVault,
        beforeId: beforeFolderId,
        step: 1000,
      );

      folder.sortIndex = newIndex;
      folder.updatedAt = DateTime.now();
      await isar.collection<Folder>().put(folder);
    });

    // 루트 레벨 폴더 정렬 컴팩션
    // ignore: unnecessary_null_comparison
    if (true) {
      // vaultId는 위 트랜잭션 내에서 초기화 보장
      final folder = await _getFolder(folderId);
      if (folder != null) {
        await NoteDbService.instance.compactFolderSortIndex(
          vaultId: folder.vaultId,
        );
      }
    }
  }

  // ---------- 내부 유틸 ----------

  Future<Folder?> _getFolder(int id) async {
    final isar = await IsarDb.instance.open();
    return isar.collection<Folder>().get(id);
  }

  /// 정렬 인덱스 계산: [beforeId] 앞 위치에 들어가도록 인덱스 산출.
  /// 간격이 없으면 간단히 [beforeIndex - 1]을 사용하고, 후속 컴팩션으로 정규화.
  int _computeSortIndexBetween<T>({
    required List<T> itemsSorted,
    required int? beforeId,
    required int step,
  }) {
    if (itemsSorted.isEmpty) {
      return step; // 첫 아이템은 1000
    }

    // itemsSorted는 Note 또는 Folder를 가정 (둘 다 id, sortIndex 보유)
    int getId(dynamic item) => (item as dynamic).id as int;
    int getSort(dynamic item) => (item as dynamic).sortIndex as int;

    if (beforeId == null) {
      return getSort(itemsSorted.last) + step;
    }

    final int idx = itemsSorted.indexWhere((e) => getId(e) == beforeId);
    if (idx < 0) {
      return getSort(itemsSorted.last) + step;
    }

    final int beforeIndex = getSort(itemsSorted[idx]);
    final int prevIndex = idx > 0 ? getSort(itemsSorted[idx - 1]) : (beforeIndex - step);

    if (beforeIndex - prevIndex > 1) {
      return (prevIndex + beforeIndex) ~/ 2;
    }
    // 간격 소진: 간단히 beforeIndex - 1을 사용하고, 이후 컴팩션으로 정리
    return beforeIndex - 1;
  }
}

// -------- 공용 인터페이스 (동결) --------

Future<void> moveNote({
  required int noteId,
  required int targetFolderId,
  int? beforeNoteId,
}) {
  return MoveService.instance.moveNote(
    noteId: noteId,
    targetFolderId: targetFolderId,
    beforeNoteId: beforeNoteId,
  );
}

Future<void> moveFolder({
  required int folderId,
  required int targetParentFolderId,
  int? beforeFolderId,
}) {
  return MoveService.instance.moveFolder(
    folderId: folderId,
    targetParentFolderId: targetParentFolderId,
    beforeFolderId: beforeFolderId,
  );
}
