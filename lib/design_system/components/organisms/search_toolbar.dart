import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_textfield.dart';
import '../atoms/app_button.dart';

class SearchToolbar extends StatelessWidget implements PreferredSizeWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onDone,
    required this.backSvgPath,
    required this.searchSvgPath,
    required this.clearSvgPath,
    this.height = 76,                 // 상단 30 포함
    this.iconSize = 32,               // 아이콘 32px
    this.iconColor = AppColors.gray50,
    this.autofocus = true,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;

  // 좌측/우측 액션
  final VoidCallback onBack;
  final VoidCallback onDone;

  // 아이콘 경로
  final String backSvgPath;
  final String searchSvgPath;
  final String clearSvgPath;

  // 옵션
  final double height;
  final double iconSize;
  final Color iconColor;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,   // 30
          right: AppSpacing.screenPadding,  // 30
          top: AppSpacing.screenPadding,    // 30
        ),
        color: AppColors.background,
        child: Row(
          children: [
            // 1) 왼쪽 아이콘 버튼(32px, 왼쪽 붙임)
            AppIconButton(
              svgPath: backSvgPath,
              onPressed: onBack,
              tooltip: '이전',
              size: AppIconButtonSize.md,   // md = 32px
              color: iconColor,
            ),

            const SizedBox(width: AppSpacing.medium), // 16

            // 2) 가운데 검색 상자(반응형 확장)
            Expanded(
              child: AppTextField.search(
                controller: controller,
                hintText: '검색',                         // Body/16 Regular
                svgPrefixIconPath: searchSvgPath,        // 버튼 아님
                svgClearIconPath: clearSvgPath,          // 누르면 clear
                autofocus: autofocus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),

            const SizedBox(width: AppSpacing.medium), // 16

            // 3) 오른쪽 '완료' 버튼 (Primary 배경, 텍스트 Subtitle/17 SemiBold)
            AppButton(
              text: '완료',
              onPressed: onDone,
              style: AppButtonStyle.primary, // 배경 = primary
              // (텍스트 색상을 AppColors.background로 쓰고 싶으면
              //  AppButton에 labelColor 옵션을 하나 추가하는 걸 권장)
            ),
          ],
        ),
      ),
    );
  }
}
