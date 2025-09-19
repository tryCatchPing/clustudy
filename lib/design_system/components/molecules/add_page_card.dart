// lib/design_system/components/molecules/add_page_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../tokens/app_sizes.dart';
import '../../utils/dashed_border.dart';

class AddPageCard extends StatelessWidget {
  const AddPageCard({
    super.key,
    required this.plusSvgPath,   // 32px SVG
    this.onTap,
  });

  final String plusSvgPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.small);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          width: AppSizes.noteTileW, // 120
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 점선 사각형 88×120 (수직 패딩 없음)
              DashedBorder(
                color: AppColors.gray40,
                strokeWidth: 1,
                dash: 6,
                gap: 4,
                radius: AppSpacing.small, // 8
                child: SizedBox(
                  width: AppSizes.noteThumbW,   // 88
                  height: AppSizes.noteThumbH,  // 120
                  child: Center(
                    child: SvgPicture.asset(
                      plusSvgPath,
                      width: AppSizes.addIcon,   // 32
                      height: AppSizes.addIcon,  // 32
                      semanticsLabel: '새 페이지 추가',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.small), 

              // Body/13 Semibold, Gray50
              Text(
                '새 페이지',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.body4.copyWith(color: AppColors.gray50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
