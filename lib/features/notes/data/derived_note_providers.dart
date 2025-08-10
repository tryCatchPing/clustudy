import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_model.dart';
import 'notes_repository_provider.dart';

// noteId 중심 리펙토링의 중심

/// 노트 전체 목록을 구독하는 스트림 Provider
final notesProvider = StreamProvider<List<NoteModel>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchNotes();
});

/// 특정 노트를 구독하는 스트림 Provider
final noteProvider = StreamProvider.family<NoteModel?, String>((ref, noteId) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchNoteById(noteId);
});

/// 특정 노트를 단건 조회하는 Future Provider(선택 사용)
final noteOnceProvider = FutureProvider.family<NoteModel?, String>((
  ref,
  noteId,
) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getNoteById(noteId);
});
