import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_button.dart';

class CreationBaseSheet extends StatelessWidget {
  const CreationBaseSheet({
    super.key,
    required this.title,
    required this.onBack,
    required this.rightText,
    this.onRightTap,
    required this.child,
    this.heightRatio = 2 / 3,
  });

  final String title;
  final VoidCallback onBack;
  final String rightText;
  final VoidCallback? onRightTap;
  final Widget child;
  final double heightRatio;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height * heightRatio;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: h + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.large,
            bottom: AppSpacing.large + bottomInset,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppIconButton(
                    svgPath: AppIcons.chevronLeft,
                    onPressed: onBack,
                    color: AppColors.background,
                    size: AppIconButtonSize.md,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.subtitle1.copyWith(color: AppColors.background),
                    ),
                  ),
                  AppButton(
                    text: rightText,
                    onPressed: onRightTap,
                    style: AppButtonStyle.secondary,   // 배경: AppColors.background(크림), 글자: primary
                    size: AppButtonSize.md,
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공통 호출 헬퍼
Future<T?> showCreationSheet<T>(BuildContext context, Widget sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}
