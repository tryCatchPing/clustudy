// lib/design_system/components/atoms/app_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

enum AppButtonType { elevated, text, textIcon }

enum AppButtonLayout { horizontal, vertical }

enum AppButtonStyle { primary, secondary }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  // 공통
  final VoidCallback? onPressed;
  final double? borderRadius;
  final AppButtonType type;
  final AppButtonStyle style;
  final AppButtonSize size;
  final bool fullWidth;
  final bool loading;

  // 라벨
  final String? text;

  // textIcon 전용
  final String? svgIconPath;
  final double? iconGap; // 아이콘-라벨 간격
  final AppButtonLayout layout;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;

  /// 1) Elevated CTA (기본)
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.borderRadius,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
    this.layout = AppButtonLayout.horizontal,
    this.padding,
    this.iconSize,
  }) : type = AppButtonType.elevated,
       svgIconPath = null,
       iconGap = null;

  /// 2) 텍스트 버튼
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.borderRadius,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
    this.layout = AppButtonLayout.horizontal,
    this.padding,
    this.iconSize,
  }) : type = AppButtonType.text,
       svgIconPath = null,
       iconGap = null;

  /// 3) 아이콘 + 텍스트 버튼
  const AppButton.textIcon({
    super.key,
    required this.text,
    required this.svgIconPath,
    this.onPressed,
    this.borderRadius,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.md,
    this.iconGap = 8,
    this.fullWidth = false,
    this.loading = false,
    this.layout = AppButtonLayout.horizontal,
    this.padding,
    this.iconSize,
  }) : type = AppButtonType.textIcon;

  @override
  Widget build(BuildContext context) {
    // 필수 필드 검증
    assert(text != null && text!.isNotEmpty, 'text is required');
    if (type == AppButtonType.textIcon) {
      assert(svgIconPath != null, 'svgIconPath is required for textIcon');
    }

    final child = _buildChild();

    final btn = switch (type) {
      AppButtonType.elevated => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: _elevatedStyle(context),
        child: child,
      ),
      AppButtonType.text => TextButton(
        onPressed: loading ? null : onPressed,
        style: _textStyle(context),
        child: child,
      ),
      AppButtonType.textIcon => TextButton(
        onPressed: loading ? null : onPressed,
        style: _textStyle(context),
        child: child,
      ),
    };

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }

  // ---------------- private: child & styles ----------------

  Widget _buildChild() {
    // 라벨 스타일: 네 스펙 유지
    final labelStyle = (type == AppButtonType.textIcon)
        ? AppTypography
              .caption // 도크 요구: caption
        : AppTypography.subtitle1;

    // 로딩 스피너
    final spinnerSize = switch (size) {
      AppButtonSize.sm => 14.0,
      AppButtonSize.md => 16.0,
      AppButtonSize.lg => 18.0,
    };

    if (loading) {
      return SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // text / elevated
    if (type != AppButtonType.textIcon) {
      return Text(text!, style: labelStyle);
    }

    // textIcon
    final sz =
        iconSize ??
        switch (size) {
          AppButtonSize.sm => 18.0,
          AppButtonSize.md => 20.0,
          AppButtonSize.lg => 24.0,
        };

    Color resolvedFg() {
      final isPrimary = style == AppButtonStyle.primary;
      return switch (type) {
        AppButtonType.elevated =>
          isPrimary ? AppColors.white : AppColors.primary,
        AppButtonType.text => isPrimary ? AppColors.primary : AppColors.gray50,
        AppButtonType.textIcon =>
          isPrimary ? AppColors.primary : AppColors.gray50,
      };
    }

    final fg = resolvedFg();

    final icon = SvgPicture.asset(
      svgIconPath!,
      width: sz,
      height: sz,
      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
    );

    if (layout == AppButtonLayout.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if ((iconGap ?? 0) > 0) SizedBox(height: iconGap),
          Text(text!, style: labelStyle),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: iconGap ?? 8),
        Text(text!, style: labelStyle),
      ],
    );
  }

  ButtonStyle _elevatedStyle(BuildContext context) {
    final isPrimary = style == AppButtonStyle.primary;

    final bg = isPrimary ? AppColors.primary : AppColors.background;
    final fg = isPrimary ? AppColors.white : AppColors.primary;
    final side = isPrimary
        ? BorderSide.none
        : const BorderSide(color: AppColors.primary, width: 1);

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledForegroundColor: AppColors.gray30,
      disabledBackgroundColor: isPrimary ? AppColors.gray20 : AppColors.gray10,
      padding: padding ?? _padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.small),
        side: side,
      ),
      elevation: 0, // 기본은 플랫; 필요하면 size별 0/1/2로 조정
      minimumSize: _minSize, // 터치 타겟 보장
    ).copyWith(
      overlayColor: _overlayColor(fg),
    );
  }

  ButtonStyle _textStyle(BuildContext context) {
    final isPrimary = style == AppButtonStyle.primary;
    final fg = isPrimary ? AppColors.primary : AppColors.gray50;

    return TextButton.styleFrom(
      foregroundColor: fg,
      disabledForegroundColor: AppColors.gray30,
      padding: padding ?? _padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.small),
      ),
      minimumSize: _minSize,
    ).copyWith(
      overlayColor: _overlayColor(fg),
    );
  }

  // 공통: 사이즈 맵
  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.md:
        return AppPadding.button; // 12 x 8 (네 토큰)
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  Size get _minSize {
    switch (size) {
      case AppButtonSize.sm:
        return const Size(
          AppSpacing.touchTargetMd,
          AppSpacing.touchTargetSm,
        ); // 터치 타겟 보장
      case AppButtonSize.md:
        return const Size(48, 40);
      case AppButtonSize.lg:
        return const Size(52, 48);
    }
  }

  WidgetStateProperty<Color?> _overlayColor(Color base) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return base.withOpacity(0.12);
      if (states.contains(WidgetState.hovered)) return base.withOpacity(0.08);
      if (states.contains(WidgetState.focused)) return base.withOpacity(0.12);
      return null;
    });
  }
}
