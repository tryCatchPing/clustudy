import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/tool_mode.dart';

part 'tool_settings_provider.g.dart';

class ToolSettings {
  final ToolMode toolMode;

  final Color pencolor;
  final double penWidth;

  final Color highlighterColor;
  final double highlighterWidth;

  final double eraserWidth;

  final Color linkerColor;

  const ToolSettings({
    required this.toolMode,
    required this.pencolor,
    required this.penWidth,
    required this.highlighterColor,
    required this.highlighterWidth,
    required this.eraserWidth,
    required this.linkerColor,
  });

  ToolSettings copyWith({
    ToolMode? toolMode,
    Color? pencolor,
    double? penWidth,
    Color? highlighterColor,
    double? highlighterWidth,
    double? eraserWidth,
    Color? linkerColor,
  }) => ToolSettings(
    toolMode: toolMode ?? this.toolMode,
    pencolor: pencolor ?? this.pencolor,
    penWidth: penWidth ?? this.penWidth,
    highlighterColor: highlighterColor ?? this.highlighterColor,
    highlighterWidth: highlighterWidth ?? this.highlighterWidth,
    eraserWidth: eraserWidth ?? this.eraserWidth,
    linkerColor: linkerColor ?? this.linkerColor,
  );

  Color get currentColor {
    switch (toolMode) {
      case ToolMode.pen:
        return pencolor;
      case ToolMode.highlighter:
        return highlighterColor;
      case ToolMode.eraser:
        // 지우개는 색상이 없는데
        return Colors.transparent;
      case ToolMode.linker:
        return linkerColor;
    }
  }

  double get currentWidth {
    switch (toolMode) {
      case ToolMode.pen:
        return penWidth;
      case ToolMode.highlighter:
        return highlighterWidth;
      case ToolMode.eraser:
        return eraserWidth;
      case ToolMode.linker:
        // TODO(xodnd): 링커 모드 굵기 존재?
        return 0;
    }
  }
}

@riverpod
class ToolSettingsNotifier extends _$ToolSettingsNotifier {
  @override
  ToolSettings build(String noteId) => ToolSettings(
    toolMode: ToolMode.pen,
    pencolor: ToolMode.pen.defaultColor,
    penWidth: ToolMode.pen.defaultWidth,
    highlighterColor: ToolMode.highlighter.defaultColor,
    highlighterWidth: ToolMode.highlighter.defaultWidth,
    eraserWidth: ToolMode.eraser.defaultWidth,
    linkerColor: ToolMode.linker.defaultColor,
  );

  void setToolMode(ToolMode toolMode) =>
      state = state.copyWith(toolMode: toolMode);
  void setPenColor(Color penColor) =>
      state = state.copyWith(pencolor: penColor);
  void setPenWidth(double penWidth) =>
      state = state.copyWith(penWidth: penWidth);
  void setHighlighterColor(Color highlighterColor) =>
      state = state.copyWith(highlighterColor: highlighterColor);
  void setHighlighterWidth(double highlighterWidth) =>
      state = state.copyWith(highlighterWidth: highlighterWidth);
  void setEraserWidth(double eraserWidth) =>
      state = state.copyWith(eraserWidth: eraserWidth);
  void setLinkerColor(Color linkerColor) =>
      state = state.copyWith(linkerColor: linkerColor);
}
