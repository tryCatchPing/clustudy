import 'dart:async';

import 'package:it_contest/features/notes/data/notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/features/notes/models/thumbnail_metadata.dart';

/// 테스트용 모의 노트 저장소입니다.
class MockNotesRepository implements NotesRepository {
  final Map<String, NoteModel> _notes = {};
  final Map<String, ThumbnailMetadata> _thumbnailMetadata = {};

  /// 오류를 발생시킬지 여부.
  bool shouldThrowError = false;

  /// 노트를 추가합니다.
  void addNote(NoteModel note) {
    _notes[note.noteId] = note;
  }

  /// 모든 데이터를 클리어합니다.
  void clear() {
    _notes.clear();
    _thumbnailMetadata.clear();
  }

  @override
  Stream<List<NoteModel>> watchNotes() {
    if (shouldThrowError) {
      return Stream.error(Exception('Mock repository error'));
    }
    return Stream.value(_notes.values.toList());
  }

  @override
  Stream<NoteModel?> watchNoteById(String noteId) {
    if (shouldThrowError) {
      return Stream.error(Exception('Mock repository error'));
    }
    return Stream.value(_notes[noteId]);
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }
    return _notes[noteId];
  }

  @override
  Future<void> upsert(NoteModel note) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }
    _notes[note.noteId] = note;
  }

  @override
  Future<void> delete(String noteId) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }
    _notes.remove(noteId);
  }

  @override
  Future<void> reorderPages(
    String noteId,
    List<NotePageModel> reorderedPages,
  ) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    final note = _notes[noteId];
    if (note != null) {
      _notes[noteId] = note.copyWith(pages: reorderedPages);
    }
  }

  @override
  Future<void> addPage(
    String noteId,
    NotePageModel newPage, {
    int? insertIndex,
  }) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    final note = _notes[noteId];
    if (note != null) {
      final pages = List<NotePageModel>.from(note.pages);
      if (insertIndex != null &&
          insertIndex >= 0 &&
          insertIndex <= pages.length) {
        pages.insert(insertIndex, newPage);
      } else {
        pages.add(newPage);
      }
      _notes[noteId] = note.copyWith(pages: pages);
    }
  }

  @override
  Future<void> deletePage(String noteId, String pageId) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    final note = _notes[noteId];
    if (note != null) {
      final pages = note.pages.where((p) => p.pageId != pageId).toList();
      _notes[noteId] = note.copyWith(pages: pages);
    }
  }

  @override
  Future<void> batchUpdatePages(
    String noteId,
    List<NotePageModel> pages,
  ) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    final note = _notes[noteId];
    if (note != null) {
      _notes[noteId] = note.copyWith(pages: pages);
    }
  }

  @override
  Future<void> updateThumbnailMetadata(
    String pageId,
    ThumbnailMetadata metadata,
  ) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    _thumbnailMetadata[pageId] = metadata;
  }

  @override
  Future<ThumbnailMetadata?> getThumbnailMetadata(String pageId) async {
    if (shouldThrowError) {
      throw Exception('Mock repository error');
    }

    return _thumbnailMetadata[pageId];
  }

  @override
  void dispose() {
    _notes.clear();
    _thumbnailMetadata.clear();
  }
}
