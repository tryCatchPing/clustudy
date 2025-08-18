// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:it_contest/features/notes/data/notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';

/// 간단한 인메모리 구현.
///
/// - 앱 기동 중 메모리에만 저장되며 종료 시 데이터는 사라집니다.
/// - 초기 데이터는 없습니다. UI에서 생성/가져오기 흐름으로 채워집니다.
/// - fakeNotes 사용 중단. 더 이상 사용되지 않습니다.
class MemoryNotesRepository implements NotesRepository {
  final StreamController<List<NoteModel>> _controller;

  /// 내부 저장소. deep copy 없이 모델 참조를 사용하므로
  /// 외부에서 변경하지 않도록 주의해야 합니다(실무에선 immutable 권장).
  final List<NoteModel> _notes = <NoteModel>[];

  MemoryNotesRepository() : _controller = StreamController<List<NoteModel>>.broadcast();

  void _emit() {
    // 방어적 복사로 외부 변이 방지
    _controller.add(List<NoteModel>.from(_notes));
  }

  @override
  Stream<List<NoteModel>> watchNotes() async* {
    // 각 구독자에게 최초 스냅샷을 즉시 전달
    yield List<NoteModel>.from(_notes);

    // 이후 변경 사항을 계속 전달
    yield* _controller.stream;
  }

  @override
  Stream<NoteModel?> watchNoteById(String noteId) async* {
    // 1. 최초 스냅샷 즉시 전달
    final index = _notes.indexWhere((n) => n.noteId == noteId);
    // `_notes` 리스트 전체에서 요청한 ID의 노트를 즉시 전달
    yield index >= 0 ? _notes[index] : null;

    // 2. 이후 _controller.stream 에서 변경사항이 올 때 마다 단일 노트만 걸러서 보내줌
    yield* _controller.stream.map((notes) {
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
