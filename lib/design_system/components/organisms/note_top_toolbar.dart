// lib/design_system/components/organisms/note_top_toolbar.dart
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_icon_button.dart';

class ToolbarAction {
  const ToolbarAction({required this.svgPath, required this.onTap, this.tooltip});
  final String svgPath;
  final VoidCallback onTap;
  final String? tooltip;
}

class NoteTopToolbar extends StatelessWidget implements PreferredSizeWidget {
  const NoteTopToolbar({
    super.key,
    required this.title,
    this.leftActions = const [],
    this.rightActions = const [],
    this.iconColor = AppColors.gray50,
    this.iconSize = 28,
    this.height = 62, // 15(top) + 32(icon) + 15(bottom) = 62
    this.titleStyle,
    this.showBottomDivider = true,
  });

  final String title;
  final List<ToolbarAction> leftActions;
  final List<ToolbarAction> rightActions;

  final Color iconColor;
  final double iconSize;
  final double height;
  final TextStyle? titleStyle;          // 기본 스타일은 아래에서 정함
  final bool showBottomDivider;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final ts = titleStyle ??
        AppTypography.subtitle1.copyWith(color: AppColors.gray50); // 스샷처럼 작고 중립 톤

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, // 30
          vertical: 15,                         // ↑↓ 15
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: showBottomDivider
              ? const Border(
                  bottom: BorderSide(color: AppColors.gray20, width: 1),
                )
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 왼쪽 아이콘 그룹
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < leftActions.length; i++) ...[
                    AppIconButton(
                      svgPath: leftActions[i].svgPath,
                      onPressed: leftActions[i].onTap,
                      tooltip: leftActions[i].tooltip,
                      size: AppIconButtonSize.md, // md = 32px 프리셋
                      color: iconColor,
                    ),
                    if (i != leftActions.length - 1)
                      const SizedBox(width: AppSpacing.medium), // 16
                  ],
                ],
              ),
            ),

            // 가운데 제목
            IgnorePointer(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts,
              ),
            ),

            // 오른쪽 아이콘 그룹
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < rightActions.length; i++) ...[
                    AppIconButton(
                      svgPath: rightActions[i].svgPath,
                      onPressed: rightActions[i].onTap,
                      tooltip: rightActions[i].tooltip,
                      size: AppIconButtonSize.md,
                      color: iconColor,
                    ),
                    if (i != rightActions.length - 1)
                      const SizedBox(width: AppSpacing.medium), // 16
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
