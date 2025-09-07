// lib/design_system/components/atoms/app_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

enum AppTextFieldStyle { search, underline, none }
enum AppTextFieldSize  { sm, md, lg }

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final AppTextFieldStyle style;
  final AppTextFieldSize size;

  /// (underline/none에서만 사용) 텍스트 스타일 직접 지정
  final TextStyle? textStyle;

  /// (search/textIcon에서 사용)
  final String? svgPrefixIconPath; // e.g. 'assets/icons/search.svg'
  final String? svgClearIconPath;  // e.g. 'assets/icons/close.svg'

  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final double? width; // underline 전용 고정폭 옵션 (없으면 부모 제약)

  const AppTextField({
    super.key,
    required this.controller,
    required this.style,
    this.hintText,
    this.textStyle,
    this.onSubmitted,
    this.onChanged,
    this.size = AppTextFieldSize.md,
    this.enabled = true,
    this.width,
  })  : svgPrefixIconPath = null,
        svgClearIconPath = null;

  const AppTextField.search({
    super.key,
    required this.controller,
    this.hintText,
    this.svgPrefixIconPath,
    this.svgClearIconPath,
    this.onSubmitted,
    this.onChanged,
    this.size = AppTextFieldSize.md,
    this.enabled = true,
  })  : style = AppTextFieldStyle.search,
        textStyle = null,
        width = null;

  @override
  Widget build(BuildContext context) {
    final field = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final _style = _resolveTextStyle();
        final _decoration = _buildDecoration(value);

        final textField = TextField(
          controller: controller,
          enabled: enabled,
          style: _style,
          decoration: _decoration,
          cursorColor: AppColors.primary,
          textAlign: style == AppTextFieldStyle.underline ? TextAlign.center : TextAlign.start,
          maxLines: style == AppTextFieldStyle.search ? 1 : null,
          textInputAction: style == AppTextFieldStyle.search ? TextInputAction.search : TextInputAction.done,
          keyboardType: TextInputType.text,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
        );

        if (style == AppTextFieldStyle.underline && width != null) {
          return SizedBox(width: width, child: textField);
        }
        return textField;
      },
    );

    return field;
  }

  // ===== helpers =====
  TextStyle _resolveTextStyle() {
    switch (style) {
      case AppTextFieldStyle.search:
        return AppTypography.body3.copyWith(color: AppColors.gray50, height: AppTypography.body3.height);
      case AppTextFieldStyle.underline:
      case AppTextFieldStyle.none:
        return (textStyle ?? AppTypography.body3).copyWith(height: (textStyle?.height ?? AppTypography.body3.height));
    }
  }

  InputDecoration _buildDecoration(TextEditingValue value) {
    final iconSize = switch (size) {
      AppTextFieldSize.sm => 18.0,
      AppTextFieldSize.md => 20.0,
      AppTextFieldSize.lg => 24.0,
    };

    final contentPadding = switch (style) {
      AppTextFieldStyle.search =>
        const EdgeInsets.symmetric(vertical: AppSpacing.medium, horizontal: AppSpacing.small),
      AppTextFieldStyle.underline =>
        const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      AppTextFieldStyle.none =>
        EdgeInsets.zero,
    };

    final borderRadius = BorderRadius.circular(
      switch (size) {
        AppTextFieldSize.sm => 6.0,
        AppTextFieldSize.md => AppSpacing.small, // 8
        AppTextFieldSize.lg => 12.0,
      },
    );

    switch (style) {
      case AppTextFieldStyle.search:
        return InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.gray10,
          contentPadding: contentPadding,
          hintText: hintText,
          hintStyle: AppTypography.body3.copyWith(color: AppColors.gray40),
          prefixIcon: svgPrefixIconPath != null
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SvgPicture.asset(
                    svgPrefixIconPath!,
                    width: iconSize, height: iconSize,
                    colorFilter: const ColorFilter.mode(AppColors.gray40, BlendMode.srcIn),
                  ),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

          suffixIcon: (value.text.isNotEmpty && svgClearIconPath != null)
              ? IconButton(
                  splashRadius: 18,
                  padding: const EdgeInsets.all(12.0),
                  icon: SvgPicture.asset(
                    svgClearIconPath!,
                    width: iconSize, height: iconSize,
                    colorFilter: const ColorFilter.mode(AppColors.gray40, BlendMode.srcIn),
                  ),
                  onPressed: controller.clear,
                  tooltip: '지우기',
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        );

      case AppTextFieldStyle.underline:
        return InputDecoration(
          isDense: true,
          isCollapsed: true, // 정확한 수직 높이
          contentPadding: contentPadding,
          hintText: hintText,
          hintStyle: (textStyle ?? AppTypography.body3).copyWith(color: AppColors.gray30),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.background, width: 1.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.background, width: 1.5),
          ),
        );

      case AppTextFieldStyle.none:
        return const InputDecoration(
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        );
    }
  }
}
