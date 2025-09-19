// lib/design_system/components/organisms/note_toolbar_secondary.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../atoms/tool_glow_icon.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';

enum NoteToolbarSecondaryVariant { bar, pill }

class NoteToolbarSecondary extends StatelessWidget {
  const NoteToolbarSecondary({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onPen,
    required this.onHighlighter,
    required this.onEraser,
    required this.onLinkPen,
    required this.onGraphView,
    this.activePenColor = ToolAccent.none,
    this.activeHighlighterColor = ToolAccent.none,
    this.isEraserOn = false,
    this.isLinkPenOn = false,
    this.iconSize = 32,
    this.showBottomDivider = true,
    this.variant = NoteToolbarSecondaryVariant.bar,
    this.onPenDoubleTap,
    this.onHighlighterDoubleTap,
    this.penGlowColor,
    this.highlighterGlowColor,
    this.eraserGlowColor,
    this.linkPenGlowColor,
  });

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onPen;
  final VoidCallback onHighlighter;
  final VoidCallback onEraser;
  final VoidCallback onLinkPen;
  final VoidCallback onGraphView;
  final double iconSize;
  final NoteToolbarSecondaryVariant variant;
  final Color? penGlowColor;
  final Color? highlighterGlowColor;

  /// 현재 선택된 펜/하이라이터 색
  final ToolAccent activePenColor;
  final ToolAccent activeHighlighterColor;
  final VoidCallback? onPenDoubleTap;
  final VoidCallback? onHighlighterDoubleTap;

  /// 지우개/링크펜 활성 상태
  final bool isEraserOn;
  final bool isLinkPenOn;

  final bool showBottomDivider;

  final Color? eraserGlowColor;
  final Color? linkPenGlowColor;

  @override
  Widget build(BuildContext context) {
    final isPill = variant == NoteToolbarSecondaryVariant.pill;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolGlowIcon(svgPath: AppIcons.undo, onTap: onUndo, size: iconSize),
        const SizedBox(width: 16),
        ToolGlowIcon(svgPath: AppIcons.redo, onTap: onRedo, size: iconSize),
        _Divider(height: iconSize * 0.75, color: isPill ? AppColors.gray50 : AppColors.gray20),

        // 펜 (선택 시 하이라이트 색 발광)
         GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: onPenDoubleTap,
          child: ToolGlowIcon(
            svgPath: AppIcons.pen,
            onTap: onPen,
            size: iconSize,
            accent: activePenColor,
            glowColor: penGlowColor,
          ),
        ),
        const SizedBox(width: 16),

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: onHighlighterDoubleTap,
          child: ToolGlowIcon(
            svgPath: AppIcons.highlighter,      // ← 하이라이터
            onTap: onHighlighter,
            size: iconSize,
            accent: activeHighlighterColor,
            glowColor: highlighterGlowColor,
          ),
        ),
        const SizedBox(width: 16),

        ToolGlowIcon(
          svgPath: AppIcons.eraser,
          onTap: onEraser,
          size: iconSize,
          glowColor: eraserGlowColor,
          // glowOpacity: 0.48, // 원하면 톤 다운
        ),
        _Divider(height: iconSize * 0.75, color: isPill ? AppColors.gray50 : AppColors.gray20),

        ToolGlowIcon(
          svgPath: AppIcons.linkPen,
          onTap: onLinkPen,
          size: iconSize,
          glowColor: linkPenGlowColor,
        ),
        const SizedBox(width: 16),

        ToolGlowIcon(svgPath: AppIcons.graphView,   onTap: onGraphView,   size: iconSize),
      ],
    );

    final decoration = isPill
        ? BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.gray50, width: 1.5),
          )
        : BoxDecoration(
            color: AppColors.background,
            border: showBottomDivider
              ? const Border(bottom: BorderSide(color: AppColors.gray20, width: 1))
              : null,
          );

    final padding = isPill
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) // 요구사항
        : const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 15); // 좌우30/상하15
    return isPill
        ? Center(child: Container(padding: padding, decoration: decoration, child:  content))
        : Container(padding: padding, decoration: decoration, child: Center(child: content));
  }
}


class _Divider extends StatelessWidget {
  const _Divider({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: height,
        child: VerticalDivider(
          width: 0,
          thickness: 1,
          color: color,
        ),
      ),
    );
  }
}
