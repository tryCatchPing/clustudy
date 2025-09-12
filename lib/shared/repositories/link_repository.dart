import '../../features/canvas/models/link_model.dart';

/// 링크 영속성에 대한 추상화.
///
/// - UI/상위 레이어는 이 인터페이스에만 의존합니다.
/// - 구현체는 Memory/Isar 등으로 교체 가능해야 합니다.
/// - 모든 변경(create/update/delete/일괄 삭제)은 관련 스트림을 반드시 emit 해야 합니다.
abstract class LinkRepository {
  /// 특정 페이지의 Outgoing 링크 스트림.
  /// 페이지가 삭제되거나 링크가 변경되면 최신 목록을 emit 합니다.
  Stream<List<LinkModel>> watchByPage(String pageId);

  /// 특정 노트로 들어오는 Backlink 스트림.
  /// targetNoteId 기준으로 변화가 있을 때 emit 합니다.
  Stream<List<LinkModel>> watchBacklinksToNote(String noteId);

  /// 단건 생성.
  /// emit: watchByPage(sourcePageId), watchBacklinksToNote(targetNoteId)
  Future<void> create(LinkModel link);

  /// 단건 수정.
  /// emit: old/new sourcePageId & targetNoteId 각각에 대해 영향 반영
  Future<void> update(LinkModel link);

  /// 단건 삭제.
  /// emit: watchByPage(sourcePageId), watchBacklinksToNote(targetNoteId)
  Future<void> delete(String linkId);

  /// 소스 페이지 기준 일괄 삭제.
  /// 반환: 삭제된 링크 수
  /// emit: watchByPage(pageId), 그리고 영향받은 targetNoteId 들에 대해 watchBacklinksToNote
  Future<int> deleteBySourcePage(String pageId);

  /// 타깃 노트 기준 일괄 삭제.
  /// 반환: 삭제된 링크 수
  /// emit: watchBacklinksToNote(noteId), 그리고 영향받은 sourcePageId 들에 대해 watchByPage
  Future<int> deleteByTargetNote(String noteId);

  /// 여러 소스 페이지 기준 일괄 삭제(편의 함수).
  /// 기본 구현은 deleteBySourcePage 반복으로 충분합니다.
  Future<int> deleteBySourcePages(List<String> pageIds) async {
    var total = 0;
    for (final id in pageIds) {
      total += await deleteBySourcePage(id);
    }
    return total;
  }

  /// 여러 소스 페이지 기준으로 현재 링크 목록을 조회합니다(일회성 스냅샷).
  /// 기본 구현은 `watchByPage(id).first` 반복으로 구성됩니다.
  Future<List<LinkModel>> listBySourcePages(List<String> pageIds) async {
    if (pageIds.isEmpty) return const <LinkModel>[];
    final unique = pageIds.toSet();
    final result = <LinkModel>[];
    for (final id in unique) {
      final links = await watchByPage(id).first;
      result.addAll(links);
    }
    return result;
  }

  /// 리소스 정리용. 스트림 컨트롤러 등 내부 자원을 해제합니다.
  void dispose();
}
