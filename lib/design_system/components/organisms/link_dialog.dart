// lib/design_system/components/overlays/link_dialog.dart
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_button.dart';
import '../atoms/app_textfield.dart';

Future<String?> showLinkDialog(
  BuildContext context, {
  required List<String> noteTitles, // 선택할 수 있는 노트 목록
}) async {
  final c = TextEditingController();
  final focus = FocusNode();

  return showGeneralDialog<String>(
    context: context,
    barrierLabel: 'link',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.45),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                  const Text('링크 생성', style: AppTypography.body2),
                  const SizedBox(height: 16),
                  // 입력창
                  AppTextField(
                    controller: c,
                    style: AppTextFieldStyle.underline,
                    textStyle: AppTypography.body2.copyWith(
                      color: AppColors.gray50,
                    ),
                    hintText: '기존 노트 선택 또는 새 제목 입력',
                    autofocus: true,
                    focusNode: focus,
                    onSubmitted: (_) =>
                        Navigator.of(context).pop(c.text.trim()),
                  ),
                  const SizedBox(height: 12),
                  // 노트 목록 표시
                  if (noteTitles.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: noteTitles.length,
                        itemBuilder: (_, i) {
                          final note = noteTitles[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(note, style: AppTypography.body4),
                            onTap: () {
                              Navigator.of(context).pop(note);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  // 버튼 영역
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '취소',
                          style: AppTypography.body4.copyWith(
                            color: AppColors.gray40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AppButton.text(
                        text: '생성',
                        onPressed: () =>
                            Navigator.of(context).pop(c.text.trim()),
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
