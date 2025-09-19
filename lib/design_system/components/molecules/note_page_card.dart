// lib/design_system/components/molecules/note_page_card.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../tokens/app_shadows.dart';
import '../../tokens/app_sizes.dart';

class NotePageCard extends StatelessWidget {
  const NotePageCard({
    super.key,
    required this.previewImage,        // w=88, h=120 미리보기
    required this.pageNumber,          // 페이지 번호
    this.onTap,
    this.onLongPress,
    this.selected = false,             // 선택 강조(옵션)
  });

  final Uint8List previewImage;
  final int pageNumber;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.small);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: SizedBox(
          width: AppSizes.noteTileW, // ← 타일 폭 120
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
                    child: previewImage.isEmpty
                      ? Container(width: AppSizes.noteThumbW, height: AppSizes.noteThumbH, color: AppColors.white)
                      :Image.memory(
                        previewImage,
                        width: AppSizes.noteThumbW,
                        height: AppSizes.noteThumbH,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: AppSizes.noteThumbW,
                          height: AppSizes.noteThumbH,
                          color: AppColors.white,
                        ),
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
