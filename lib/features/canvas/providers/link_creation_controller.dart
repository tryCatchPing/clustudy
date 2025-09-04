import 'dart:async';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/note_service.dart';
import '../../notes/data/notes_repository_provider.dart';
import '../../notes/models/note_model.dart';
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

    // 1) 타깃 노트 결정
    NoteModel targetNote;
    if (targetNoteId != null) {
      final found = await notesRepo.getNoteById(targetNoteId);
      if (found == null) {
        throw StateError('Target note not found: $targetNoteId');
      }
      targetNote = found;
      debugPrint(
        '[LinkCreate] resolved existing target noteId=${found.noteId}',
      );
    } else {
      // 제목으로 조회 (대소문자 무시, 정확 일치)
      final currentNotes = await notesRepo.watchNotes().first;
      final normalizedTitle = (targetTitle ?? '').trim().toLowerCase();
      NoteModel? match;
      for (final n in currentNotes) {
        if (n.title.trim().toLowerCase() == normalizedTitle) {
          match = n;
          break;
        }
      }

      if (match != null) {
        targetNote = match;
        debugPrint('[LinkCreate] matched title → noteId=${match.noteId}');
      } else {
        // 없으면 새 노트 생성 (빈 노트, 페이지 1개)
        final created = await NoteService.instance.createBlankNote(
          title: targetTitle?.trim().isEmpty == false
              ? targetTitle!.trim()
              : null,
          initialPageCount: 1,
        );
        if (created == null) {
          throw StateError('Failed to create target note');
        }
        await notesRepo.upsert(created);
        targetNote = created;
        debugPrint('[LinkCreate] created new note noteId=${created.noteId}');
      }
    }

    // 2) 동일 노트 링크 방지
    if (targetNote.noteId == sourceNoteId) {
      debugPrint(
        '[LinkCreate] blocked: self-link attempted to noteId=${targetNote.noteId}',
      );
      throw StateError('동일 노트로는 링크를 생성할 수 없습니다.');
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
}

final linkCreationControllerProvider =
    Provider.autoDispose<LinkCreationController>((ref) {
      return LinkCreationController(ref);
    });
