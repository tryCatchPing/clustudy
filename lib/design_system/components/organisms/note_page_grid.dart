// lib/design_system/components/organisms/note_page_grid.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../tokens/app_sizes.dart';
import '../../tokens/app_spacing.dart';
import '../molecules/add_page_card.dart';
import '../molecules/note_page_card.dart';

final demoPages = List<NotePageItem>.generate(
  8,
  (i) => NotePageItem(
    previewImage: Uint8List(0),
    pageNumber: i + 1,
  ),
);

class NotePageItem {
  const NotePageItem({
    required this.previewImage,
    required this.pageNumber,
    this.selected = false,
  });


  final Uint8List previewImage;
  final int pageNumber;
  final bool selected;
}

class NotePageGrid extends StatelessWidget {
  const NotePageGrid({
    super.key,
    required this.pages,
    this.onTapPage,
    this.onLongPressPage,
    this.onAddPage,
    this.crossAxisGap = AppSpacing.large, // 24
    this.mainAxisGap = AppSpacing.large,  // 24
    this.padding,                         // 화면 좌우 여백(미지정 시 반응형)
    this.plusSvgPath = 'assets/icons/plus.svg',
  });

  final List<NotePageItem> pages;
  final ValueChanged<int>? onTapPage; // index
  final ValueChanged<int>? onLongPressPage;
  final VoidCallback? onAddPage;
  final double crossAxisGap;
  final double mainAxisGap;
  final EdgeInsets? padding;
  final String plusSvgPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // 1) 반응형 gutter(바깥 여백)
      final w = c.maxWidth;
      final bool phone = w < 600;
      final EdgeInsets gutters = padding ??
          EdgeInsets.symmetric(
            horizontal: phone ? AppSpacing.medium : AppSpacing.large, // 16 | 24
            vertical: phone ? AppSpacing.medium : AppSpacing.large,   // 16 | 24
          );

      // 2) 열 수 자동 계산 (gap은 고정)
      // 타일 폭 = 120, gap = 24(기본)
      final double inner = w - gutters.horizontal;
      const double tileW = AppSizes.noteTileW; // 120
      final double gap = crossAxisGap;         // 24
      final int cols = ((inner + gap) / (tileW + gap)).floor().clamp(1, 12);

      return GridView.builder(
        padding: gutters,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: crossAxisGap,
          mainAxisSpacing: mainAxisGap,
          childAspectRatio: AppSizes.noteTileW / AppSizes.noteTileH,
        ),
        itemCount: pages.length + 1, // 마지막에 "새 페이지" 타일
        itemBuilder: (context, i) {
          if (i == pages.length) {
            return AddPageCard(plusSvgPath: plusSvgPath, onTap: onAddPage,);
          }
          final p = pages[i];
          return NotePageCard(
            previewImage: p.previewImage,
            pageNumber: p.pageNumber,
            selected: p.selected,
            onTap: () => onTapPage?.call(i),
            onLongPress: () => onLongPressPage?.call(i),
          );
        },
      );
    });
  }
}
