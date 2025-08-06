import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// 🔧 디자인 시스템 유틸리티 확장
/// 
/// Flutter의 기본 클래스들을 확장하여 디자인 토큰을 쉽게 사용할 수 있도록 합니다.

/// Context 확장 - 테마와 미디어쿼리에 쉽게 접근
extension BuildContextExtensions on BuildContext {
  /// 현재 테마 데이터
  ThemeData get theme => Theme.of(this);
  
  /// 현재 색상 스킴
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// 현재 텍스트 테마
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// 화면 크기 정보
  Size get screenSize => MediaQuery.of(this).size;
  
  /// 화면 너비
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// 화면 높이
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// SafeArea 패딩 정보
  EdgeInsets get padding => MediaQuery.of(this).padding;
  
  /// 화면 하단 패딩 (홈 인디케이터 등)
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  
  /// 화면 상단 패딩 (상태바 등)
  double get topPadding => MediaQuery.of(this).padding.top;
  
  /// 키보드 높이
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  
  /// 키보드가 열려있는지 확인
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
  
  /// 반응형 디자인을 위한 breakpoint 확인
  bool get isMobile => screenWidth < 768;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
}