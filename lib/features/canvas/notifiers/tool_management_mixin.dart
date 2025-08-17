import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../models/tool_mode.dart';

/// 도구 관리 기능을 제공하는 Mixin
mixin ToolManagementMixin on ScribbleNotifier {
  /// 현재 도구 모드
  ToolMode get toolMode;

  /// 도구 모드를 설정합니다.
  set toolMode(ToolMode value);

  /// 공통 도구 변경 메서드
  void setTool(ToolMode newToolMode) {
    toolMode = newToolMode;

    if (newToolMode.isDrawingMode) {
      temporaryValue = ScribbleState.drawing(
        sketch: value.sketch,
        selectedColor: newToolMode.defaultColor.toARGB32(),
        selectedWidth: newToolMode.defaultWidth,
        allowedPointersMode: value.allowedPointersMode,
        scaleFactor: value.scaleFactor,
        activePointerIds: value.activePointerIds,
      );
    } else {
      // 지우개 모드
      temporaryValue = ScribbleState.erasing(
        sketch: value.sketch,
        selectedWidth: newToolMode.defaultWidth,
        scaleFactor: value.scaleFactor,
        allowedPointersMode: value.allowedPointersMode,
        activePointerIds: value.activePointerIds,
      );
    }
  }

  /// 펜 모드로 설정합니다.
  void setPen() => setTool(ToolMode.pen);

  /// 하이라이터 모드로 설정합니다.
  void setHighlighter() => setTool(ToolMode.highlighter);

  /// 링커 모드로 설정합니다.
  void setLinker() => setTool(ToolMode.linker);

  /// 지우개 모드로 설정합니다.
  @override
  void setEraser() => setTool(ToolMode.eraser);

  /// 색상을 변경합니다 (히스토리에 추가하지 않음)
  @override
  void setColor(Color color) {
    if (value is Drawing) {
      temporaryValue = (value as Drawing).copyWith(
        selectedColor: color.value,
      );
    }
  }

  /// 선 굵기를 변경합니다 (히스토리에 추가하지 않음)
  @override
  void setStrokeWidth(double width) {
    temporaryValue = value.copyWith(selectedWidth: width);
  }
}
