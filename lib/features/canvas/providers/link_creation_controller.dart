import 'dart:async';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/name_normalizer.dart';
import '../../../shared/services/vault_notes_service.dart';
import '../../notes/data/notes_repository_provider.dart';
import '../../notes/models/note_model.dart';
import '../../vaults/data/vault_tree_repository_provider.dart';
import '../../vaults/models/vault_item.dart';
import '../models/link_model.dart';
import 'link_providers.dart';

/// 링크 생성 오케스트레이션 컨트롤러 (비-코드젠)
class LinkCreationController {
  static const _uuid = Uuid();
  final Ref ref;

  LinkCreationController(this.ref);

  /// 드래그로 생성된 영역과 타깃 정보를 받아 링크를 생성합니다.
  ///
  /// - [sourceNoteId], [sourcePageId]: 링크를 건 출발점
  /// - [rect]: 페이지 로컬 좌표의 사각형
  /// - 타깃 지정은 둘 중 하나로 제공합니다.
  ///   - [targetNoteId] (명시)
  ///   - [targetTitle]: 제목으로 노트 조회, 없으면 새 노트 생성
  Future<LinkModel> createFromRect({
    required String sourceNoteId,
    required String sourcePageId,
    required Rect rect,
    String? targetNoteId,
    String? targetTitle,
    String? label,
    String? anchorText,
  }) async {
    debugPrint(
      '[LinkCreate] start: src=$sourceNoteId/$sourcePageId rect='
      '(${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},'
      '${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)}) '
      'targetNoteId=$targetNoteId targetTitle=$targetTitle',
    );
    // 기본 검증
    if (rect.width.abs() <= 0 || rect.height.abs() <= 0) {
      throw StateError('Invalid rectangle size');
    }

    final notesRepo = ref.read(notesRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final service = ref.read(vaultNotesServiceProvider);
    final vaultTree = ref.read(vaultTreeRepositoryProvider);

    // Resolve source placement and vault context
    final srcPlacement = await service.getPlacement(sourceNoteId);
    if (srcPlacement == null) {
      throw StateError('Source note not found in vault tree: $sourceNoteId');
    }

    // 1) 타깃 노트 결정
    NoteModel targetNote;
    if (targetNoteId != null) {
      // Validate placement and cross‑vault
      final tgtPlacement = await service.getPlacement(targetNoteId);
      if (tgtPlacement == null) {
        throw StateError('Target note not found in vault tree: $targetNoteId');
      }
      if (tgtPlacement.vaultId != srcPlacement.vaultId) {
        throw StateError('다른 vault에는 링크를 생성할 수 없습니다.');
      }
      final found = await notesRepo.getNoteById(targetNoteId);
      if (found == null) {
        throw StateError('Target note content not found: $targetNoteId');
      }
      targetNote = found;
      debugPrint(
        '[LinkCreate] resolved existing target noteId=${found.noteId}',
      );
    } else {
      // 제목으로 조회 (현 vault의 Placement 집합에서 정확 일치, 케이스 비구분)
      final normalizedKey = NameNormalizer.compareKey(
        (targetTitle ?? '').trim(),
      );
      String? matchedNoteId;
      // BFS over folders
      final queue = <String?>[null];
      final seen = <String?>{};
      while (queue.isNotEmpty) {
        final parent = queue.removeAt(0);
        if (!seen.add(parent)) continue;
        final items = await vaultTree
            .watchFolderChildren(srcPlacement.vaultId, parentFolderId: parent)
            .first;
        for (final it in items) {
          if (it.type == VaultItemType.folder) {
            queue.add(it.id);
          } else {
            if (NameNormalizer.compareKey(it.name) == normalizedKey) {
              matchedNoteId = it.id;
              break;
            }
          }
        }
        if (matchedNoteId != null) break;
      }

      if (matchedNoteId != null) {
        final found = await notesRepo.getNoteById(matchedNoteId);
        if (found != null) {
          targetNote = found;
          debugPrint('[LinkCreate] matched title → noteId=${found.noteId}');
        } else {
          // 콘텐츠가 없으면 새로 생성(루트에), 동일 이름 허용 범위는 폴더 단위
          final created = await service.createBlankInFolder(
            srcPlacement.vaultId,
            parentFolderId: null,
            name: targetTitle?.trim().isNotEmpty == true
                ? targetTitle!.trim()
                : null,
          );
          targetNote = created;
          debugPrint('[LinkCreate] created new note noteId=${created.noteId}');
        }
      } else {
        // 없으면 새 노트 생성 (해당 vault 루트)
        final created = await service.createBlankInFolder(
          srcPlacement.vaultId,
          parentFolderId: null,
          name: targetTitle?.trim().isNotEmpty == true
              ? targetTitle!.trim()
              : null,
        );
        targetNote = created;
        debugPrint('[LinkCreate] created new note noteId=${created.noteId}');
      }
    }

    // 2) 동일 노트 링크 방지 (Validation)
    if (targetNote.noteId == sourceNoteId) {
      debugPrint(
        '[LinkCreate] blocked: self-link attempted to noteId=${targetNote.noteId}',
      );
      throw const FormatException('동일 노트로는 링크를 생성할 수 없습니다.');
    }

    // 3) LinkModel 생성 (현재 정책: 페이지 → 노트 링크)
    final normalized = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width.abs(),
      rect.height.abs(),
    );
    final now = DateTime.now();
    final link = LinkModel(
      id: _uuid.v4(),
      sourceNoteId: sourceNoteId,
      sourcePageId: sourcePageId,
      targetNoteId: targetNote.noteId,
      bboxLeft: normalized.left,
      bboxTop: normalized.top,
      bboxWidth: normalized.width,
      bboxHeight: normalized.height,
      label: label ?? targetNote.title,
      anchorText: anchorText,
      createdAt: now,
      updatedAt: now,
    );

    // 4) 저장
    await linkRepo.create(link);
    debugPrint(
      '[LinkCreate] saved link id=${link.id} '
      'src=${link.sourceNoteId}/${link.sourcePageId} tgt=${link.targetNoteId}',
    );
    return link;
  }

