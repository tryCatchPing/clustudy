// lib/design_system/components/molecules/note_page_card.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../tokens/app_shadows.dart';

class NotePageCard extends StatelessWidget {
  const NotePageCard({
    super.key,
    required this.previewImage,        // w=88, h=120 미리보기
    required this.pageNumber,          // 페이지 번호
    this.onTap,
    this.thumbWidth = AppSpacing.pageCardWidth,
    this.thumbHeight = AppSpacing.pageCardHeight,
    this.selected = false,             // 선택 강조(옵션)
  });

  final Uint8List previewImage;
  final int pageNumber;
  final VoidCallback? onTap;
  final double thumbWidth;
  final double thumbHeight;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.small);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small), // 카드 내부 여백 8
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 미리보기 + 그림자 + 라운드 (+선택 테두리)
              Container(
                decoration: BoxDecoration(
                  boxShadow: AppShadows.small,
                  borderRadius: radius,
                  border: selected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Image.memory(
                    previewImage,
                    width: thumbWidth,
                    height: thumbHeight,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.medium), // 16px

              // 페이지 번호(가운데 정렬, 1줄)
              Text(
                '$pageNumber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.body5.copyWith(color: AppColors.gray50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
