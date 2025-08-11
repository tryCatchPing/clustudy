import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../notes/models/note_page_model.dart' as page_model;

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
      page!.updateFromSketch(currentSketch);
    }
  }
}
