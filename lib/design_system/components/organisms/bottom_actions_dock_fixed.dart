// lib/design_system/components/organisms/bottom_actions_dock_fixed.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../design_system/components/atoms/app_button.dart';

class DockItem {
  const DockItem({
    required this.label,
    required this.svgPath,
    required this.onTap,
    this.tooltip,
  });

  final String label;       // 예: '폴더 생성'
  final String svgPath;     // 32x32 svg
  final VoidCallback onTap;
  final String? tooltip;
}

class BottomActionsDockFixed extends StatelessWidget {
  const BottomActionsDockFixed({
    super.key,
    required this.items,          // 보통 3개
    this.spacing = 32,            // 버튼 간 간격
    this.width = 240,             // 고정 폭
    this.height = 60,             // 고정 높이
  });

  final List<DockItem> items;
  final double spacing;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.only(
      topLeft: Radius.circular(25),
      topRight: Radius.circular(25),
    );

    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
          color: AppColors.background,                 // 채우기: 배경색
          borderRadius: radius,                        // 좌/우/위 radius=25
          border: const Border(                        // 외곽선: 좌/우/위 only
            top: BorderSide(color: AppColors.primary, width: 1),
            left: BorderSide(color: AppColors.primary, width: 1),
            right: BorderSide(color: AppColors.primary, width: 1),
            // bottom 없음
          ),
      ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              AppButton.textIcon(
                text: items[i].label,
                svgIconPath: items[i].svgPath,
                onPressed: items[i].onTap,
                style: AppButtonStyle.secondary,
                size: AppButtonSize.sm,
                layout: AppButtonLayout.vertical,
                iconSize: 32,
                iconGap: 0,
                padding: EdgeInsets.zero,
              ),
              if (i != items.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
    );
  }
}
