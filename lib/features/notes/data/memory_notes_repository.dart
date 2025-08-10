import 'dart:async';

import '../models/note_model.dart';
import 'fake_notes.dart';
import 'notes_repository.dart';

/// 간단한 인메모리 구현.
///
/// - 앱 기동 중 메모리에만 저장되며 종료 시 데이터는 사라집니다.
/// - 초기 데이터로 `fakeNotes`를 사용합니다(점진적 제거 예정).
class MemoryNotesRepository implements NotesRepository {
  final StreamController<List<NoteModel>> _controller;

  /// 내부 저장소. deep copy 없이 모델 참조를 사용하므로
  /// 외부에서 변경하지 않도록 주의해야 합니다(실무에선 immutable 권장).
  final List<NoteModel> _notes = List<NoteModel>.from(fakeNotes);

  MemoryNotesRepository()
    : _controller = StreamController<List<NoteModel>>.broadcast();

  void _emit() {
    // 방어적 복사로 외부 변이 방지
    _controller.add(List<NoteModel>.from(_notes));
  }

  @override
  Stream<List<NoteModel>> watchNotes() {
    // 새 구독자에게도 현재 스냅샷을 보장하기 위해 호출 시점에 1회 발행
    _emit();
    return _controller.stream;
  }

  @override
  Stream<NoteModel?> watchNoteById(String noteId) {
    // 전체 스트림에서 map하여 단일 노트로 변환
    _emit();
    return _controller.stream.map((notes) {
      final index = notes.indexWhere((n) => n.noteId == noteId);
      return index >= 0 ? notes[index] : null;
    });
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async {
    final index = _notes.indexWhere((n) => n.noteId == noteId);
    return index >= 0 ? _notes[index] : null;
  }

  @override
  Future<void> upsert(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.noteId == note.noteId);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _emit();
  }

  @override
  Future<void> delete(String noteId) async {
    _notes.removeWhere((n) => n.noteId == noteId);
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
