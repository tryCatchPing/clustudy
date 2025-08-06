import 'package:flutter/material.dart';

/// 🎨 앱 전체에서 사용할 색상 시스템
/// 
/// Figma 디자인 시스템을 기반으로 한 색상 토큰입니다.
/// 모든 UI 컴포넌트에서 하드코딩된 색상 대신 이 클래스를 사용해주세요.
/// 
/// 예시:
/// ```dart
/// Container(
///   color: AppColors.primary,
///   child: Text('텍스트', style: TextStyle(color: AppColors.onPrimary)),
/// )
/// ```
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ================== Primary Colors ==================
  /// 주 색상 - 앱의 핵심 브랜드 색상
  static const Color primary = Color(0xFF6366f1);
  
  /// 주 색상 (어두운 변형) - 호버, 포커스 상태
  static const Color primaryDark = Color(0xFF4f46e5);
  
  /// 주 색상 (밝은 변형) - 배경, 하이라이트
  static const Color primaryLight = Color(0xFF818cf8);
  
  /// 주 색상 위의 텍스트 색상 (흰색 텍스트)
  static const Color onPrimary = Color(0xFFffffff);

  // ================== Secondary Colors ==================
  /// 보조 색상 - 액센트 요소
  static const Color secondary = Color(0xFF8b5cf6);
  
  /// 보조 색상 (어두운 변형)
  static const Color secondaryDark = Color(0xFF7c3aed);
  
  /// 보조 색상 위의 텍스트 색상
  static const Color onSecondary = Color(0xFFffffff);

  // ================== Surface Colors ==================
  /// 기본 배경 색상 (라이트 모드)
  static const Color surface = Color(0xFFffffff);
  
  /// 카드, 시트 등의 배경 색상
  static const Color surfaceVariant = Color(0xFFf8fafc);
  
  /// 어두운 배경 색상 (다크 모드 대비)
  static const Color surfaceDark = Color(0xFF1f2937);
  
  /// 표면 색상 위의 텍스트 색상
  static const Color onSurface = Color(0xFF111827);
  
  /// 표면 색상 위의 보조 텍스트 색상
  static const Color onSurfaceSecondary = Color(0xFF6b7280);

  // ================== Status Colors ==================
  /// 성공 상태 색상
  static const Color success = Color(0xFF10b981);
  
  /// 성공 색상 위의 텍스트
  static const Color onSuccess = Color(0xFFffffff);
  
  /// 성공 색상 (연한 배경용)
  static const Color successLight = Color(0xFFd1fae5);

  /// 오류 상태 색상
  static const Color error = Color(0xFFef4444);
  
  /// 오류 색상 위의 텍스트
  static const Color onError = Color(0xFFffffff);
  
  /// 오류 색상 (연한 배경용)
  static const Color errorLight = Color(0xFFfee2e2);

  /// 경고 상태 색상
  static const Color warning = Color(0xFFf59e0b);
  
  /// 경고 색상 위의 텍스트
  static const Color onWarning = Color(0xFFffffff);
  
  /// 경고 색상 (연한 배경용)
  static const Color warningLight = Color(0xFFfef3c7);

  /// 정보 상태 색상
  static const Color info = Color(0xFF3b82f6);
  
  /// 정보 색상 위의 텍스트
  static const Color onInfo = Color(0xFFffffff);
  
  /// 정보 색상 (연한 배경용)
  static const Color infoLight = Color(0xFFdbeafe);

  // ================== Neutral Colors ==================
  /// 텍스트 주 색상 (가장 진한 회색)
  static const Color textPrimary = Color(0xFF111827);
  
  /// 텍스트 보조 색상
  static const Color textSecondary = Color(0xFF4b5563);
  
  /// 텍스트 3차 색상 (연한 회색)
  static const Color textTertiary = Color(0xFF9ca3af);
  
  /// 비활성화된 텍스트 색상
  static const Color textDisabled = Color(0xFFd1d5db);

  // ================== Border Colors ==================
  /// 기본 테두리 색상
  static const Color border = Color(0xFFe5e7eb);
  
  /// 포커스된 테두리 색상
  static const Color borderFocus = primary;
  
  /// 오류 테두리 색상
  static const Color borderError = error;

  // ================== Canvas Colors ==================
  /// 캔버스 배경 색상
  static const Color canvasBackground = Color(0xFFf9fafb);
  
  /// 캔버스 그리드 색상
  static const Color canvasGrid = Color(0xFFf3f4f6);
  
  /// 캔버스 선택 영역 색상
  static const Color canvasSelection = Color(0x4D6366f1); // primary with 30% opacity

  // ================== Note App Specific Colors ==================
  /// 노트 카드 배경
  static const Color noteCard = surface;
  
  /// 노트 카드 테두리
  static const Color noteCardBorder = border;
  
  /// 노트 즐겨찾기 색상
  static const Color noteFavorite = Color(0xFFfbbf24);
  
  /// PDF 페이지 배경
  static const Color pdfPage = Color(0xFFfefefe);
  
  /// PDF 페이지 그림자
  static const Color pdfShadow = Color(0x1A000000);
}

/// 🌙 다크 모드를 위한 색상 시스템 (향후 확장용)
class AppColorsDark {
  // Private constructor
  AppColorsDark._();
  
  // 다크 모드 색상은 필요시 추가 구현
  static const Color primary = Color(0xFF818cf8);
  static const Color surface = Color(0xFF111827);
  static const Color onSurface = Color(0xFFf9fafb);
  
  // TODO: 다크 모드 완전 구현
}