import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/canvas/providers/link_providers.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/data/notes_repository_provider.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/vaults/data/vault_tree_repository_provider.dart';
import '../../features/vaults/models/folder_model.dart';
import '../../features/vaults/models/note_placement.dart';
import '../../features/vaults/models/vault_item.dart';
import '../../features/vaults/models/vault_model.dart';
import '../repositories/link_repository.dart';
import '../repositories/vault_tree_repository.dart';
import 'db_txn_runner.dart';
import 'file_storage_service.dart';
import 'name_normalizer.dart';
import 'note_service.dart';

/// 노트 검색 결과 모델
class NoteSearchResult {
  final String noteId;
  final String title;
  final String? parentFolderName; // 루트면 '루트'
  const NoteSearchResult({
    required this.noteId,
    required this.title,
    this.parentFolderName,
  });
}

/// 폴더 선택용 정보(경로 라벨 포함)
class FolderInfo {
  final String folderId;
  final String name;
  final String? parentFolderId;
  final String pathLabel;
  const FolderInfo({
    required this.folderId,
    required this.name,
    required this.parentFolderId,
    required this.pathLabel,
  });
}

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
    // 1) 콘텐츠 생성(초기 제목은 name가 있으면 우선 적용)
    String? normalizedName;
    if (name != null && name.trim().isNotEmpty) {
      normalizedName = NameNormalizer.normalize(name);
    }
    final note = await noteService.createBlankNote(
      title: normalizedName,
      initialPageCount: 1,
    );
    if (note == null) {
      throw Exception('Failed to create blank note');
    }

    // 2) 최종 제목 확정(자동 접미사 포함)
    final desired = (normalizedName ?? NameNormalizer.normalize(note.title));
    final existing = await _collectNoteNameKeysInScope(vaultId, parentFolderId);
    final uniqueTitle = _generateUniqueName(desired, existing);
    final materialized = note.copyWith(title: uniqueTitle);

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
    // 1) PDF 처리 및 콘텐츠 생성 (사용자 선택 포함)
    String? normalizedName;
    if (name != null && name.trim().isNotEmpty) {
      normalizedName = NameNormalizer.normalize(name);
    }
    final note = await noteService.createPdfNote(title: normalizedName);
    if (note == null) {
      throw Exception('PDF note creation was cancelled or failed');
    }

    // 2) 최종 제목 확정(자동 접미사 포함)
    final desired = (normalizedName ?? NameNormalizer.normalize(note.title));
    final existing = await _collectNoteNameKeysInScope(vaultId, parentFolderId);
    final uniqueTitle = _generateUniqueName(desired, existing);
    final materialized = note.copyWith(title: uniqueTitle);

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
    // 스코프 수집(동일 부모 폴더의 노트 이름들) 및 자기 이름 제외
    final placement = await getPlacement(noteId);
    if (placement == null) {
      throw Exception('Note not found in vault tree: $noteId');
    }
    final existing = await _collectNoteNameKeysInScope(
      placement.vaultId,
      placement.parentFolderId,
    );
    existing.remove(NameNormalizer.compareKey(placement.name));
    final unique = _generateUniqueName(normalized, existing);
    await dbTxn.write(() async {
      await vaultTree.renameNote(noteId, unique);
      final note = await notesRepo.getNoteById(noteId);
      if (note != null) {
        await notesRepo.upsert(note.copyWith(title: unique));
      }
    });
  }

  /// 폴더 표시명을 변경합니다.
  Future<void> renameFolder(String folderId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    // 금지문자/길이 검증(간단 검증; 세부 정책은 레포가 1차 보장)
    if (normalized.isEmpty || normalized.length > 100) {
      throw const FormatException('이름 길이가 올바르지 않습니다');
    }
    // 소속 vaultId 및 parentFolderId 탐색
    final vaults = await vaultTree.watchVaults().first;
    String? vaultId;
    for (final v in vaults) {
      if (await _containsFolder(v.vaultId, folderId)) {
        vaultId = v.vaultId;
        break;
      }
    }
    if (vaultId == null) {
      throw Exception('Folder not found: $folderId');
    }
    final parentId = await getParentFolderId(vaultId, folderId);
    // 현재 이름을 찾아 자기 제외 후 unique 산출
    final items = await vaultTree
        .watchFolderChildren(vaultId, parentFolderId: parentId)
        .first;
    String? currentName;
    for (final it in items) {
      if (it.type == VaultItemType.folder && it.id == folderId) {
        currentName = it.name;
        break;
      }
    }
    final existing = await _collectFolderNameKeysInScope(vaultId, parentId);
    if (currentName != null) {
      existing.remove(NameNormalizer.compareKey(currentName));
    }
    final unique = _generateUniqueName(normalized, existing);
    await dbTxn.write(() async {
      await vaultTree.renameFolder(folderId, unique);
    });
  }

  /// Vault 이름을 변경합니다(전역 유일).
  Future<void> renameVault(String vaultId, String newName) async {
    final normalized = NameNormalizer.normalize(newName);
    if (normalized.isEmpty || normalized.length > 100) {
      throw const FormatException('이름 길이가 올바르지 않습니다');
    }
    final existing = await _collectVaultNameKeys();
    // 자기 제외
    final current = await vaultTree.getVault(vaultId);
    if (current != null) {
      existing.remove(NameNormalizer.compareKey(current.name));
    }
    final unique = _generateUniqueName(normalized, existing);
    await dbTxn.write(() async {
      await vaultTree.renameVault(vaultId, unique);
    });
  }

  /// 폴더 생성(자동 접미사 적용). UI 연동은 후속.
  Future<FolderModel> createFolder(
    String vaultId, {
    String? parentFolderId,
    required String name,
  }) async {
    final desired = NameNormalizer.normalize(name);
    final existing = await _collectFolderNameKeysInScope(
      vaultId,
      parentFolderId,
    );
    final unique = _generateUniqueName(desired, existing);
    return vaultTree.createFolder(
      vaultId,
      parentFolderId: parentFolderId,
      name: unique,
    );
  }

  /// Vault 생성(자동 접미사 적용). UI 연동은 후속.
  Future<VaultModel> createVault(String name) async {
    final desired = NameNormalizer.normalize(name);
    final existing = await _collectVaultNameKeys();
    final unique = _generateUniqueName(desired, existing);
    // vaultTree.createVault는 내부에서 유일성 재차 검증함
    final v = await vaultTree.createVault(unique);
    return v;
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

  /// Vault 내 노트 검색(케이스/악센트 무시). 기본은 부분 일치, exact=true 시 정확 일치만.
  Future<List<NoteSearchResult>> searchNotesInVault(
    String vaultId,
    String query, {
    bool exact = false,
    int limit = 50,
  }) async {
    final q = NameNormalizer.compareKey(query.trim());
    // BFS: (parentFolderId, parentFolderName)
    final queue = <_FolderCtx>[const _FolderCtx(null, '루트')];
    final results = <_ScoredResult>[];

    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent.id)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          queue.add(_FolderCtx(it.id, it.name));
        } else {
          final title = it.name;
          final key = NameNormalizer.compareKey(title);
          int score;
          if (q.isEmpty) {
            score = 0; // 빈 검색: 정렬만 적용
          } else if (exact) {
            if (key == q) {
              score = 3;
            } else {
              continue;
            }
          } else {
            if (key == q) {
              score = 3;
            } else if (key.startsWith(q)) {
              score = 2;
            } else if (key.contains(q)) {
              score = 1;
            } else {
              continue;
            }
          }
          results.add(
            _ScoredResult(
              score: score,
              result: NoteSearchResult(
                noteId: it.id,
                title: title,
                parentFolderName: parent.name,
              ),
            ),
          );
        }
      }
    }

    // 정렬: 검색어 있을 때는 점수 우선, 없으면 제목 ASC
    if (q.isEmpty) {
      results.sort(
        (a, b) => NameNormalizer.compareKey(
          a.result.title,
        ).compareTo(NameNormalizer.compareKey(b.result.title)),
      );
    } else {
      results.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return NameNormalizer.compareKey(
          a.result.title,
        ).compareTo(NameNormalizer.compareKey(b.result.title));
      });
    }

    final cut = limit > 0 ? results.take(limit) : results;
    return cut.map((e) => e.result).toList(growable: false);
  }

  /// Vault 내 모든 폴더를 경로 라벨과 함께 플랫 리스트로 반환합니다.
  Future<List<FolderInfo>> listFoldersWithPath(String vaultId) async {
    final result = <FolderInfo>[];
    // BFS: (parentFolderId, parentFolderName, pathLabel)
    final queue = <_FolderCtx>[const _FolderCtx(null, '루트')];
    final pathMap = <String?, String>{};
    pathMap[null] = '';
    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      final parentPath = pathMap[parent.id] ?? '';
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent.id)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          final path = parent.id == null
              ? it.name
              : (parentPath.isEmpty ? it.name : '$parentPath/${it.name}');
          result.add(
            FolderInfo(
              folderId: it.id,
              name: it.name,
              parentFolderId: parent.id,
              pathLabel: path,
            ),
          );
          queue.add(_FolderCtx(it.id, it.name));
          pathMap[it.id] = path;
        }
      }
    }
    // 이름 ASC로 정렬(경로 라벨은 표시용)
    result.sort(
      (a, b) => NameNormalizer.compareKey(
        a.name,
      ).compareTo(NameNormalizer.compareKey(b.name)),
    );
    return result;
  }

  /// 특정 폴더의 하위(자기 포함) 폴더 id 집합을 반환합니다.
  Future<Set<String>> listFolderSubtreeIds(
    String vaultId,
    String rootFolderId,
  ) async {
    final ids = <String>{};
    final dq = <String>[rootFolderId];
    while (dq.isNotEmpty) {
      final id = dq.removeAt(0);
      if (!ids.add(id)) continue;
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: id)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) dq.add(it.id);
      }
    }
    return ids;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Helpers
  //////////////////////////////////////////////////////////////////////////////

  /// 동일 스코프에서 이름 충돌 시 자동 접미사를 붙여 가용 이름을 생성합니다.
  String _generateUniqueName(
    String baseName,
    Set<String> existingKeys, {
    int maxLen = 100,
  }) {
    final normalizedBase = NameNormalizer.normalize(baseName);
    final baseKey = NameNormalizer.compareKey(normalizedBase);
    if (!existingKeys.contains(baseKey)) {
      return normalizedBase.length <= maxLen
          ? normalizedBase
          : normalizedBase.substring(0, maxLen);
    }
    int n = 2;
    while (n < 1000) {
      final suffix = ' ($n)';
      final take = maxLen - suffix.length;
      final trunk = take > 0
          ? (normalizedBase.length <= take
                ? normalizedBase
                : normalizedBase.substring(0, take))
          : '';
      final candidate = trunk + suffix;
      final key = NameNormalizer.compareKey(candidate);
      if (!existingKeys.contains(key)) {
        return candidate;
      }
      n += 1;
    }
    throw Exception('Unable to resolve unique name');
  }

  Future<Set<String>> _collectNoteNameKeysInScope(
    String vaultId,
    String? parentFolderId,
  ) async {
    final items = await vaultTree
        .watchFolderChildren(vaultId, parentFolderId: parentFolderId)
        .first;
    final set = <String>{};
    for (final it in items) {
      if (it.type == VaultItemType.note) {
        set.add(NameNormalizer.compareKey(it.name));
      }
    }
    return set;
  }

  Future<Set<String>> _collectFolderNameKeysInScope(
    String vaultId,
    String? parentFolderId,
  ) async {
    final items = await vaultTree
        .watchFolderChildren(vaultId, parentFolderId: parentFolderId)
        .first;
    final set = <String>{};
    for (final it in items) {
      if (it.type == VaultItemType.folder) {
        set.add(NameNormalizer.compareKey(it.name));
      }
    }
    return set;
  }

  Future<Set<String>> _collectVaultNameKeys() async {
    final vaults = await vaultTree.watchVaults().first;
    return vaults.map((v) => NameNormalizer.compareKey(v.name)).toSet();
  }

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

class _FolderCtx {
  final String? id;
  final String? name;
  const _FolderCtx(this.id, this.name);
}

class _ScoredResult {
  final int score;
  final NoteSearchResult result;
  const _ScoredResult({required this.score, required this.result});
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
