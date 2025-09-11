import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'derived_note_providers.dart';

/// 특정 노트의 제목만 경량으로 제공
final noteTitleProvider = Provider.family<String?, String>((ref, noteId) {
  final noteAsync = ref.watch(noteProvider(noteId));
  return noteAsync.maybeWhen(
    data: (note) => note?.title,
    orElse: () => null,
  );
});
