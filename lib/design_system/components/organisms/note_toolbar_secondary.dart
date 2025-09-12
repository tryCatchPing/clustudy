// lib/design_system/components/organisms/note_toolbar_secondary.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../atoms/tool_glow_icon.dart';
import '../../tokens/app_icons.dart';
import '../atoms/app_icon_button.dart';

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
    this.centered = true,
  });

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onPen;
  final VoidCallback onHighlighter;
  final VoidCallback onEraser;
  final VoidCallback onLinkPen;
  final VoidCallback onGraphView;
  final double iconSize;
  final bool centered;

  /// 현재 선택된 펜/하이라이터 색
  final ToolAccent activePenColor;
  final ToolAccent activeHighlighterColor;

  /// 지우개/링크펜 활성 상태
  final bool isEraserOn;
  final bool isLinkPenOn;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolGlowIcon(svgPath: AppIcons.undo, onTap: onUndo),
        const SizedBox(width: 16),
        ToolGlowIcon(svgPath: AppIcons.redo, onTap: onRedo),
        const _Divider(),
        // 펜 (선택 시 하이라이트 색 발광)
        ToolGlowIcon(
          svgPath: AppIcons.pen,
          onTap: onPen,
          accent: activePenColor, // 다색 발광
        ),
        const SizedBox(width: 16),
        ToolGlowIcon(
          svgPath: AppIcons.highlighter,
          onTap: onHighlighter,
          accent: activeHighlighterColor, // 다색 발광
        ),
        const SizedBox(width: 16),
        ToolGlowIcon(
          svgPath: AppIcons.eraser,
          onTap: onEraser,
          glowColor: isEraserOn ? AppColors.primary : null,
          // glowOpacity: 0.48, // 원하면 톤 다운
        ),
        const _Divider(),

        ToolGlowIcon(
          svgPath: AppIcons.linkPen,
          onTap: onLinkPen,
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
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: centered? Center(child: content)
      :content,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 24,
        child: const VerticalDivider(
          width: 0,
          thickness: 1,
          color: AppColors.gray20,
        ),
      ),
    );
  }
}
