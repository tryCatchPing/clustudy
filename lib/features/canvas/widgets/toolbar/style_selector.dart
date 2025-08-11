import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../models/canvas_color.dart';
import '../../models/tool_mode.dart';
import '../../notifiers/custom_scribble_notifier.dart';
import 'color_button.dart';

/// 스타일 선택기(색상 + 굵기)를 한 곳에서 제공하는 위젯.
///
/// - 펜/하이라이터 색상 팔레트
/// - 현재 도구 기준 굵기 선택
class NoteEditorStyleSelector extends StatelessWidget {
  const NoteEditorStyleSelector({
    required this.notifier,
    super.key,
  });

  final CustomScribbleNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pen colors
        _ColorRow(notifier: notifier, toolMode: ToolMode.pen),
        const VerticalDivider(width: 12),
        // Highlighter colors
        _ColorRow(notifier: notifier, toolMode: ToolMode.highlighter),
        const VerticalDivider(width: 12),
        // Stroke widths (for current tool)
        _StrokeRow(notifier: notifier),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.notifier,
    required this.toolMode,
  });

  final CustomScribbleNotifier notifier;
  final ToolMode toolMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final canvasColor in CanvasColor.all)
          _ColorButton(
            notifier: notifier,
            toolMode: toolMode,
            color: toolMode == ToolMode.highlighter
                ? canvasColor.highlighterColor
                : canvasColor.color,
            tooltip: canvasColor.displayName,
          ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.notifier,
    required this.toolMode,
    required this.color,
    required this.tooltip,
  });

  final CustomScribbleNotifier notifier;
  final ToolMode toolMode;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: NoteEditorColorButton(
          color: color,
          isActive: state is Drawing && state.selectedColor == color.toARGB32(),
          onPressed: () {
            if (notifier.toolMode != toolMode) {
              switch (toolMode) {
                case ToolMode.pen:
                  notifier.setPen();
                case ToolMode.highlighter:
                  notifier.setHighlighter();
                case ToolMode.linker:
                  notifier.setLinker();
                case ToolMode.eraser:
                  return; // 지우개는 색상 변경 없음
              }
            }
            notifier.setColor(color);
          },
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _StrokeRow extends StatelessWidget {
  const _StrokeRow({
    required this.notifier,
  });

  final CustomScribbleNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final width in notifier.toolMode.widths)
            _StrokeButton(
              notifier: notifier,
              width: width,
              state: state,
            ),
        ],
      ),
    );
  }
}

class _StrokeButton extends StatelessWidget {
  const _StrokeButton({
    required this.notifier,
    required this.width,
    required this.state,
  });

  final CustomScribbleNotifier notifier;
  final double width;
  final ScribbleState state;

  @override
  Widget build(BuildContext context) {
    final bool selected = state.selectedWidth == width;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        elevation: selected ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => notifier.setStrokeWidth(width),
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: kThemeAnimationDuration,
            width: width * 2,
            height: width * 2,
            decoration: BoxDecoration(
              color: state.map(
                drawing: (s) => Color(s.selectedColor),
                erasing: (_) => Colors.transparent,
              ),
              border: state.map(
                drawing: (_) => null,
                erasing: (_) => Border.all(width: 1),
              ),
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
      ),
    );
  }
}
