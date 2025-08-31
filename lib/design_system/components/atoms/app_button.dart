// lib/design_system/components/atoms/app_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

enum AppButtonType { elevated, text, textIcon, iconOnly }

enum AppButtonStyle { primary, secondary }

class AppButton extends StatelessWidget {
  // 공통 속성
  final VoidCallback? onPressed;
  final AppButtonType type;

  // 텍스트 관련 속성
  final String? text;

  // Elevated 버튼 전용 속성
  final AppButtonStyle style;

  // 아이콘 관련 속성
  final String? svgIconPath; // SVG 파일 경로

  /// 1. Primary & Secondary 텍스트 버튼 (ElevatedButton)
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
  }) : type = AppButtonType.elevated,
       svgIconPath = null;

  /// 2. 아이콘만 있는 버튼 (IconButton)
  const AppButton.iconOnly({
    super.key,
    required this.svgIconPath,
    this.onPressed,
  }) : type = AppButtonType.iconOnly,
       text = null,
       style = AppButtonStyle.primary; // 사용되지 않음

  /// 3. 아이콘과 텍스트가 함께 있는 버튼 (TextButton.icon)
  const AppButton.textIcon({
    super.key,
    required this.text,
    required this.svgIconPath,
    this.onPressed,
  }) : type = AppButtonType.textIcon,
       style = AppButtonStyle.primary; // 사용되지 않음

  /// 4. 텍스트만 있는 버튼 (TextButton)
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
  }) : type = AppButtonType.text,
       svgIconPath = null,
       style = AppButtonStyle.primary; // 사용되지 않음

  @override
  Widget build(BuildContext context) {
    // 버튼 타입에 따라 다른 위젯을 반환
    switch (type) {
      case AppButtonType.elevated:
        final backgroundColor = style == AppButtonStyle.primary
            ? AppColors.primary
            : AppColors.background;
        final foregroundColor = style == AppButtonStyle.primary
            ? AppColors.white
            : AppColors.primary;

        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            //boxShadow: [AppShadows.small], // 나중에 그림자 토큰 추가
            padding: AppPadding.button, // 필요시 스타일별 패딩 조절
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.small),
            ),
          ),
          child: Text(text!, style: AppTypography.subtitle1),
        );

      case AppButtonType.iconOnly:
        return IconButton(
          onPressed: onPressed,
          icon: SvgPicture.asset(
            svgIconPath!,
            width: AppSpacing.xl, // 32px
            height: AppSpacing.xl, // 32px
          ),
        );

      case AppButtonType.textIcon:
        return TextButton.icon(
          onPressed: onPressed,
          icon: SvgPicture.asset(
            svgIconPath!,
            width: AppSpacing.xl, // 크기 지정 추가
            height: AppSpacing.xl, // 크기 지정 추가
            colorFilter: const ColorFilter.mode(
              AppColors.gray50,
              BlendMode.srcIn,
            ),
          ),
          label: Text(
            text!,
            style: AppTypography.caption.copyWith(color: AppColors.gray50),
          ),
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: onPressed,
          child: Text(
            text!,
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray50),
          ),
        );
    }
  }
}
