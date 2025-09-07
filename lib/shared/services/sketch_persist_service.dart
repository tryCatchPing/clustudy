import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/canvas/providers/note_editor_provider.dart';
import '../../features/notes/data/derived_note_providers.dart';
import '../../features/notes/data/notes_repository_provider.dart';

/// Utilities for persisting the current page's sketch via the repository.
class SketchPersistService {
  /// Save the sketch for the current page of the given note.
  static Future<void> saveCurrentPage(WidgetRef ref, String noteId) async {
    final note = ref.read(noteProvider(noteId)).value;
    if (note == null || note.pages.isEmpty) return;

    final index = ref.read(currentPageIndexProvider(noteId));
    if (index < 0 || index >= note.pages.length) return;
    await savePageByIndex(ref, noteId, index);
  }

  /// Save the sketch for a specific page index of the given note.
  static Future<void> savePageByIndex(
    WidgetRef ref,
    String noteId,
    int pageIndex,
  ) async {
    try {
      final note = ref.read(noteProvider(noteId)).value;
      if (note == null || pageIndex < 0 || pageIndex >= note.pages.length) {
        return;
      }
      final page = note.pages[pageIndex];
      final notifier = ref.read(pageNotifierProvider(noteId, pageIndex));

      final sketch = notifier.value.sketch;
      final json = jsonEncode(sketch.toJson());

      debugPrint(
        '💾 [SketchPersist] Saving sketch to repo: '
        'noteId=$noteId pageId=${page.pageId} pageNo=${page.pageNumber} '
        'jsonBytes=${json.length}',
      );

      await ref
          .read(notesRepositoryProvider)
          .updatePageJson(
            noteId,
            page.pageId,
            json,
          );

      debugPrint(
        '✅ [SketchPersist] Saved: noteId=$noteId pageId=${page.pageId}',
      );
    } catch (e, st) {
      debugPrint('⚠️ SketchPersistService.savePageByIndex failed: $e\n$st');
    }
  }
}
