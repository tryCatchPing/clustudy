import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/canvas_color.dart';
import '../../models/tool_mode.dart';
import '../../providers/tool_settings_provider.dart';
import 'color_button.dart';

/// 스타일 선택기(색상 + 굵기)를 한 곳에서 제공하는 위젯.
///
/// - 펜/하이라이터 색상 팔레트
/// - 현재 도구 기준 굵기 선택
class NoteEditorStyleSelector extends ConsumerWidget {
  const NoteEditorStyleSelector({
    required this.noteId,
    super.key,
  });

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pen colors
        _ColorRow(noteId: noteId, toolMode: ToolMode.pen),
        const VerticalDivider(width: 12),
        // Highlighter colors
        _ColorRow(noteId: noteId, toolMode: ToolMode.highlighter),
        const VerticalDivider(width: 12),
        // Stroke widths (for current tool)
        _StrokeRow(noteId: noteId),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.noteId,
    required this.toolMode,
  });

  final String noteId;
  final ToolMode toolMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final canvasColor in CanvasColor.all)
          _ColorButton(
            noteId: noteId,
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

class _ColorButton extends ConsumerWidget {
  const _ColorButton({
    required this.color,
    required this.tooltip,
    required this.noteId,
    required this.toolMode,
  });

  final Color color;
  final String tooltip;
  final String noteId;
  final ToolMode toolMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: NoteEditorColorButton(
        color: color,
        isActive: toolSettings.currentColor == color,
        onPressed: () {
          ref
              .read(toolSettingsNotifierProvider(noteId).notifier)
              .setToolMode(
                toolMode,
              );
          if (toolMode == ToolMode.pen) {
            ref
                .read(toolSettingsNotifierProvider(noteId).notifier)
                .setPenColor(color);
          } else if (toolMode == ToolMode.highlighter) {
            ref
                .read(toolSettingsNotifierProvider(noteId).notifier)
                .setHighlighterColor(color);
          }
        },
        tooltip: tooltip,
      ),
    );
  }
}

class _StrokeRow extends ConsumerWidget {
  const _StrokeRow({
    required this.noteId,
  });

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));

    final widths = toolSettings.toolMode.widths;
    final minW = widths.reduce((a, b) => a < b ? a : b);
    final maxW = widths.reduce((a, b) => a > b ? a : b);
    const double minVisual = 10; // px - 최소 표시 지름 (터치 타깃과 구분)
    const double maxVisual = 24; // px - 최대 표시 지름

    double mapToVisual(double w) {
      final range = (maxW - minW).abs() < 1e-6 ? 1.0 : (maxW - minW);
      final t = (w - minW) / range;
      return minVisual + t * (maxVisual - minVisual);
    }

    final bool isEraser = toolSettings.toolMode == ToolMode.eraser;
    final Color fillColor = isEraser
        ? Colors.transparent
        : toolSettings.currentColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final width in widths)
          _StrokeButton(
            noteId: noteId,
            toolMode: toolSettings.toolMode,
            width: width,
            selected: toolSettings.currentWidth == width,
            innerDiameter: mapToVisual(width),
            fillColor: fillColor,
            showInnerBorder: isEraser,
          ),
      ],
    );
  }
}

class _StrokeButton extends ConsumerWidget {
  const _StrokeButton({
    required this.noteId,
    required this.toolMode,
    required this.width,
    required this.selected,
    required this.innerDiameter,
    required this.fillColor,
    required this.showInnerBorder,
  });

  final String noteId;
  final ToolMode toolMode;
  final double width;
  final bool selected;
  final double innerDiameter;
  final Color fillColor;
  final bool showInnerBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double outerDiameter = 36; // 고정 터치 타깃 크기
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        elevation: selected ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            final notifier = ref.read(
              toolSettingsNotifierProvider(noteId).notifier,
            );
            switch (toolMode) {
              case ToolMode.pen:
                notifier.setPenWidth(width);
                break;
              case ToolMode.highlighter:
                notifier.setHighlighterWidth(width);
                break;
              case ToolMode.eraser:
                notifier.setEraserWidth(width);
                break;
              case ToolMode.linker:
                // 링커 굵기 개념이 생기면 여기서 처리
                break;
            }
          },
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: kThemeAnimationDuration,
            width: outerDiameter,
            height: outerDiameter,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: Center(
              child: Container(
                width: innerDiameter,
                height: innerDiameter,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: showInnerBorder ? Border.all(width: 1) : null,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
