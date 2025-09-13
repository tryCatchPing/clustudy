import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/canvas/providers/link_providers.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/data/notes_repository_provider.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/vaults/data/vault_tree_repository_provider.dart';
import '../../features/vaults/models/note_placement.dart';
import '../../features/vaults/models/vault_item.dart';
import '../repositories/link_repository.dart';
import '../repositories/vault_tree_repository.dart';
import 'db_txn_runner.dart';
import 'file_storage_service.dart';
import 'name_normalizer.dart';
import 'note_service.dart';

/// 폴더 삭제 전 영향 범위를 요약합니다.
class FolderCascadeImpact {
  final int folderCount;
  final int noteCount;
  const FolderCascadeImpact({
    required this.folderCount,
    required this.noteCount,
  });
}

/// Vault/Folder/Note 배치 트리와 노트 콘텐츠/링크를 오케스트레이션하는 서비스.
///
/// - 생성/이동/이름변경/삭제를 유스케이스 단위로 일관되게 처리합니다.
/// - 트리의 표시명 정책을 준수하고, 콘텐츠 제목을 미러로 동기화합니다.
class VaultNotesService {
  final VaultTreeRepository vaultTree;
  final NotesRepository notesRepo;
  final LinkRepository linkRepo;
  final NoteService noteService;
  final DbTxnRunner dbTxn;

  VaultNotesService({
    required this.vaultTree,
    required this.notesRepo,
    required this.linkRepo,
    required this.dbTxn,
    NoteService? noteService,
  }) : noteService = noteService ?? NoteService.instance;

  /// 현재 폴더에 빈 노트를 생성합니다(콘텐츠→배치 등록→업서트).
  Future<NoteModel> createBlankInFolder(
    String vaultId, {
    String? parentFolderId,
    String? name,
  }) async {
    // 1) 이름 확정(입력값이 있으면 우선 적용)
    String? normalizedName;
    if (name != null && name.trim().isNotEmpty) {
      normalizedName = NameNormalizer.normalize(name);
    }

    // 2) 콘텐츠 생성
    final note = await noteService.createBlankNote(
      title: normalizedName,
      initialPageCount: 1,
    );
    if (note == null) {
      throw Exception('Failed to create blank note');
    }

    // 제목이 비어있다면 서비스가 생성한 제목을 정규화
    final finalTitle = NameNormalizer.normalize(note.title);
    final materialized = note.copyWith(title: finalTitle);

    try {
      // 3) 트랜잭션: 배치 등록 + 콘텐츠 업서트
      await dbTxn.write(() async {
        await vaultTree.registerExistingNote(
          noteId: materialized.noteId,
          vaultId: vaultId,
          parentFolderId: parentFolderId,
          name: materialized.title,
        );
        await notesRepo.upsert(materialized);
      });
      return materialized;
    } catch (e) {
      // 보상: 배치/콘텐츠 정리 + 파일 정리(최소 영향)
      try {
        await notesRepo.delete(materialized.noteId);
      } catch (_) {}
      try {
        await vaultTree.deleteNote(materialized.noteId);
      } catch (_) {}
      try {
        await FileStorageService.deleteNoteFiles(materialized.noteId);
      } catch (_) {}
      rethrow;
    }
  }

  /// PDF에서 노트를 생성합니다(사전 렌더링/메타 포함).
  Future<NoteModel> createPdfInFolder(
    String vaultId, {
    String? parentFolderId,
    String? name,
  }) async {
    // 1) 이름 정규화(있다면)
    String? normalizedName;
    if (name != null && name.trim().isNotEmpty) {
      normalizedName = NameNormalizer.normalize(name);
    }

    // 2) PDF 처리 및 콘텐츠 생성 (사용자 선택 포함)
    final note = await noteService.createPdfNote(title: normalizedName);
    if (note == null) {
      throw Exception('PDF note creation was cancelled or failed');
    }

    // 3) 제목 정규화 확정
    final finalTitle = NameNormalizer.normalize(note.title);
    final materialized = note.copyWith(title: finalTitle);

    try {
      // 4) 트랜잭션: 배치 등록 + 콘텐츠 업서트
      await dbTxn.write(() async {
        await vaultTree.registerExistingNote(
          noteId: materialized.noteId,
          vaultId: vaultId,
          parentFolderId: parentFolderId,
          name: materialized.title,
        );
        await notesRepo.upsert(materialized);
      });
      return materialized;
    } catch (e) {
      // 보상: 콘텐츠/배치/파일 정리
      try {
        await notesRepo.delete(materialized.noteId);
      } catch (_) {}
      try {
        await vaultTree.deleteNote(materialized.noteId);
      } catch (_) {}
      try {
        await FileStorageService.deleteNoteFiles(materialized.noteId);
      } catch (_) {}
      rethrow;
    }
  }

