// lib/design_system/components/organisms/folder_grid.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../tokens/app_sizes.dart';
import '../../tokens/app_spacing.dart';
import '../molecules/app_card.dart';

class FolderGridItem {
  const FolderGridItem({
    this.svgIconPath,                  // 폴더면 SVG 사용
    this.previewImage,                 // 노트면 미리보기 이미지
    required this.title,
    required this.date,
    this.onTap,
    this.onTitleChanged,
    this.child,
  }) : assert(svgIconPath != null || previewImage != null || child != null);

  final String? svgIconPath;
  final Uint8List? previewImage;
  final String title;
  final DateTime date;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTitleChanged;
  final Widget? child;
}

class FolderGrid extends StatelessWidget {
  const FolderGrid({
    super.key,
    required this.items,
    this.padding,                // 화면 바깥 여백
    this.preferredGap = 48,      // 기본 간격 48px
  });

  final List<FolderGridItem> items;
  final EdgeInsets? padding;
  final double preferredGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // 1) 반응형 gutter
      final w = c.maxWidth;
      final bool phone = w < 600;
      final EdgeInsets gutters = padding ??
          EdgeInsets.symmetric(
            horizontal: phone ? AppSpacing.medium : AppSpacing.large, // 16 | 24
            vertical:   phone ? AppSpacing.medium : AppSpacing.large, // 16 | 24
          );

      // 2) 열 수 계산 + 좁을 때 gap 자동 완화(48→24)
      final inner = w - gutters.horizontal;
      double gap = preferredGap;                         // 48
      int cols = ((inner + gap) / (AppSizes.folderTileW + gap)).floor();

      if (cols < 2 && inner >= AppSizes.folderTileW * 2) {
        // 최소 2열을 위해 gap을 24로 줄여 재계산
        gap = AppSpacing.large;                          // 24
        cols = ((inner + gap) / (AppSizes.folderTileW + gap)).floor();
      }
      cols = cols.clamp(1, 12);

      return GridView.builder(
        padding: gutters,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: AppSizes.folderTileW / AppSizes.folderTileH, // 144/196
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.child != null) {
            return item.child!;
          }
          return AppCard(
            svgIconPath: item.svgIconPath,
            previewImage: item.previewImage,
            title: item.title,
            date: item.date,
            onTap: item.onTap,
            onTitleChanged: item.onTitleChanged,
          );
        },
      );
    });
  }
}
