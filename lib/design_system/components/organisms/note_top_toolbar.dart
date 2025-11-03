// lib/design_system/components/organisms/note_top_toolbar.dart
import 'package:flutter/material.dart';

import '../../../shared/constants/breakpoints.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/app_icon_button.dart';

/// 툴바 액션을 나타내는 데이터 클래스
class ToolbarAction {
  /// 툴바 액션 생성자
  const ToolbarAction({
    required this.svgPath,
    required this.onTap,
    this.tooltip,
  });
  /// SVG 아이콘 경로
  final String svgPath;
  /// 탭 시 실행될 콜백
  final VoidCallback onTap;
  /// 툴팁 텍스트 (옵션)
  final String? tooltip;
}

// D: NoteScreen 에서 사용
// F: NoteEditorScreen 에서 사용
// 전체화면 시 비활성화
/// 노트 화면 상단 툴바 위젯
class NoteTopToolbar extends StatelessWidget implements PreferredSizeWidget {
  /// 노트 상단 툴바 생성자
  const NoteTopToolbar({
    super.key,
    required this.title,
    this.leftActions = const [],
    this.rightActions = const [],
    this.iconColor = AppColors.gray50,
    this.iconSize = 28,
    this.height = 62, // 15(top) + 32(icon) + 15(bottom) = 62
    this.titleStyle,
    this.showBottomDivider = true,
  });

  /// 툴바 제목
  final String title;
  /// 왼쪽 액션 버튼 목록
  final List<ToolbarAction> leftActions;
  /// 오른쪽 액션 버튼 목록
  final List<ToolbarAction> rightActions;

  /// 아이콘 색상
  final Color iconColor;
  /// 아이콘 크기
  final double iconSize;
  /// 툴바 높이
  final double height;
  /// 제목 텍스트 스타일 (기본 스타일은 아래에서 정함)
  final TextStyle? titleStyle;
  /// 하단 구분선 표시 여부
  final bool showBottomDivider;

  @override
  Size get preferredSize {
    // Note: MediaQuery is not available here,
    // so we use a conservative estimate.
    // The actual height is adjusted in build().
    return Size.fromHeight(height + 50); // Estimate for status bar
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = Breakpoints.isMobile(screenWidth);

    // 모바일일 때 텍스트 크기 축소: subtitle1 (17px) → body2 (16px)
    final ts = titleStyle ??
        (isMobile
            ? AppTypography.body2.copyWith(
                color: AppColors.gray50,
              )
            : AppTypography.subtitle1.copyWith(
                color: AppColors.gray50,
              )); // 스샷처럼 작고 중립 톤

    final topPadding = mediaQuery.padding.top + 15;
    final totalHeight = height + mediaQuery.padding.top;

    // 모바일일 때 패딩 축소: 30px → 16px
    final horizontalPadding =
        isMobile ? AppSpacing.medium : AppSpacing.screenPadding;

    return Container(
      height: totalHeight,
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: topPadding, // SafeArea top + 15
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: showBottomDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.gray20, width: 1),
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 왼쪽 아이콘 그룹
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < leftActions.length; i++) ...[
                  AppIconButton(
                    svgPath: leftActions[i].svgPath,
                    onPressed: leftActions[i].onTap,
                    tooltip: leftActions[i].tooltip,
                    size: AppIconButtonSize.md, // md = 40px 터치 타겟
                    color: iconColor,
                  ),
                  if (i != leftActions.length - 1)
                    SizedBox(
                      width: isMobile
                          ? AppSpacing.small
                          : AppSpacing.medium, // 모바일: 8px, 태블릿: 16px
                    ),
                ],
              ],
            ),
          ),

          // 가운데 제목
          IgnorePointer(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile
                    ? screenWidth * 0.5
                    : double.infinity, // 모바일에서 최대 너비 제한
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 오른쪽 아이콘 그룹
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < rightActions.length; i++) ...[
                  AppIconButton(
                    svgPath: rightActions[i].svgPath,
                    onPressed: rightActions[i].onTap,
                    tooltip: rightActions[i].tooltip,
                    size: AppIconButtonSize.md, // md = 40px 터치 타겟
                    color: iconColor,
                  ),
                  if (i != rightActions.length - 1)
                    SizedBox(
                      width: isMobile
                          ? AppSpacing.small
                          : AppSpacing.medium, // 모바일: 8px, 태블릿: 16px
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
