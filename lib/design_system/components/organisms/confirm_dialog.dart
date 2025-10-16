import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_button.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool barrierDismissible = true,
  bool destructive = false,
  Widget? leading,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'confirm',
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(0.45),
    pageBuilder: (_, __, ___) {
      return Builder(
        builder: (dialogContext) {
          final navigator = Navigator.of(dialogContext);
          final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: bottomInset + 24,
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.gray50,
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (leading != null) ...[
                          Center(child: leading),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          title,
                          style: AppTypography.body2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: AppTypography.body4.copyWith(
                            color: AppColors.gray50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => navigator.pop(false),
                              child: Text(
                                cancelLabel,
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.gray40,
                                ),
                              ),
                            ),
                           const SizedBox(width: 16),
                           AppButton.text(
                             text: confirmLabel,
                             onPressed: () => navigator.pop(true),
                              style: destructive
                                  ? AppButtonStyle.primary
                                  : AppButtonStyle.secondary,
                             size: AppButtonSize.md,
                           ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
