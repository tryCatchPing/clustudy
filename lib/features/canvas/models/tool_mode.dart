import 'package:flutter/material.dart';

import 'canvas_color.dart';

/// 캔버스에서 사용되는 도구 모드를 정의합니다.
/// 각 도구는 표시 이름, 사용 가능한 굵기, 기본 굵기, 기본 색상 등의 속성을 가집니다.
enum ToolMode {
  /// 펜 모드
  pen('Pen', [1, 3, 5, 7]),

  /// 지우개 모드
  eraser('Eraser', [3, 5, 7]),

  /// 하이라이터 모드
  highlighter('Highlighter', [10, 20, 30]),

  /// 링커 모드
  linker('Linker', [10, 20, 30]);

  /// [displayName]은 사용자에게 표시할 이름입니다.
  /// [widths]는 해당 도구에서 사용 가능한 굵기 목록입니다.
  const ToolMode(this.displayName, this.widths);

  /// 도구의 표시 이름
  final String displayName;

  /// 도구에서 사용 가능한 굵기 목록
  final List<double> widths;

  /// 각 도구의 기본 굵기 (widths 리스트의 첫 번째 또는 중간 값)
  double get defaultWidth {
    switch (this) {
      case ToolMode.pen:
        return 3.0;
      case ToolMode.eraser:
        return 5.0;
      case ToolMode.highlighter:
        return 20.0;
      case ToolMode.linker:
        return 20.0;
    }
  }

  /// 각 도구의 기본 색상
  Color get defaultColor {
    switch (this) {
      case ToolMode.pen:
        return CanvasColor.defaultColor.color;
      case ToolMode.eraser:
        return Colors.transparent; // 지우개는 색상 없음
      case ToolMode.highlighter:
        return CanvasColor.defaultColor.highlighterColor;
      case ToolMode.linker:
        return Colors.pinkAccent.withAlpha((255 * 0.5).round());
    }
  }

  /// 각 도구가 그리기 모드인지 지우기 모드인지 여부를 반환합니다.
  bool get isDrawingMode => this != ToolMode.eraser;

  /// 현재 도구 모드가 링커 모드인지 여부를 반환합니다.
  bool get isLinker => this == ToolMode.linker;

  /// 이 도구 모드가 InteractiveViewer의 패닝을 비활성화해야 하는 상호작용 모드인지 여부
  bool get disablesInteractiveViewerPan {
    return this == ToolMode.pen ||
        this == ToolMode.eraser ||
        this == ToolMode.highlighter ||
        this == ToolMode.linker;
  }
}
