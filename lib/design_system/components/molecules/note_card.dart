import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'app_card.dart';

/// 노트/폴더를 표시하는 카드 위젯
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.date,
    required this.onTap,
    this.showActions = true,
    this.onMove,
    this.onRename,
    this.onDelete,
  });

  final String iconPath;
  final String title;
  final DateTime date;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onMove;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            svgIconPath: iconPath,
            title: title,
            date: date,
            onTap: onTap,
          ),
          if (showActions) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onMove != null)
                  CardActionButton(
                    iconPath: AppIcons.move,
                    tooltip: '이동',
                    onPressed: onMove!,
                  ),
                if (onMove != null && (onRename != null || onDelete != null))
                  const SizedBox(width: AppSpacing.small),
                if (onRename != null)
                  CardActionButton(
                    iconPath: AppIcons.rename,
                    tooltip: '이름 변경',
                    onPressed: onRename!,
                  ),
                if (onRename != null && onDelete != null)
                  const SizedBox(width: AppSpacing.small),
                if (onDelete != null)
                  CardActionButton(
                    iconPath: AppIcons.trash,
                    tooltip: '삭제',
                    onPressed: onDelete!,
                    color: AppColors.penRed,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 카드 하단 액션 버튼
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.iconPath,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final String iconPath;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          color ?? AppColors.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}