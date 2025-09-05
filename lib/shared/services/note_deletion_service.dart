import 'package:flutter/foundation.dart';

import '../../features/notes/data/notes_repository.dart';
import '../../shared/repositories/link_repository.dart';
import 'file_storage_service.dart';

/// 노트 삭제를 담당하는 서비스
///
/// - 파일 시스템과 영속 저장소(Repository)를 아우르는 삭제 오케스트레이션을 제공합니다.
/// - UI 레이어에서는 이 서비스만 호출하도록 일원화합니다.
class NoteDeletionService {
  NoteDeletionService._();

  /// 노트를 완전히 삭제합니다.
  ///
  /// 순서:
  /// 1) 파일 시스템 정리
  /// 2) 저장소에서 노트 제거
  static Future<bool> deleteNoteCompletely(
    String noteId, {
    required NotesRepository repo,
    required LinkRepository linkRepo,
  }) async {
    try {
      debugPrint('🗑️ [NoteDeletion] 노트 완전 삭제 시작: $noteId');

      // 1. 파일 시스템 정리
      await FileStorageService.deleteNoteFiles(noteId);

      // 2. 링크 정리 (outgoing + incoming)
      final note = await repo.getNoteById(noteId);
      if (note != null) {
        // Outgoing: all pages of this note
        final pageIds = note.pages.map((p) => p.pageId).toList();
        var outCount = 0;
        for (final pid in pageIds) {
          outCount += await linkRepo.deleteBySourcePage(pid);
        }
        debugPrint(
          '🧹 [LinkCascade] Outgoing deleted: $outCount from ${pageIds.length} page(s)',
        );
      }
      // Incoming to this note
      final inCount = await linkRepo.deleteByTargetNote(noteId);
      debugPrint(
        '🧹 [LinkCascade] Incoming deleted: $inCount for note $noteId',
      );

      // 3. 저장소에서 노트 제거
      await repo.delete(noteId);

      debugPrint('✅ [NoteDeletion] 노트 완전 삭제 완료: $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ [NoteDeletion] 노트 삭제 실패: $e');
      return false;
    }
  }
}
