import 'package:flutter/material.dart';

/// 🌑 앱 전체에서 사용할 그림자 시스템
/// 
/// Figma 디자인 시스템을 기반으로 한 그림자 토큰입니다.
/// BoxDecoration에서 하드코딩된 그림자 대신 이 클래스를 사용해주세요.
/// 
/// 예시:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.medium,
///     borderRadius: BorderRadius.circular(12),
///   ),
/// )
/// ```
class AppShadows {
  // Private constructor to prevent instantiation
  AppShadows._();

  // ================== Basic Shadow Levels ==================
  /// 아주 연한 그림자 - 미세한 고도 표현
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// 작은 그림자 - 양식 요소, 텍스트 입력
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// 기본 그림자 - 카드, 버튼
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// 큰 그림자 - 모달, 드롭다운
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x19000000), // 10% opacity
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// 아주 큰 그림자 - 플로팅 요소
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1F000000), // 12% opacity
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// 최대 그림자 - 풀스크린 모달
  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x29000000), // 16% opacity
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x19000000), // 10% opacity
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ================== Specialized Shadows ==================
  /// 내부 그림자 - 담은 입력 필드
  static const List<BoxShadow> inset = [
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
      blurStyle: BlurStyle.inner,
    ),
  ];

  /// 색상 그림자 - 액센트 요소 (주 색상 기반)
  static const List<BoxShadow> colored = [
    BoxShadow(
      color: Color(0x336366f1), // primary color with 20% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// 성공 그림자 - 성공 상태 요소
  static const List<BoxShadow> success = [
    BoxShadow(
      color: Color(0x3310b981), // success color with 20% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// 오류 그림자 - 오류 상태 요소
  static const List<BoxShadow> error = [
    BoxShadow(
      color: Color(0x33ef4444), // error color with 20% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// 경고 그림자 - 경고 상태 요소
  static const List<BoxShadow> warning = [
    BoxShadow(
      color: Color(0x33f59e0b), // warning color with 20% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  // ================== Canvas Specific Shadows ==================
  /// 페이지 그림자 - PDF 페이지
  static const List<BoxShadow> page = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// 툴바 그림자 - 플로팅 툴바
  static const List<BoxShadow> toolbar = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 16,
      offset: Offset(0, -4), // 위쪽 그림자
    ),
  ];

  /// 선택 그림자 - 선택된 요소
  static const List<BoxShadow> selected = [
    BoxShadow(
      color: Color(0x4D6366f1), // primary color with 30% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // ================== Note App Specific Shadows ==================
  /// 노트 카드 그림자
  static const List<BoxShadow> noteCard = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000), // 2% opacity
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  /// 노트 카드 호버 그림자
  static const List<BoxShadow> noteCardHover = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// 플로팅 액션 버튼 그림자
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x1F000000), // 12% opacity
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // ================== Utility Methods ==================
  /// 그림자 없음
  static const List<BoxShadow> none = [];

  /// 커스텀 그림자 생성
  static List<BoxShadow> custom({
    required Color color,
    required double blurRadius,
    required Offset offset,
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        offset: offset,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// 투명도를 조절한 그림자 생성
  static List<BoxShadow> withOpacity(List<BoxShadow> shadows, double opacity) {
    return shadows
        .map((shadow) => shadow.copyWith(
              color: shadow.color.withOpacity(
                shadow.color.opacity * opacity,
              ),
            ))
        .toList();
  }
}

/// 🌙 다크 모드를 위한 그림자 시스템 (향후 확장용)
class AppShadowsDark {
  // Private constructor
  AppShadowsDark._();
  
  // 다크 모드에서는 그림자가 더 밝게 나타나야 함
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity (more visible in dark)
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // TODO: 다크 모드 그림자 완전 구현
}