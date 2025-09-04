import '../../features/canvas/models/link_model.dart';

/// 링크에 대한 영속성 접근을 추상화하는 Repository 인터페이스.
///
/// UI/상위 레이어는 이 인터페이스만 의존합니다.
/// 실제 저장 방식(메모리, Isar 등)은 교체 가능해야 합니다.
abstract class LinkRepository {
  /// 특정 페이지에서 나가는(Outgoing) 링크 목록을 스트림으로 관찰합니다.
  Stream<List<LinkModel>> watchByPage(String pageId);

  /// 특정 노트로 들어오는(Backlink) 링크 목록을 스트림으로 관찰합니다.
  Stream<List<LinkModel>> watchBacklinksToNote(String noteId);

  /// 링크를 생성합니다.
  Future<void> create(LinkModel link);

  /// 링크를 수정합니다.
  Future<void> update(LinkModel link);

  /// 링크를 삭제합니다.
  Future<void> delete(String linkId);

  /// 리소스 정리용. 스트림 컨트롤러 등 내부 자원을 해제합니다.
  void dispose();
}
