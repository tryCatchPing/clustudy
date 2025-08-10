import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memory_notes_repository.dart';
import 'notes_repository.dart';

/// 앱 전역에서 사용할 `NotesRepository` Provider.
///
/// - 기본 구현은 `MemoryNotesRepository`이며, 런타임/테스트에서 override 가능.
/// - DI 지점으로 사용되며, 런타임에 교체 가능.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final repo = MemoryNotesRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