  /// 노트 표시명을 변경하고 콘텐츠 제목을 동기화합니다.
  Future<void> renameNote(String noteId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    await dbTxn.write(() async {
      await vaultTree.renameNote(noteId, normalized);
      final note = await notesRepo.getNoteById(noteId);
      if (note != null) {
        await notesRepo.upsert(note.copyWith(title: normalized));
      }
    });
  }

  /// 노트를 동일 Vault 내 다른 폴더로 이동합니다.
  Future<void> moveNote(String noteId, {String? newParentFolderId}) async {
    await dbTxn.write(() async {
      await vaultTree.moveNote(
        noteId: noteId,
        newParentFolderId: newParentFolderId,
      );
    });
  }

  /// 노트를 완전히 제거합니다(링크/파일/콘텐츠/배치 순).
  Future<void> deleteNote(String noteId) async {
    // 1) 노트 조회(있으면 페이지 기반 링크 정리 준비)
    final note = await notesRepo.getNoteById(noteId);
    final pageIds =
        note?.pages.map((p) => p.pageId).toList() ?? const <String>[];

    // 2) DB 변경(링크/콘텐츠/배치) — 트랜잭션으로 묶기
    await dbTxn.write(() async {
      if (pageIds.isNotEmpty) {
        await linkRepo.deleteBySourcePages(pageIds);
      }
      await linkRepo.deleteByTargetNote(noteId);
      await notesRepo.delete(noteId);
      await vaultTree.deleteNote(noteId);
    });

    // 3) 파일 삭제(트랜잭션 밖)
    await FileStorageService.deleteNoteFiles(noteId);
  }

  /// 폴더 하위(자기 포함)의 폴더/노트 영향 범위를 계산합니다.
  Future<FolderCascadeImpact> computeFolderCascadeImpact(
    String vaultId,
    String folderId,
  ) async {
    int folderCount = 0;
    int noteCount = 0;
    final queue = <String>[folderId];
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!seen.add(current)) continue;
      folderCount += 1; // include current folder
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: current)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          queue.add(it.id);
        } else {
          noteCount += 1;
        }
      }
    }
    return FolderCascadeImpact(folderCount: folderCount, noteCount: noteCount);
  }

  /// 폴더와 그 하위 모든 노트/폴더를 안전하게 삭제합니다.
  Future<void> deleteFolderCascade(String folderId) async {
    // 폴더가 속한 vaultId 탐색
    final vaults = await vaultTree.watchVaults().first;
    String? targetVaultId;
    for (final v in vaults) {
      final found = await _containsFolder(v.vaultId, folderId);
      if (found) {
        targetVaultId = v.vaultId;
        break;
      }
    }
    if (targetVaultId == null) {
      // 폴더를 찾을 수 없으면 조용히 반환(idempotent)
      return;
    }

    // 삭제 대상 노트 수집(DFS 스트리밍)
    final noteIds = await _collectNotesRecursively(targetVaultId, folderId);

    // 노트 삭제 반복
    for (final id in noteIds) {
      try {
        await deleteNote(id);
      } catch (e) {
        debugPrint('deleteFolderCascade: failed to delete note=$id error=$e');
      }
    }

    // 폴더 삭제(트리 캐스케이드)
    await vaultTree.deleteFolder(folderId);
  }

  /// 현재 폴더의 상위 폴더 id를 반환합니다(null이면 루트).
  Future<String?> getParentFolderId(String vaultId, String folderId) async {
    final queue = <String?>[null];
    final seen = <String?>{};
    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      if (!seen.add(parent)) continue;
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          if (it.id == folderId) return parent; // found
          queue.add(it.id);
        }
      }
    }
    return null;
  }

  /// 배치 컨텍스트 조회.
  Future<NotePlacement?> getPlacement(String noteId) {
    return vaultTree.getNotePlacement(noteId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Helpers
  //////////////////////////////////////////////////////////////////////////////

  Future<bool> _containsFolder(String vaultId, String folderId) async {
    // BFS from root to see whether folderId appears in this vault
    final queue = <String?>[null];
    final seen = <String?>{};
    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      if (!seen.add(parent)) continue;
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          if (it.id == folderId) return true;
          queue.add(it.id);
        }
      }
    }
    return false;
  }

  Future<List<String>> _collectNotesRecursively(
    String vaultId,
    String startFolderId,
  ) async {
    final noteIds = <String>[];
    final queue = <String?>[startFolderId];
    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          queue.add(it.id);
        } else {
          noteIds.add(it.id);
        }
      }
    }
    return noteIds;
  }
}

/// VaultNotesService DI 지점.
final vaultNotesServiceProvider = Provider<VaultNotesService>((ref) {
  final vaultTree = ref.watch(vaultTreeRepositoryProvider);
  final notesRepo = ref.watch(notesRepositoryProvider);
  final linkRepo = ref.watch(linkRepositoryProvider);
  final dbTxn = ref.watch(dbTxnRunnerProvider);
  return VaultNotesService(
    vaultTree: vaultTree,
    notesRepo: notesRepo,
    linkRepo: linkRepo,
    dbTxn: dbTxn,
  );
});
