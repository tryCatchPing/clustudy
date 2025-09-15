import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_shadows.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_button.dart';

typedef CreationTap = Future<void> Function();

class CreationAction {
  final String label;
  final String? desc;
  final Widget leading; // 보통 Svg/아이콘
  final CreationTap onTap;
  CreationAction({
    required this.label,
    required this.leading,
    required this.onTap,
    this.desc,
  });
}

class CreationSheet extends StatelessWidget {
  final String title;
  final VoidCallback onBack; // 좌측 아이콘
  final String rightText; // 우측 텍스트 버튼
  final VoidCallback onRightTap;
  final List<CreationAction> actions;

  const CreationSheet({
    super.key,
    required this.title,
    required this.onBack,
    required this.rightText,
    required this.onRightTap,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height * (2 / 3);

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.large,
            bottom: AppSpacing.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 좌 아이콘, 가운데 타이틀, 우 텍스트 버튼
              Row(
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
                      style: AppTypography.subtitle1.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppButton.text(
                    text: rightText,
                    onPressed: onRightTap,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.md,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 액션 영역
              Expanded(
                child: ListView.separated(
                  itemCount: actions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.medium),
                  itemBuilder: (context, i) {
                    final a = actions[i];
                    return InkWell(
                      onTap: () async => a.onTap(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.small,
                        ),
                        child: Row(
                          children: [
                            a.leading,
                            const SizedBox(width: AppSpacing.large),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.label,
                                    style: AppTypography.body1.copyWith(color: AppColors.gray50),
                                  ),
                                  if (a.desc != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      a.desc!,
                                      style: AppTypography.caption.copyWith(color: AppColors.gray40, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.gray40,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공통 호출 헬퍼
Future<T?> showCreationSheet<T>(BuildContext context, CreationSheet sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}
