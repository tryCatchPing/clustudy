// lib/design_system/components/organisms/note_toolbar_secondary.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../atoms/tool_glow_icon.dart';
import '../../tokens/app_icons.dart';
import '../atoms/app_icon_button.dart';
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

  /// 현재 선택된 펜/하이라이터 색
  final ToolAccent activePenColor;
  final ToolAccent activeHighlighterColor;

  /// 지우개/링크펜 활성 상태
  final bool isEraserOn;
  final bool isLinkPenOn;

  final bool showBottomDivider;

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
        ToolGlowIcon(
          svgPath: AppIcons.pen,
          onTap: onPen,
          size: iconSize,
          accent: activePenColor, // 다색 발광
        ),
        const SizedBox(width: 16),

        ToolGlowIcon(
          svgPath: AppIcons.highlighter,
          onTap: onHighlighter,
          size: iconSize,
          accent: activeHighlighterColor, // 다색 발광
        ),
        const SizedBox(width: 16),

        ToolGlowIcon(
          svgPath: AppIcons.eraser,
          onTap: onEraser,
          size: iconSize,
          glowColor: isEraserOn ? AppColors.primary : null,
          // glowOpacity: 0.48, // 원하면 톤 다운
        ),
        _Divider(height: iconSize * 0.75, color: isPill ? AppColors.gray50 : AppColors.gray20),

        ToolGlowIcon(
          svgPath: AppIcons.linkPen,
          onTap: onLinkPen,
          size: iconSize,
          glowColor: isLinkPenOn ? AppColors.primary : null,
        ),
        const SizedBox(width: 16),

        AppIconButton(
          svgPath: AppIcons.graphView,
          onPressed: onGraphView,
          tooltip: '그래프 뷰',
          size: AppIconButtonSize.md,
          color: AppColors.gray50,
        ),
      ],
    );

    final decoration = isPill
        ? BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.gray50, width: 1.5),
          )
        : const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.gray20, width: 1)),
          );

    final padding = isPill
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) // 요구사항
        : const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 15); // 좌우30/상하15

    final child = Container(
      padding: padding,
      decoration: decoration,
      child: Center(child: content),     // 항상 가운데
    );

    // Pill은 화면 중앙에 딱 맞춘 작은 덩어리여서 Center로 감싸서 반환
    return isPill ? Center(child: child) : child;
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
        child: const VerticalDivider(
          width: 0,
          thickness: 1,
          color: AppColors.gray20,
        ),
      ),
    );
  }
}
