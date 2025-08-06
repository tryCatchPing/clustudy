import 'package:flutter/material.dart';

/// 🔤 앱 전체에서 사용할 타이포그래피 시스템
/// 
/// Figma 디자인 시스템을 기반으로 한 폰트 토큰입니다.
/// 모든 Text 위젯에서 하드코딩된 스타일 대신 이 클래스를 사용해주세요.
/// 
/// 예시:
/// ```dart
/// Text('제목', style: AppTypography.headline1),
/// Text('본문', style: AppTypography.body1),
/// ```
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // ================== Headline Styles ==================
  /// 메인 제목 - 가장 큰 텍스트
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.8,
    color: Color(0xFF111827),
  );

  /// 서브 제목 - 두 번째로 큰 텍스트
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.3,
    letterSpacing: -0.5,
    color: Color(0xFF111827),
  );

  /// 섹션 제목
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.4,
    letterSpacing: -0.3,
    color: Color(0xFF111827),
  );

  /// 서브섹션 제목
  static const TextStyle headline4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: -0.2,
    color: Color(0xFF111827),
  );

  /// 마이너 제목
  static const TextStyle headline5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.5,
    letterSpacing: 0,
    color: Color(0xFF111827),
  );

  // ================== Body Styles ==================
  /// 기본 본문 텍스트 (큰 크기)
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.6,
    letterSpacing: 0,
    color: Color(0xFF111827),
  );

  /// 보조 본문 텍스트 (작은 크기)
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.6,
    letterSpacing: 0.1,
    color: Color(0xFF4b5563),
  );

  /// 세밀한 본문 텍스트
  static const TextStyle body3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.2,
    color: Color(0xFF6b7280),
  );

  // ================== Button Styles ==================
  /// 기본 버튼 텍스트
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.25,
    letterSpacing: 0.1,
    color: Color(0xFFffffff),
  );

  /// 작은 버튼 텍스트
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.25,
    letterSpacing: 0.1,
    color: Color(0xFFffffff),
  );

  /// 큰 버튼 텍스트
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
    height: 1.25,
    letterSpacing: 0,
    color: Color(0xFFffffff),
  );

  // ================== Caption & Label Styles ==================
  /// 설명 텍스트 (가장 작은 크기)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.3,
    color: Color(0xFF9ca3af),
  );

  /// 오버라인 레이블
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.6,
    letterSpacing: 1.5,
    color: Color(0xFF6b7280),
  );

  /// 라벨 텍스트 (폼 라벨 등)
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFF374151),
  );

  // ================== Special Styles ==================
  /// 에러 메시지 텍스트
  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFFef4444),
  );

  /// 성공 메시지 텍스트
  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFF10b981),
  );

  /// 경고 메시지 텍스트
  static const TextStyle warning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFFf59e0b),
  );

  /// 링크 텍스트
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFF6366f1),
    decoration: TextDecoration.underline,
  );

  // ================== Note App Specific Styles ==================
  /// 노트 제목
  static const TextStyle noteTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.3,
    letterSpacing: -0.2,
    color: Color(0xFF111827),
  );

  /// 노트 미리보기 텍스트
  static const TextStyle notePreview = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.1,
    color: Color(0xFF6b7280),
  );

  /// 노트 메타데이터 (날짜, 페이지 수 등)
  static const TextStyle noteMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.2,
    color: Color(0xFF9ca3af),
  );

  /// 툴바 아이늨 라벨
  static const TextStyle toolbarLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500, // Medium
    height: 1.3,
    letterSpacing: 0.3,
    color: Color(0xFF6b7280),
  );
}

/// 🌙 다크 모드를 위한 타이포그래피 시스템 (향후 확장용)
class AppTypographyDark {
  // Private constructor
  AppTypographyDark._();
  
  // 다크 모드 타이포그래피는 필요시 추가 구현
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.8,
    color: Color(0xFFf9fafb), // Light text for dark mode
  );
  
  // TODO: 다크 모드 타이포그래피 완전 구현
}

/// 폰트 가중치 상수
class FontWeight {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}