// lib/design_system/components/molecules/add_page_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../utils/dashed_border.dart';

class AddPageCard extends StatelessWidget {
  const AddPageCard({
    super.key,
    required this.plusSvgPath,     // 가운데 + 아이콘(svg)
    this.onTap,
    this.thumbWidth = 88,
    this.thumbHeight = 120,
    this.label = '새 페이지',       // 고정 문구
  });

  final String plusSvgPath;
  final VoidCallback? onTap;
  final double thumbWidth;
  final double thumbHeight;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.small),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small), // 카드 안쪽 여백(8)
          child: DashedBorder(
            color: AppColors.gray40,
            strokeWidth: 1.0,
            dash: 6,
            gap: 4,
            radius: AppSpacing.small, // 8
            child: SizedBox(
              width: thumbWidth,
              height: thumbHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      plusSvgPath,
                      width: 28,
                      height: 28,
                      // SVG 원본 색을 그대로 쓰면 colorFilter 삭제
                      colorFilter: const ColorFilter.mode(AppColors.gray50, BlendMode.srcIn),
                    ),
                    const SizedBox(height: AppSpacing.small), // 아이콘 ↔ 글씨 8px
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body4.copyWith(color: AppColors.gray50), // Body/13 Semibold, Gray50
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
