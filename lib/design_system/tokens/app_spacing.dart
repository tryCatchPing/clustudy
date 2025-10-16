import 'package:flutter/material.dart';

class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ================== Base Spacing Scale ==================
  /// 초소형 간격 (2px) - 미세 조정용
  static const double xxs = 2.0;

  /// 아주 작은 간격 (4px) - 아이콘과 텍스트 사이
  static const double xs = 4.0;

  /// 작은 간격 (8px) - 아이콘과 텍스트 사이
  static const double small = 8.0;

  /// 기본 간격 (16px) - 일반적인 패딩
  static const double medium = 16.0;

  /// 큰 간격 (24px) - 섹션 내부 간격
  static const double large = 24.0;

  /// 아주 큰 간격 (32px) - 섹션 간 간격
  static const double xl = 32.0;

  /// 초대형 간격 (48px) - 노트 간격
  static const double xxl = 48.0;

  /// 거대하게 큰 간격 (120px) - 객체 간격
  static const double xxxl = 120.0;

  /// 화면 가장자리 패딩
  static const double screenPadding = 30.0;

  /// 버튼 내부 패딩 (가로)
  static const double buttonHorizontal = 12.0;

  /// 버튼 내부 패딩 (세로)
  static const double buttonVertical = 8.0;

  static const double touchTargetSm = 36.0;
  static const double touchTargetMd = 40.0;

  static const double cardPreviewWidth = 88.0;
  static const double cardPreviewHeight = 120.0;
  static const double cardFolderIconWidth = 144.0;
  static const double cardFolderIconHeight = 136.0;
  static const double cardBorderRadius = 12.0;

  static const double pageCardWidth = 88.0;
  static const double pageCardHeight = 120.0;
  static const double selectedBorderWidth = 2.0;
}

/// 📏 사전 정의된 EdgeInsets 패턴
class AppPadding {
  // Private constructor
  AppPadding._();

  // ================== All Sides ==================
  /// 모든 방향 소 패딩
  static const EdgeInsets allSmall = EdgeInsets.all(AppSpacing.small);

  /// 모든 방향 기본 패딩
  static const EdgeInsets allMedium = EdgeInsets.all(AppSpacing.medium);

  /// 모든 방향 대 패딩
  static const EdgeInsets allLarge = EdgeInsets.all(AppSpacing.large);

  // ================== Horizontal & Vertical ==================
  /// 가로 방향만 소 패딩
  static const EdgeInsets horizontalSmall = EdgeInsets.symmetric(
    horizontal: AppSpacing.small,
  );

  /// 가로 방향만 기본 패딩
  static const EdgeInsets horizontalMedium = EdgeInsets.symmetric(
    horizontal: AppSpacing.medium,
  );

  /// 가로 방향만 대 패딩
  static const EdgeInsets horizontalLarge = EdgeInsets.symmetric(
    horizontal: AppSpacing.large,
  );

  /// 세로 방향만 소 패딩
  static const EdgeInsets verticalSmall = EdgeInsets.symmetric(
    vertical: AppSpacing.small,
  );

  /// 세로 방향만 기본 패딩
  static const EdgeInsets verticalMedium = EdgeInsets.symmetric(
    vertical: AppSpacing.medium,
  );

  /// 세로 방향만 대 패딩
  static const EdgeInsets verticalLarge = EdgeInsets.symmetric(
    vertical: AppSpacing.large,
  );

  // ================== Screen Padding ==================
  /// 화면 전체 패딩
  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.screenPadding);

  /// 화면 가로 패딩만
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenPadding,
  );

  /// 화면 상하 패딩만
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.screenPadding,
  );

  // ================== Component Specific ==================
  /// 버튼 패딩
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.buttonHorizontal,
    vertical: AppSpacing.buttonVertical,
  );
}
