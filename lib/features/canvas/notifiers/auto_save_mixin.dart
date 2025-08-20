import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:it_contest/canvas/canvas_pipeline.dart';
import 'package:it_contest/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart' as page_model;
import 'package:scribble/scribble.dart';

/// 자동저장 기능을 제공하는 Mixin
mixin AutoSaveMixin on ScribbleNotifier {
  /// 현재 페이지 정보
  page_model.NotePageModel? get page;

  /// 포인터가 떼어졌을 때 스케치를 저장합니다.
  @override
  void onPointerUp(PointerUpEvent event) {
    super.onPointerUp(event);
    saveSketch();
  }

  /// 스케치를 현재 페이지에 저장합니다.
  void saveSketch() {
    // 멀티페이지 - Page 객체가 있으면 해당 Page에 저장
    if (page != null) {
      final pageId = int.parse(page!.pageId);
      final noteId = int.parse(page!.noteId);
      final currentSketch = value.sketch;

      // 저장 작업을 비동기로 처리하여 UI 블로킹 방지
      _saveSketchAsync(noteId, pageId, currentSketch);
    }
  }

  /// 비동기 저장 메서드
  Future<void> _saveSketchAsync(int noteId, int pageId, Sketch sketch) async {
    try {
      final json = jsonEncode(sketch.toJson());
      const version = '1.0'; // Or get from somewhere else

      // UI와 분리된 스레드에서 저장 처리
      await Future.microtask(() {
        CanvasPipeline.saveCanvasWithDebouncedSnapshot(
          noteId,
          pageId,
          json,
          version,
        );

        // 캐시 업데이트 - 저장 후 캐시를 현재 스케치로 동기화
        CustomScribbleNotifier.updateCacheForPage(pageId, sketch);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AutoSaveMixin: 스케치 저장 실패: $e');
      }
    }
  }
}
