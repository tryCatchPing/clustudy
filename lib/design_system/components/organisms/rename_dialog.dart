// lib/design_system/components/overlays/rename_dialog.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_button.dart';
import '../atoms/app_textfield.dart';

Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,       // 다이얼로그 타이틀 (예: '이름 바꾸기')
  required String initial,     // 초기 텍스트
}) async {
  final c = TextEditingController(text: initial);
  final focus = FocusNode();

  return showGeneralDialog<String>(
    context: context,
    barrierLabel: 'rename',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.45), // 배경 딤
    pageBuilder: (_, __, ___) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.white,                // 크림색 카드
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: AppColors.gray50, blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: AppTypography.body2), // 원하는 타이틀 스타일
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: c,
                    style: AppTextFieldStyle.underline,      // 또는 none/search 등 원하는 스타일
                    textStyle: AppTypography.body2.copyWith(color: AppColors.gray50),
                    autofocus: true,
                    focusNode: focus,
                    onSubmitted: (_) => Navigator.of(context).pop(c.text.trim()),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('취소', style: AppTypography.body4.copyWith(color: AppColors.gray40)),
                      ),
                      const SizedBox(width: 16),
                      AppButton.text(                           // 디자인 시스템 버튼 사용
                        text: '확인',
                        onPressed: () => Navigator.of(context).pop(c.text.trim()),
                        style: AppButtonStyle.primary,
                        size: AppButtonSize.md,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
