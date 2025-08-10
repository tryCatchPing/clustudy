import 'dart:async';

import '../models/note_model.dart';

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

  /// 리소스 정리용(필요한 구현에서만 사용). 사용하지 않으면 빈 구현이면 됩니다.
  void dispose() {}
}
