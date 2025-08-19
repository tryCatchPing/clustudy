import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:it_contest/canvas/canvas_pipeline.dart';
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
      final json = jsonEncode(value.sketch.toJson());
      const version = '1.0'; // Or get from somewhere else

      CanvasPipeline.saveCanvasWithDebouncedSnapshot(
        noteId,
        pageId,
        json,
        version,
      );
    }
  }
}