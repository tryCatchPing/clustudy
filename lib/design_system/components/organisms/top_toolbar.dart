// lib/design_system/components/organisms/top_toolbar.dart
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_icon_button.dart';

enum TopToolbarVariant { landing, folder }

class ToolbarAction {
  const ToolbarAction({
    required this.svgPath,
    required this.onTap,
    this.tooltip,
  });
  final String svgPath;
  final VoidCallback onTap;
  final String? tooltip;
}

class TopToolbar extends StatelessWidget implements PreferredSizeWidget {
  const TopToolbar({
    super.key,
    required this.variant,
    required this.title,
    this.onBack,
    this.backSvgPath,
    this.actions = const [],
    this.iconColor = AppColors.gray50,
    this.height = 76,
    this.iconSize = 32,
  });

  final TopToolbarVariant variant;
  final String title;
  final VoidCallback? onBack;
  final List<ToolbarAction> actions;
  final Color iconColor;
  final double height;
  final double iconSize;
  final String? backSvgPath;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final titleStyle = switch (variant) {
      TopToolbarVariant.landing => AppTypography.title1.copyWith(
        color: AppColors.primary,
      ), // 36 Bold
      TopToolbarVariant.folder => AppTypography.title2.copyWith(
        color: AppColors.gray50,
      ), // 36 Regular
    };

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding, // 30
          right: AppSpacing.screenPadding, // 30
          top: AppSpacing.screenPadding, // 30
        ),
        color: AppColors.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant == TopToolbarVariant.folder &&
                    onBack != null &&
                    backSvgPath != null) ...[
                  AppIconButton(
                    svgPath: backSvgPath!,
                    onPressed: onBack,
                    tooltip: '이전',
                    size: AppIconButtonSize.md,
                    color: iconColor,
                  ),
                  const SizedBox(width: AppSpacing.medium),
            ],

            Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  AppIconButton(
                    svgPath: actions[i].svgPath,
                    onPressed: actions[i].onTap,
                    tooltip: actions[i].tooltip ?? '',
                    size: AppIconButtonSize.md,
                    color: iconColor,
                  ),
                  if (i != actions.length - 1)
                    const SizedBox(width: AppSpacing.medium),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
