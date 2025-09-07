import 'dart:async';

import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../models/thumbnail_metadata.dart';

/// 노트에 대한 영속성 접근을 추상화하는 Repository 인터페이스.
///
/// - UI/상위 레이어는 이 인터페이스만 의존합니다.
/// - 실제 저장 방식(메모리, Isar, 테스트 더블 등)은 교체 가능해야 합니다.
/// - 읽기(관찰)/단건 조회/쓰기(upsert)/삭제를 명확히 분리합니다.
abstract class NotesRepository {
  /// 전체 노트 목록을 스트림으로 관찰합니다.
  ///
  /// 화면/리스트는 이 스트림을 구독해 실시간으로 변경을 반영합니다.
  Stream<List<NoteModel>> watchNotes();

  /// 특정 노트를 스트림으로 관찰합니다.
  ///
  /// 노트가 존재하지 않으면 `null`을 내보냅니다.
  Stream<NoteModel?> watchNoteById(String noteId);

  /// 특정 노트를 단건 조회합니다.
  ///
  /// 존재하지 않으면 `null`을 반환합니다.
  Future<NoteModel?> getNoteById(String noteId);

  /// 노트를 생성하거나 업데이트합니다.
  ///
  /// 동일한 `noteId`가 존재하면 교체(업데이트)하고, 없으면 추가합니다.
  Future<void> upsert(NoteModel note);

  /// 노트를 삭제합니다. 대상이 없어도 에러로 간주하지 않습니다(idempotent).
  Future<void> delete(String noteId);

  // 페이지 컨트롤러를 위한 새로운 메서드들

  /// 페이지 순서를 변경합니다 (배치 업데이트).
  ///
  /// [noteId]는 대상 노트의 ID이고, [reorderedPages]는 새로운 순서의 페이지 목록입니다.
  /// 모든 페이지의 pageNumber가 새로운 순서에 맞게 재매핑되어야 합니다.
  Future<void> reorderPages(
    String noteId,
    List<NotePageModel> reorderedPages,
  );

  /// 페이지를 추가합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [newPage]는 추가할 페이지입니다.
  /// [insertIndex]가 지정되면 해당 위치에 삽입하고, 없으면 마지막에 추가합니다.
  Future<void> addPage(
    String noteId,
    NotePageModel newPage, {
    int? insertIndex,
  });

  /// 페이지를 삭제합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [pageId]는 삭제할 페이지의 ID입니다.
  /// 마지막 페이지는 삭제할 수 없습니다.
  Future<void> deletePage(String noteId, String pageId);

  /// 여러 페이지를 배치로 업데이트합니다 (Isar DB 최적화용).
  ///
  /// [noteId]는 대상 노트의 ID이고, [pages]는 업데이트할 페이지 목록입니다.
  /// 현재 메모리 구현에서는 단순히 전체 노트를 업데이트하지만,
  /// 향후 Isar DB에서는 트랜잭션을 활용한 배치 처리로 최적화됩니다.
  Future<void> batchUpdatePages(
    String noteId,
    List<NotePageModel> pages,
  );

  /// 단일 페이지의 스케치(JSON)를 업데이트합니다.
  ///
  /// [noteId]: 대상 노트 ID
  /// [pageId]: 대상 페이지 ID
  /// [json]: 직렬화된 Sketch JSON 문자열
  Future<void> updatePageJson(
    String noteId,
    String pageId,
    String json,
  );

  /// 썸네일 메타데이터를 저장합니다 (향후 Isar DB에서 활용).
  ///
  /// [pageId]는 페이지 ID이고, [metadata]는 저장할 썸네일 메타데이터입니다.
  Future<void> updateThumbnailMetadata(
    String pageId,
    ThumbnailMetadata metadata,
  );

  /// 썸네일 메타데이터를 조회합니다.
  ///
  /// [pageId]는 페이지 ID입니다. 메타데이터가 없으면 null을 반환합니다.
  Future<ThumbnailMetadata?> getThumbnailMetadata(String pageId);

  /// 리소스 정리용(필요한 구현에서만 사용). 사용하지 않으면 빈 구현이면 됩니다.
  void dispose() {}
}