  /// 기존 링크의 타깃(노트/라벨)을 수정합니다.
  /// - [link]: 수정할 기존 링크 (id/소스/바운딩 박스 유지)
  /// - 타깃 지정은 둘 중 하나로 제공합니다.
  ///   - [targetNoteId] (명시)
  ///   - [targetTitle] (제목으로 노트 조회, 없으면 새 노트 생성)
  /// - [label]: 지정하면 라벨을 갱신, 미지정이면 기존 라벨 유지
  Future<LinkModel> updateTargetLink(
    LinkModel link, {
    String? targetNoteId,
    String? targetTitle,
    String? label,
  }) async {
    debugPrint(
      '[LinkEdit] start: linkId=${link.id} '
      'src=${link.sourceNoteId}/${link.sourcePageId} '
      'oldTarget=${link.targetNoteId} newTargetId=$targetNoteId newTitle=$targetTitle',
    );

    final notesRepo = ref.read(notesRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final service = ref.read(vaultNotesServiceProvider);
    final vaultTree = ref.read(vaultTreeRepositoryProvider);

    // 1) 타깃 노트 결정 (현 링크의 소스 vault 기준으로 제한)
    // 소스 vault는 link.sourceNoteId의 placement에서 얻음
    final srcPlacement = await service.getPlacement(link.sourceNoteId);
    if (srcPlacement == null) {
      throw StateError(
        'Source note not found in vault tree: ${link.sourceNoteId}',
      );
    }

    NoteModel targetNote;
    if (targetNoteId != null) {
      final tgtPlacement = await service.getPlacement(targetNoteId);
      if (tgtPlacement == null) {
        throw StateError('Target note not found in vault tree: $targetNoteId');
      }
      if (tgtPlacement.vaultId != srcPlacement.vaultId) {
        throw StateError('다른 vault에는 링크를 수정할 수 없습니다.');
      }
      final found = await notesRepo.getNoteById(targetNoteId);
      if (found == null) {
        throw StateError('Target note content not found: $targetNoteId');
      }
      targetNote = found;
    } else {
      final normalizedKey = NameNormalizer.compareKey(
        (targetTitle ?? '').trim(),
      );
      String? matchedNoteId;
      final queue = <String?>[null];
      final seen = <String?>{};
      while (queue.isNotEmpty) {
        final parent = queue.removeAt(0);
        if (!seen.add(parent)) continue;
        final items = await vaultTree
            .watchFolderChildren(srcPlacement.vaultId, parentFolderId: parent)
            .first;
        for (final it in items) {
          if (it.type == VaultItemType.folder) {
            queue.add(it.id);
          } else {
            if (NameNormalizer.compareKey(it.name) == normalizedKey) {
              matchedNoteId = it.id;
              break;
            }
          }
        }
        if (matchedNoteId != null) break;
      }

      if (matchedNoteId != null) {
        final found = await notesRepo.getNoteById(matchedNoteId);
        if (found != null) {
          targetNote = found;
        } else {
          final created = await service.createBlankInFolder(
            srcPlacement.vaultId,
            parentFolderId: null,
            name: targetTitle?.trim().isNotEmpty == true
                ? targetTitle!.trim()
                : null,
          );
          targetNote = created;
        }
      } else {
        final created = await service.createBlankInFolder(
          srcPlacement.vaultId,
          parentFolderId: null,
          name: targetTitle?.trim().isNotEmpty == true
              ? targetTitle!.trim()
              : null,
        );
        targetNote = created;
      }
    }

    // 2) 동일 노트 링크 방지
    if (targetNote.noteId == link.sourceNoteId) {
      debugPrint(
        '[LinkEdit] blocked: self-link attempted to noteId=${targetNote.noteId}',
      );
      throw StateError('동일 노트로는 링크를 수정할 수 없습니다.');
    }

    // 3) 업데이트 모델 생성 (id/소스/바운딩 박스 유지, 타깃/라벨 갱신)
    final updated = link.copyWith(
      targetNoteId: targetNote.noteId,
      label: label ?? targetNote.title,
      updatedAt: DateTime.now(),
    );

    // 4) 저장
    await linkRepo.update(updated);
    debugPrint(
      '[LinkEdit] updated link id=${link.id} '
      'oldTarget=${link.targetNoteId} newTarget=${updated.targetNoteId}',
    );
    return updated;
  }
}

final linkCreationControllerProvider =
    Provider.autoDispose<LinkCreationController>((ref) {
      return LinkCreationController(ref);
    });
